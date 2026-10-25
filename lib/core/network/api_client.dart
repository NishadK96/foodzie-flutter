import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'FOODZY_API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );
}

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode, [this.errors]);
  final String message;
  final int statusCode;
  final Object? errors;

  @override
  String toString() => message;
}

class SessionTokens {
  const SessionTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.refreshExpiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;
  final DateTime refreshExpiresAt;

  factory SessionTokens.fromJson(Map<String, dynamic> json) => SessionTokens(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    accessExpiresAt: DateTime.parse(json['expires_at'] as String),
    refreshExpiresAt: DateTime.parse(json['refresh_expires_at'] as String),
  );
}

abstract class SessionStore {
  Future<SessionTokens?> read();
  Future<void> write(SessionTokens tokens);
  Future<void> clear();
}

class SecureSessionStore implements SessionStore {
  const SecureSessionStore([this.storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage storage;
  static const _key = 'foodzy_pos_session_v1';

  @override
  Future<SessionTokens?> read() async {
    final value = await storage.read(key: _key);
    if (value == null) return null;
    try {
      return SessionTokens.fromJson(jsonDecode(value) as Map<String, dynamic>);
    } catch (_) {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(SessionTokens tokens) => storage.write(
    key: _key,
    value: jsonEncode({
      'access_token': tokens.accessToken,
      'refresh_token': tokens.refreshToken,
      'expires_at': tokens.accessExpiresAt.toIso8601String(),
      'refresh_expires_at': tokens.refreshExpiresAt.toIso8601String(),
    }),
  );

  @override
  Future<void> clear() => storage.delete(key: _key);
}

class FoodzyApiClient {
  FoodzyApiClient({
    http.Client? httpClient,
    SessionStore? sessionStore,
    this.baseUrl = ApiConfig.baseUrl,
  }) : _http = httpClient ?? http.Client(),
       sessionStore = sessionStore ?? const SecureSessionStore();

  final http.Client _http;
  final SessionStore sessionStore;
  final String baseUrl;
  SessionTokens? _tokens;
  Future<bool>? _refreshInFlight;
  int? branchId;

  Future<bool> restoreSession() async {
    _tokens = await sessionStore.read();
    if (_tokens == null) return false;
    if (_tokens!.refreshExpiresAt.isBefore(DateTime.now())) {
      await clearSession();
      return false;
    }
    if (_tokens!.accessExpiresAt.isBefore(
      DateTime.now().add(const Duration(seconds: 15)),
    )) {
      return refreshSession();
    }
    return true;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String deviceName = 'Foodzy Flutter POS',
    String? twoFactorCode,
  }) async {
    final body = <String, Object?>{
      'email': email.trim(),
      'password': password,
      'device_name': deviceName,
      if (twoFactorCode?.trim().isNotEmpty == true)
        'two_factor_code': twoFactorCode!.trim(),
    };
    final json = await _sendRaw('POST', '/auth/login', body: body);
    final data = _asMap(json['data']);
    _tokens = SessionTokens.fromJson(data);
    await sessionStore.write(_tokens!);
    return data;
  }

  Future<bool> refreshSession() {
    final current = _refreshInFlight;
    if (current != null) return current;
    final operation = _performRefresh();
    _refreshInFlight = operation;
    return operation.whenComplete(() => _refreshInFlight = null);
  }

  Future<bool> _performRefresh() async {
    final refreshToken = _tokens?.refreshToken;
    if (refreshToken == null) return false;
    try {
      final json = await _sendRaw(
        'POST',
        '/auth/refresh',
        body: {'refresh_token': refreshToken},
      );
      _tokens = SessionTokens.fromJson(_asMap(json['data']));
      await sessionStore.write(_tokens!);
      return true;
    } catch (_) {
      await clearSession();
      return false;
    }
  }

  Future<dynamic> get(String path) => request('GET', path);
  Future<dynamic> post(String path, {Map<String, Object?>? body}) =>
      request('POST', path, body: body);
  Future<dynamic> put(String path, {Map<String, Object?>? body}) =>
      request('PUT', path, body: body);
  Future<dynamic> delete(String path, {Map<String, Object?>? body}) =>
      request('DELETE', path, body: body);

  Future<dynamic> request(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    if (_tokens == null && !await restoreSession()) {
      throw const ApiException('Please sign in again.', 401);
    }
    var response = await _send(method, path, body: body);
    if (response.statusCode == 401 && await refreshSession()) {
      response = await _send(method, path, body: body);
    }
    return _decode(response);
  }

  Future<void> logout() async {
    try {
      if (_tokens != null) await request('POST', '/auth/logout');
    } finally {
      await clearSession();
    }
  }

  Future<void> clearSession() async {
    _tokens = null;
    branchId = null;
    await sessionStore.clear();
  }

  Future<dynamic> _sendRaw(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async => _decode(
    await _http
        .send(
          http.Request(method, _uri(path))
            ..headers.addAll(_headers(authenticated: false))
            ..body = body == null ? '' : jsonEncode(body),
        )
        .then(http.Response.fromStream),
  );

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) => _http
      .send(
        http.Request(method, _uri(path))
          ..headers.addAll(_headers(authenticated: true))
          ..body = body == null ? '' : jsonEncode(body),
      )
      .then(http.Response.fromStream);

  Uri _uri(String path) => Uri.parse(
    '${baseUrl.replaceFirst(RegExp(r'/$'), '')}/${path.replaceFirst(RegExp(r'^/'), '')}',
  );

  Map<String, String> _headers({required bool authenticated}) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (authenticated && _tokens != null)
      'Authorization': 'Bearer ${_tokens!.accessToken}',
    if (authenticated && branchId != null) 'X-Branch-ID': '$branchId',
  };

  dynamic _decode(http.Response response) {
    dynamic json;
    try {
      json = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      throw ApiException(
        'The server returned an unreadable response.',
        response.statusCode,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final map = json is Map ? Map<String, dynamic>.from(json) : null;
      throw ApiException(
        map?['message']?.toString() ??
            'Request failed (${response.statusCode}).',
        response.statusCode,
        map?['errors'],
      );
    }
    return json;
  }

  Map<String, dynamic> _asMap(dynamic value) =>
      Map<String, dynamic>.from(value as Map);

  void close() => _http.close();
}
