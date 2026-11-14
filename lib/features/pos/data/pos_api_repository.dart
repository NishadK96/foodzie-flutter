import '../../../core/network/api_client.dart';
import '../domain/models.dart';

class PosApiRepository {
  const PosApiRepository(this.api);

  final FoodzyApiClient api;

  Future<PosBootstrap> bootstrap() async {
    final responses = await Future.wait<dynamic>([
      api.get('/pos/order-types'),
      api.get('/pos/taxes'),
      api.get('/pos/orders'),
      api.get('/pos/kots'),
      api.get('/pos/customers'),
      api.get('/pos/reservations'),
      api.get('/platform/printers'),
      api.get('/platform/receipt-settings'),
      api.get('/pos/branches'),
      api.get('/staff'),
    ]);
    return PosBootstrap(
      orderTypes: _rows(responses[0]),
      taxes: _rows(responses[1]),
      orders: _paginatedRows(responses[2]),
      kots: _paginatedRows(responses[3]),
      customers: _paginatedRows(responses[4]),
      reservations: _paginatedRows(responses[5]),
      printers: _rows(responses[6]),
      receiptSettings: _map(responses[7]),
      branches: _rows(responses[8]),
      staff: _rows(responses[9]),
    );
  }

  Future<List<ModifierGroup>> modifiersFor(String productId) async {
    final itemId = _backendId(productId);
    final response = await api.get('/pos/items/$itemId/modifier-groups');
    return [
      for (final group in _rows(response))
        ModifierGroup(
          'api_${group['id']}',
          _text(group['name'] ?? group['group_name'], 'Options'),
          [
            for (final option in _rows(
              group['options'] ?? group['modifier_options'],
            ))
              ModifierOption(
                'api_${option['id']}',
                _text(option['name'] ?? option['option_name'], 'Option'),
                (_number(option['price']) * 100).round(),
              ),
          ],
          required: group['is_required'] == true || group['required'] == true,
          multiple:
              group['allow_multiple'] == true ||
              group['multiple'] == true ||
              '${group['selection_type']}'.toLowerCase() == 'multiple',
        ),
    ];
  }

  Future<Map<String, dynamic>> submitOrder({
    required List<CartLine> lines,
    required RestaurantTable? table,
    required String note,
    required int fixedDiscountPaise,
    required int percentageDiscountBasisPoints,
    required bool sendToKitchen,
  }) async {
    final body = <String, Object?>{
      'items': [
        for (final line in lines)
          {
            'id': _backendId(line.product.id),
            'quantity': line.quantity,
            'modifiers': [
              for (final modifier in line.modifiers)
                {'id': _backendId(modifier.id)},
            ],
            if (line.note.isNotEmpty) 'note': line.note,
          },
      ],
      'order_type': table == null ? 'Takeaway' : 'Dine In',
      if (table?.backendId != null) 'table_id': table!.backendId,
      // The current orders schema accepts POS-originated orders as `pos`.
      'placed_via': 'pos',
      if (note.isNotEmpty) 'note': note,
      if (fixedDiscountPaise > 0) ...{
        'discount_type': 'fixed',
        'discount_value': fixedDiscountPaise / 100,
      } else if (percentageDiscountBasisPoints > 0) ...{
        'discount_type': 'percent',
        'discount_value': percentageDiscountBasisPoints / 100,
      },
      'actions': [sendToKitchen ? 'kot' : 'draft'],
    };
    return _map(await api.post('/pos/orders', body: body));
  }

  Future<List<int>> addOrderItems(int orderId, List<CartLine> lines) async {
    final additions = [
      for (final line in lines)
        if (line.quantity > line.sentQuantity)
          {
            'action': 'add',
            'menu_item_id': _backendId(line.product.id),
            'quantity': line.quantity - line.sentQuantity,
            'modifier_ids': [
              for (final modifier in line.modifiers) _backendId(modifier.id),
            ],
            if (line.note.isNotEmpty) 'note': line.note,
          },
    ];
    if (additions.isEmpty) return const [];
    final response = _map(
      await api.put('/pos/orders/$orderId/items', body: {'items': additions}),
    );
    final data = _map(response['data']);
    return [
      for (final id
          in data['added_items'] is List
              ? data['added_items'] as List
              : const [])
        ?int.tryParse('$id'),
    ];
  }

  Future<Map<String, dynamic>> createKot(
    int orderId,
    List<int> orderItemIds, {
    String note = '',
  }) async => _map(
    await api.post(
      '/pos/orders/$orderId/kot',
      body: {'order_item_ids': orderItemIds, if (note.isNotEmpty) 'note': note},
    ),
  );

  Future<Map<String, dynamic>> updateKotStatus(
    int kotId,
    String status,
  ) async =>
      _map(await api.put('/pos/kots/$kotId/status', body: {'status': status}));

  Future<Map<String, dynamic>> payOrder(
    int orderId,
    PaymentMethod method,
  ) async => _map(
    await api.post(
      '/pos/orders/$orderId/pay',
      body: {'payment_method': method.name},
    ),
  );

  Future<Map<String, dynamic>> splitPayment(
    int orderId,
    List<PaymentAllocation> payments,
  ) async => _map(
    await api.post(
      '/pos/orders/$orderId/split-payments',
      body: {
        'payments': [
          for (final payment in payments)
            {
              'payment_method': payment.method.name,
              'amount': payment.amountPaise / 100,
            },
        ],
      },
    ),
  );

  Future<List<Map<String, dynamic>>> orders() async =>
      _paginatedRows(await api.get('/pos/orders'));
  Future<List<Map<String, dynamic>>> kots() async =>
      _paginatedRows(await api.get('/pos/kots'));
  Future<List<Map<String, dynamic>>> customers() async =>
      _paginatedRows(await api.get('/pos/customers'));
  Future<List<Map<String, dynamic>>> reservations() async =>
      _paginatedRows(await api.get('/pos/reservations'));

  Future<Map<String, dynamic>?> activeCashSession() async {
    try {
      final response = _map(
        await api.get('/pos/cash-register/sessions/active'),
      );
      return _map(response['data']);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  static int _backendId(String value) {
    final id = int.tryParse(value.replaceFirst('api_', ''));
    if (id == null) throw StateError('Missing backend identifier for $value');
    return id;
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static List<Map<String, dynamic>> _rows(dynamic value) {
    final raw = value is Map && value['data'] is List ? value['data'] : value;
    if (raw is! List) return const [];
    return [
      for (final row in raw)
        if (row is Map) Map<String, dynamic>.from(row),
    ];
  }

  static List<Map<String, dynamic>> _paginatedRows(dynamic value) {
    if (value is Map && value['data'] is Map) {
      return _rows((value['data'] as Map)['data']);
    }
    if (value is Map && value['data'] is List) return _rows(value['data']);
    return _rows(value);
  }

  static String _text(dynamic value, String fallback) =>
      value?.toString().trim().isNotEmpty == true
      ? value.toString().trim()
      : fallback;

  static double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}

class PosBootstrap {
  const PosBootstrap({
    required this.orderTypes,
    required this.taxes,
    required this.orders,
    required this.kots,
    required this.customers,
    required this.reservations,
    required this.printers,
    required this.receiptSettings,
    required this.branches,
    required this.staff,
  });

  final List<Map<String, dynamic>> orderTypes;
  final List<Map<String, dynamic>> taxes;
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> kots;
  final List<Map<String, dynamic>> customers;
  final List<Map<String, dynamic>> reservations;
  final List<Map<String, dynamic>> printers;
  final Map<String, dynamic> receiptSettings;
  final List<Map<String, dynamic>> branches;
  final List<Map<String, dynamic>> staff;
}
