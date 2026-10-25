import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:foodzy_pos/core/network/api_client.dart';
import 'package:foodzy_pos/features/pos/data/live_menu_repository.dart';

class _MemoryStore implements SessionStore {
  SessionTokens? tokens;

  @override
  Future<void> clear() async => tokens = null;

  @override
  Future<SessionTokens?> read() async => tokens;

  @override
  Future<void> write(SessionTokens value) async => tokens = value;
}

Map<String, Object> _tokenBody(String access, String refresh) => {
  'data': {
    'access_token': access,
    'refresh_token': refresh,
    'expires_at': DateTime.now()
        .add(const Duration(minutes: 15))
        .toIso8601String(),
    'refresh_expires_at': DateTime.now()
        .add(const Duration(days: 30))
        .toIso8601String(),
  },
};

void main() {
  test('login stores the returned access and refresh token pair', () async {
    final store = _MemoryStore();
    final client = FoodzyApiClient(
      baseUrl: 'https://example.test/api/v1',
      sessionStore: store,
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/login');
        expect(jsonDecode(request.body)['device_name'], 'Foodzy Flutter POS');
        return http.Response(
          jsonEncode(_tokenBody('access-1', 'refresh-1')),
          200,
        );
      }),
    );

    await client.login(email: 'cashier@example.com', password: 'secret');

    expect(store.tokens?.accessToken, 'access-1');
    expect(store.tokens?.refreshToken, 'refresh-1');
  });

  test('401 rotates tokens once and retries the protected request', () async {
    final store = _MemoryStore()
      ..tokens = SessionTokens(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
        accessExpiresAt: DateTime.now().add(const Duration(minutes: 10)),
        refreshExpiresAt: DateTime.now().add(const Duration(days: 10)),
      );
    var catalogCalls = 0;
    final client = FoodzyApiClient(
      baseUrl: 'https://example.test/api/v1',
      sessionStore: store,
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          return http.Response(
            jsonEncode(_tokenBody('new-access', 'new-refresh')),
            200,
          );
        }
        catalogCalls++;
        if (catalogCalls == 1) return http.Response('{}', 401);
        expect(request.headers['authorization'], 'Bearer new-access');
        return http.Response('[]', 200);
      }),
    );

    expect(await client.restoreSession(), isTrue);
    expect(await client.get('/pos/items'), isEmpty);
    expect(catalogCalls, 2);
    expect(store.tokens?.refreshToken, 'new-refresh');
  });

  test('live catalog maps API categories, products, and tables', () {
    final repository = LiveMenuRepository.fromResponses(
      categoriesJson: [
        {'id': 5, 'category_name': 'Pizzas'},
      ],
      productsJson: [
        {
          'id': 9,
          'item_name': 'Margherita',
          'description': 'Tomato and mozzarella',
          'item_category_id': 5,
          'price': '249.00',
          'type': 'veg',
        },
      ],
      tablesJson: {
        'tables': [
          {
            'id': 8,
            'table_code': 'T08',
            'seating_capacity': 4,
            'available_status': 'running',
          },
        ],
      },
    );

    expect(repository.categories.last.name, 'Pizzas');
    expect(repository.products.single.pricePaise, 24900);
    expect(repository.products.single.categoryId, 'api_5');
    expect(repository.tables.single.number, 8);
  });
}
