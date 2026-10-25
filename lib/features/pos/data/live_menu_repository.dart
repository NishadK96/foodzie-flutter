import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../domain/models.dart';
import 'demo_repository.dart';

final catalogControllerProvider =
    AsyncNotifierProvider<CatalogController, MenuRepository>(
      CatalogController.new,
    );

class CatalogController extends AsyncNotifier<MenuRepository> {
  @override
  MenuRepository build() => DemoMenuRepository();

  Future<bool> loadLive() async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait([
        api.get('/pos/categories'),
        api.get('/pos/items'),
        api.get('/pos/tables'),
      ]);
      state = AsyncData(
        LiveMenuRepository.fromResponses(
          categoriesJson: results[0],
          productsJson: results[1],
          tablesJson: results[2],
        ),
      );
      return true;
    } catch (error, stack) {
      state = AsyncError(error, stack);
      return false;
    }
  }

  void useDemo() => state = AsyncData(DemoMenuRepository());
}

class LiveMenuRepository implements MenuRepository {
  const LiveMenuRepository({
    required this.categories,
    required this.products,
    required this.tables,
    this.tickets = const [],
    this.orders = const [],
  });

  factory LiveMenuRepository.fromResponses({
    required dynamic categoriesJson,
    required dynamic productsJson,
    required dynamic tablesJson,
  }) {
    final categoryRows = _list(categoriesJson);
    final productRows = _list(productsJson);
    final tableRows = tablesJson is Map
        ? _list(tablesJson['tables'] ?? tablesJson['data'])
        : _list(tablesJson);

    final categories = <MenuCategory>[
      const MenuCategory('all', 'All Items', 'all'),
      for (final row in categoryRows)
        MenuCategory(
          'api_${row['id']}',
          _text(row['category_name'], fallback: 'Category ${row['id']}'),
          _iconFor(_text(row['category_name'])),
        ),
    ];

    final products = <MenuProduct>[
      for (var index = 0; index < productRows.length; index++)
        _product(productRows[index], index),
    ];

    final tables = <RestaurantTable>[
      for (var index = 0; index < tableRows.length; index++)
        _table(tableRows[index], index),
    ];

    return LiveMenuRepository(
      categories: categories,
      products: products,
      tables: tables,
    );
  }

  @override
  final List<MenuCategory> categories;
  @override
  final List<MenuProduct> products;
  @override
  final List<RestaurantTable> tables;
  @override
  final List<KitchenTicket> tickets;
  @override
  final List<CompletedOrder> orders;

  static MenuProduct _product(Map<String, dynamic> row, int index) {
    final price = _number(
      row['price'] ??
          row['base_price'] ??
          row['selling_price'] ??
          row['item_price'],
    );
    final type = '${row['type'] ?? row['food_type'] ?? ''}'.toLowerCase();
    return MenuProduct(
      id: 'api_${row['id']}',
      name: _text(
        row['item_name'] ?? row['name'],
        fallback: 'Menu item ${row['id']}',
      ),
      description: _text(
        row['description'] ?? row['item_description'],
        fallback: 'Freshly prepared',
      ),
      categoryId: 'api_${row['item_category_id'] ?? row['category_id'] ?? ''}',
      pricePaise: (price * 100).round(),
      imageIndex: index % 16,
      vegetarian:
          type.contains('veg') && !type.contains('non') ||
          row['is_vegetarian'] == true ||
          row['is_veg'] == true,
    );
  }

  static RestaurantTable _table(Map<String, dynamic> row, int index) {
    final code = '${row['table_code'] ?? row['number'] ?? row['id']}';
    final number =
        int.tryParse(code.replaceAll(RegExp(r'[^0-9]'), '')) ??
        int.tryParse('${row['id']}') ??
        index + 1;
    final available = '${row['available_status'] ?? ''}'.toLowerCase();
    return RestaurantTable(
      number,
      int.tryParse('${row['seating_capacity'] ?? 4}') ?? 4,
      available == 'running' || row['is_running'] == true
          ? TableStatus.occupied
          : TableStatus.available,
      backendId: int.tryParse('${row['id']}'),
      code: code,
    );
  }

  static List<Map<String, dynamic>> _list(dynamic value) {
    if (value is! List) return const [];
    return [
      for (final row in value)
        if (row is Map) Map<String, dynamic>.from(row),
    ];
  }

  static String _text(dynamic value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is Map) {
      for (final candidate in ['en', 'name', 'value']) {
        final text = value[candidate]?.toString().trim();
        if (text != null && text.isNotEmpty) return text;
      }
      for (final candidate in value.values) {
        final text = candidate?.toString().trim();
        if (text != null && text.isNotEmpty) return text;
      }
    }
    return fallback;
  }

  static double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static String _iconFor(String value) {
    final name = value.toLowerCase();
    if (name.contains('pizza')) return 'pizzas';
    if (name.contains('burger')) return 'burgers';
    if (name.contains('rice') || name.contains('biryani')) return 'rice';
    if (name.contains('drink') || name.contains('beverage')) return 'beverages';
    if (name.contains('dessert')) return 'desserts';
    if (name.contains('starter')) return 'starters';
    return 'mains';
  }
}
