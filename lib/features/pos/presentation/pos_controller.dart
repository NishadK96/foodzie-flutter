import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/demo_repository.dart';
import '../data/live_menu_repository.dart';
import '../domain/billing.dart';
import '../domain/models.dart';

final menuRepositoryProvider = Provider<MenuRepository>(
  (ref) => ref.watch(catalogControllerProvider).value ?? DemoMenuRepository(),
);
final posControllerProvider = NotifierProvider<PosController, PosState>(
  PosController.new,
);

class PosState {
  const PosState({
    required this.carts,
    required this.selectedTable,
    required this.tables,
    required this.tickets,
    required this.orders,
    required this.shiftTotalPaise,
    this.orderNotes = const {},
    this.search = '',
    this.category = 'all',
    this.sort = SortMode.popular,
    this.grid = true,
    this.sidebarCollapsed = false,
    this.fixedDiscountPaise = 10000,
    this.percentageDiscountBasisPoints = 0,
    this.taxBasisPoints = 500,
  });
  final Map<int, List<CartLine>> carts;
  final int selectedTable; // 0 represents takeaway.
  final List<RestaurantTable> tables;
  final List<KitchenTicket> tickets;
  final List<CompletedOrder> orders;
  final int shiftTotalPaise;
  final Map<int, String> orderNotes;
  final String search;
  final String category;
  final SortMode sort;
  final bool grid;
  final bool sidebarCollapsed;
  final int fixedDiscountPaise;
  final int percentageDiscountBasisPoints;
  final int taxBasisPoints;

  List<CartLine> get cart => carts[selectedTable] ?? const [];
  Bill get bill => Billing.calculate(
    cart,
    fixedDiscountPaise: fixedDiscountPaise,
    percentageDiscountBasisPoints: percentageDiscountBasisPoints,
    taxBasisPoints: taxBasisPoints,
  );
  int get pendingTickets =>
      tickets.where((ticket) => ticket.status != TicketStatus.ready).length;
  int get unsentItemCount =>
      cart.fold(0, (total, line) => total + line.quantity - line.sentQuantity);
  String get activeNote => orderNotes[selectedTable] ?? '';

  PosState copyWith({
    Map<int, List<CartLine>>? carts,
    int? selectedTable,
    List<RestaurantTable>? tables,
    List<KitchenTicket>? tickets,
    List<CompletedOrder>? orders,
    int? shiftTotalPaise,
    Map<int, String>? orderNotes,
    String? search,
    String? category,
    SortMode? sort,
    bool? grid,
    bool? sidebarCollapsed,
    int? fixedDiscountPaise,
    int? percentageDiscountBasisPoints,
    int? taxBasisPoints,
  }) => PosState(
    carts: carts ?? this.carts,
    selectedTable: selectedTable ?? this.selectedTable,
    tables: tables ?? this.tables,
    tickets: tickets ?? this.tickets,
    orders: orders ?? this.orders,
    shiftTotalPaise: shiftTotalPaise ?? this.shiftTotalPaise,
    orderNotes: orderNotes ?? this.orderNotes,
    search: search ?? this.search,
    category: category ?? this.category,
    sort: sort ?? this.sort,
    grid: grid ?? this.grid,
    sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
    fixedDiscountPaise: fixedDiscountPaise ?? this.fixedDiscountPaise,
    percentageDiscountBasisPoints:
        percentageDiscountBasisPoints ?? this.percentageDiscountBasisPoints,
    taxBasisPoints: taxBasisPoints ?? this.taxBasisPoints,
  );
}

class PosController extends Notifier<PosState> {
  static const _storageKey = 'foodzy_pos_draft_v1';

  @override
  PosState build() {
    final repo = ref.watch(menuRepositoryProvider);
    final products = repo.products;
    final seeded = repo is DemoMenuRepository
        ? <CartLine>[
            CartLine(
              key: 'item_1|cheese40,thin',
              product: products[0],
              modifiers: [
                DemoMenuRepository.pizzaGroups[0].options[0],
                DemoMenuRepository.pizzaGroups[1].options[0],
              ],
              quantity: 1,
            ),
            CartLine(
              key: 'item_9|cheese20,no_onion',
              product: products[8],
              modifiers: [
                DemoMenuRepository.burgerGroups[0].options[0],
                DemoMenuRepository.burgerGroups[1].options[0],
              ],
              quantity: 1,
            ),
            CartLine(
              key: 'item_10|bread40,chicken60',
              product: products[9],
              modifiers: [
                DemoMenuRepository.pastaGroups[0].options[0],
                DemoMenuRepository.pastaGroups[0].options[1],
              ],
              quantity: 2,
            ),
            CartLine(
              key: 'item_54|',
              product: products[53],
              modifiers: const [],
              quantity: 1,
            ),
          ]
        : <CartLine>[];
    Future.microtask(() => _restore(repo));
    final selectedTable = repo is DemoMenuRepository
        ? 8
        : repo.tables.firstOrNull?.number ?? 0;
    return PosState(
      carts: {selectedTable: seeded},
      selectedTable: selectedTable,
      tables: repo.tables,
      tickets: repo.tickets,
      orders: repo.orders,
      shiftTotalPaise: repo is DemoMenuRepository ? 1235000 : 0,
      fixedDiscountPaise: repo is DemoMenuRepository ? 10000 : 0,
    );
  }

  List<MenuProduct> visibleProducts() {
    final query = state.search.trim().toLowerCase();
    final products = ref
        .read(menuRepositoryProvider)
        .products
        .where(
          (product) =>
              (state.category == 'all' ||
                  product.categoryId == state.category) &&
              (query.isEmpty ||
                  product.name.toLowerCase().contains(query) ||
                  product.description.toLowerCase().contains(query)),
        )
        .toList();
    switch (state.sort) {
      case SortMode.popular:
        break;
      case SortMode.name:
        products.sort((a, b) => a.name.compareTo(b.name));
      case SortMode.priceLow:
        products.sort((a, b) => a.pricePaise.compareTo(b.pricePaise));
      case SortMode.priceHigh:
        products.sort((a, b) => b.pricePaise.compareTo(a.pricePaise));
    }
    return products;
  }

  void setSearch(String value) => state = state.copyWith(search: value);
  void setCategory(String value) => state = state.copyWith(category: value);
  void setSort(SortMode value) => state = state.copyWith(sort: value);
  void toggleGrid() => state = state.copyWith(grid: !state.grid);
  void toggleSidebar() =>
      state = state.copyWith(sidebarCollapsed: !state.sidebarCollapsed);
  void selectTable(int number) {
    state = state.copyWith(selectedTable: number);
    _save();
  }

  void setOrderNote(String value) {
    state = state.copyWith(
      orderNotes: {...state.orderNotes, state.selectedTable: value},
    );
    _save();
  }

  void addProduct(
    MenuProduct product,
    List<ModifierOption> modifiers, {
    String note = '',
  }) {
    final ids = modifiers.map((option) => option.id).toList()..sort();
    final key = '${product.id}|${ids.join(',')}|$note';
    final cart = [...state.cart];
    final index = cart.indexWhere((line) => line.key == key);
    if (index >= 0) {
      cart[index] = cart[index].copyWith(quantity: cart[index].quantity + 1);
    } else {
      cart.add(
        CartLine(
          key: key,
          product: product,
          modifiers: modifiers,
          quantity: 1,
          note: note,
        ),
      );
    }
    _replaceCart(cart);
  }

  void changeQuantity(String key, int delta) {
    final cart = [...state.cart];
    final index = cart.indexWhere((line) => line.key == key);
    if (index < 0) return;
    final line = cart[index];
    final next = line.quantity + delta;
    if (next < 1 || next < line.sentQuantity) return;
    cart[index] = line.copyWith(quantity: next);
    _replaceCart(cart);
  }

  bool removeLine(String key) {
    final line = state.cart.where((item) => item.key == key).firstOrNull;
    if (line == null || line.sentQuantity > 0) return false;
    _replaceCart(state.cart.where((item) => item.key != key).toList());
    return true;
  }

  bool clearOrder() {
    if (state.cart.any((line) => line.sentQuantity > 0)) return false;
    _replaceCart([]);
    return true;
  }

  void setFixedDiscount(int paise) {
    state = state.copyWith(
      fixedDiscountPaise: paise.clamp(0, state.bill.subtotalPaise),
    );
    _save();
  }

  void setPercentDiscount(int basisPoints) {
    state = state.copyWith(
      percentageDiscountBasisPoints: basisPoints.clamp(0, 10000),
    );
    _save();
  }

  void setTaxRate(int basisPoints) {
    state = state.copyWith(taxBasisPoints: basisPoints.clamp(0, 10000));
    _save();
  }

  KitchenTicket? sendToKitchen() {
    if (state.unsentItemCount == 0) return null;
    final items = [
      for (final line in state.cart)
        if (line.quantity > line.sentQuantity)
          '${line.quantity - line.sentQuantity} × ${line.product.name}${line.modifiers.isEmpty ? '' : ' (${line.modifiers.map((m) => m.name).join(', ')})'}',
    ];
    final ticket = KitchenTicket(
      'KOT-${1001 + state.tickets.length}',
      state.selectedTable == 0 ? null : state.selectedTable,
      items,
      TicketStatus.newOrder,
      DateTime.now(),
    );
    final cart = [
      for (final line in state.cart) line.copyWith(sentQuantity: line.quantity),
    ];
    state = state.copyWith(
      tickets: [ticket, ...state.tickets],
      carts: {...state.carts, state.selectedTable: cart},
    );
    _save();
    return ticket;
  }

  void setTicketStatus(String id, TicketStatus status) =>
      state = state.copyWith(
        tickets: [
          for (final ticket in state.tickets)
            ticket.id == id ? ticket.copyWith(status) : ticket,
        ],
      );

  CompletedOrder? completePayment(
    PaymentMethod method, {
    List<PaymentAllocation> payments = const [],
  }) {
    if (state.cart.isEmpty || state.bill.totalPaise <= 0) return null;
    if (payments.isNotEmpty &&
        payments.fold<int>(0, (sum, payment) => sum + payment.amountPaise) !=
            state.bill.totalPaise) {
      return null;
    }
    final order = CompletedOrder(
      'ORD-${1041 + state.orders.length}',
      state.selectedTable == 0 ? null : state.selectedTable,
      state.bill.totalPaise,
      method,
      DateTime.now(),
      [...state.cart],
      payments.isEmpty
          ? [PaymentAllocation(method, state.bill.totalPaise)]
          : payments,
    );
    final carts = {...state.carts, state.selectedTable: <CartLine>[]};
    final tables = [
      for (final table in state.tables)
        table.number == state.selectedTable
            ? table.copyWith(status: TableStatus.available)
            : table,
    ];
    state = state.copyWith(
      orders: [order, ...state.orders],
      carts: carts,
      tables: tables,
      shiftTotalPaise: state.shiftTotalPaise + order.totalPaise,
      fixedDiscountPaise: 0,
      percentageDiscountBasisPoints: 0,
      orderNotes: {...state.orderNotes, state.selectedTable: ''},
    );
    _save();
    return order;
  }

  void _replaceCart(List<CartLine> cart) {
    state = state.copyWith(carts: {...state.carts, state.selectedTable: cart});
    _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'selectedTable': state.selectedTable,
      'discount': state.fixedDiscountPaise,
      'percent': state.percentageDiscountBasisPoints,
      'tax': state.taxBasisPoints,
      'shift': state.shiftTotalPaise,
      'notes': state.orderNotes.map((key, value) => MapEntry('$key', value)),
      'carts': state.carts.map(
        (key, lines) => MapEntry('$key', [
          for (final line in lines)
            {
              'product': line.product.id,
              'modifiers': line.modifiers.map((m) => m.id).toList(),
              'quantity': line.quantity,
              'sent': line.sentQuantity,
              'note': line.note,
            },
        ]),
      ),
    };
    await prefs.setString(_storageKey, jsonEncode(payload));
  }

  Future<void> _restore(MenuRepository sourceRepository) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final products = ref.read(menuRepositoryProvider).products;
      final byId = {for (final product in products) product.id: product};
      final carts = <int, List<CartLine>>{};
      for (final entry in (data['carts'] as Map<String, dynamic>).entries) {
        carts[int.parse(entry.key)] = [
          for (final rawLine in entry.value as List)
            _restoreLine(rawLine as Map<String, dynamic>, byId),
        ];
      }
      if (!identical(sourceRepository, ref.read(menuRepositoryProvider))) {
        return;
      }
      state = state.copyWith(
        carts: carts,
        selectedTable: data['selectedTable'] as int,
        fixedDiscountPaise: data['discount'] as int,
        percentageDiscountBasisPoints: data['percent'] as int,
        taxBasisPoints: data['tax'] as int? ?? 500,
        shiftTotalPaise: data['shift'] as int,
        orderNotes: (data['notes'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(int.parse(key), value as String),
        ),
      );
    } catch (_) {
      // Leave the usable seeded order in place if an older draft is invalid.
    }
  }

  CartLine _restoreLine(
    Map<String, dynamic> raw,
    Map<String, MenuProduct> products,
  ) {
    final product = products[raw['product']]!;
    final options = [for (final group in product.groups) ...group.options];
    final modifiers = [
      for (final id in raw['modifiers'] as List)
        options.firstWhere((option) => option.id == id),
    ];
    final ids = modifiers.map((m) => m.id).toList()..sort();
    final note = raw['note'] as String;
    return CartLine(
      key: '${product.id}|${ids.join(',')}|$note',
      product: product,
      modifiers: modifiers,
      quantity: raw['quantity'] as int,
      sentQuantity: raw['sent'] as int,
      note: note,
    );
  }
}
