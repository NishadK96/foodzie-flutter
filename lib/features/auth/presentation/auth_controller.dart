import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final apiClientProvider = Provider<FoodzyApiClient>((ref) {
  final client = FoodzyApiClient();
  ref.onDispose(client.close);
  return client;
});

class AuthState {
  const AuthState({this.user, this.restaurant, this.branch, this.demo = false});
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? restaurant;
  final Map<String, dynamic>? branch;
  final bool demo;

  bool get authenticated => user != null;
  String get displayName => user?['name']?.toString() ?? 'Demo Cashier';
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthState> {
  FoodzyApiClient get _api => ref.read(apiClientProvider);

  @override
  Future<AuthState> build() async {
    try {
      if (!await _api.restoreSession()) return const AuthState();
      return _loadContext();
    } catch (_) {
      await _api.clearSession();
      return const AuthState();
    }
  }

  Future<bool> login(String email, String password, {String? twoFactor}) async {
    state = const AsyncLoading();
    try {
      await _api.login(
        email: email,
        password: password,
        twoFactorCode: twoFactor,
      );
      state = AsyncData(await _loadContext());
      return true;
    } catch (error, stack) {
      state = AsyncError(error, stack);
      return false;
    }
  }

  Future<AuthState> _loadContext() async {
    final response = Map<String, dynamic>.from(
      await _api.get('/auth/me') as Map,
    );
    final branch = Map<String, dynamic>.from(response['branch'] as Map);
    _api.branchId = int.tryParse('${branch['id']}');
    return AuthState(
      user: Map<String, dynamic>.from(response['user'] as Map),
      restaurant: Map<String, dynamic>.from(response['restaurant'] as Map),
      branch: branch,
    );
  }

  void useDemo() => state = const AsyncData(AuthState(demo: true));

  Future<void> logout() async {
    state = const AsyncLoading();
    await _api.logout();
    state = const AsyncData(AuthState());
  }
}
