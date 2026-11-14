import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:foodzy_pos/core/network/api_client.dart';
import 'package:foodzy_pos/features/pos/data/live_menu_repository.dart';
import 'package:foodzy_pos/features/pos/data/pos_api_repository.dart';
import 'package:foodzy_pos/features/pos/domain/models.dart';

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

  test('existing order additions use only unsent quantities', () async {
    final requests = <http.Request>[];
    final store = _MemoryStore()
      ..tokens = SessionTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
        accessExpiresAt: DateTime.now().add(const Duration(minutes: 10)),
        refreshExpiresAt: DateTime.now().add(const Duration(days: 10)),
      );
    final client = FoodzyApiClient(
      baseUrl: 'https://example.test/api/v1',
      sessionStore: store,
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'data': {
              'added_items': [81],
            },
          }),
          200,
        );
      }),
    );
    final repository = PosApiRepository(client);
    final product = MenuProduct(
      id: 'api_9',
      name: 'Margherita',
      description: '',
      categoryId: 'api_5',
      pricePaise: 24900,
      imageIndex: 0,
      vegetarian: true,
    );
    final lines = [
      CartLine(
        key: 'line',
        product: product,
        modifiers: const [],
        quantity: 3,
        sentQuantity: 2,
      ),
    ];

    final ids = await repository.addOrderItems(42, lines);

    expect(ids, [81]);
    expect(requests.single.method, 'PUT');
    expect(requests.single.url.path, '/api/v1/pos/orders/42/items');
    final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(body['items'].single['menu_item_id'], 9);
    expect(body['items'].single['quantity'], 1);
    expect(body['items'].single['action'], 'add');
  });

  test('additional KOT contains only newly added order item ids', () async {
    late http.Request captured;
    final store = _MemoryStore()
      ..tokens = SessionTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
        accessExpiresAt: DateTime.now().add(const Duration(minutes: 10)),
        refreshExpiresAt: DateTime.now().add(const Duration(days: 10)),
      );
    final repository = PosApiRepository(
      FoodzyApiClient(
        baseUrl: 'https://example.test/api/v1',
        sessionStore: store,
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode({'success': true}), 201);
        }),
      ),
    );

    await repository.createKot(42, [81, 82], note: 'No onion');

    expect(captured.url.path, '/api/v1/pos/orders/42/kot');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['order_item_ids'], [81, 82]);
    expect(body['note'], 'No onion');
  });

  test('live KOT status uses backend status vocabulary', () async {
    late http.Request captured;
    final store = _MemoryStore()
      ..tokens = SessionTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
        accessExpiresAt: DateTime.now().add(const Duration(minutes: 10)),
        refreshExpiresAt: DateTime.now().add(const Duration(days: 10)),
      );
    final repository = PosApiRepository(
      FoodzyApiClient(
        baseUrl: 'https://example.test/api/v1',
        sessionStore: store,
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode({'success': true}), 200);
        }),
      ),
    );

    await repository.updateKotStatus(7, 'food_ready');

    expect(captured.method, 'PUT');
    expect(captured.url.path, '/api/v1/pos/kots/7/status');
    expect(jsonDecode(captured.body)['status'], 'food_ready');
  });
}
