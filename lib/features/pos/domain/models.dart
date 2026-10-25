enum OrderType { dineIn, takeaway }

enum TableStatus { available, occupied, reserved }

enum TicketStatus { newOrder, preparing, ready }

enum PaymentMethod { cash, card, upi }

enum SortMode { popular, name, priceLow, priceHigh }

class MenuCategory {
  const MenuCategory(this.id, this.name, this.iconKey);
  final String id;
  final String name;
  final String iconKey;
}

class ModifierOption {
  const ModifierOption(this.id, this.name, this.pricePaise);
  final String id;
  final String name;
  final int pricePaise;
}

class ModifierGroup {
  const ModifierGroup(
    this.id,
    this.name,
    this.options, {
    this.required = false,
    this.multiple = false,
  });
  final String id;
  final String name;
  final List<ModifierOption> options;
  final bool required;
  final bool multiple;
}

class MenuProduct {
  const MenuProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.pricePaise,
    required this.imageIndex,
    required this.vegetarian,
    this.groups = const [],
  });
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final int pricePaise;
  final int imageIndex;
  final bool vegetarian;
  final List<ModifierGroup> groups;

  MenuProduct copyWith({List<ModifierGroup>? groups}) => MenuProduct(
    id: id,
    name: name,
    description: description,
    categoryId: categoryId,
    pricePaise: pricePaise,
    imageIndex: imageIndex,
    vegetarian: vegetarian,
    groups: groups ?? this.groups,
  );
}

class CartLine {
  const CartLine({
    required this.key,
    required this.product,
    required this.modifiers,
    required this.quantity,
    this.note = '',
    this.sentQuantity = 0,
  });
  final String key;
  final MenuProduct product;
  final List<ModifierOption> modifiers;
  final int quantity;
  final String note;
  final int sentQuantity;
  int get unitPaise =>
      product.pricePaise +
      modifiers.fold<int>(0, (sum, item) => sum + item.pricePaise);
  int get totalPaise => unitPaise * quantity;
  CartLine copyWith({int? quantity, int? sentQuantity, String? note}) =>
      CartLine(
        key: key,
        product: product,
        modifiers: modifiers,
        quantity: quantity ?? this.quantity,
        sentQuantity: sentQuantity ?? this.sentQuantity,
        note: note ?? this.note,
      );
}

class RestaurantTable {
  const RestaurantTable(
    this.number,
    this.seats,
    this.status, {
    this.backendId,
    this.code,
  });
  final int number;
  final int seats;
  final TableStatus status;
  final int? backendId;
  final String? code;
  RestaurantTable copyWith({TableStatus? status}) => RestaurantTable(
    number,
    seats,
    status ?? this.status,
    backendId: backendId,
    code: code,
  );
}

class KitchenTicket {
  const KitchenTicket(
    this.id,
    this.tableNumber,
    this.items,
    this.status,
    this.createdAt,
  );
  final String id;
  final int? tableNumber;
  final List<String> items;
  final TicketStatus status;
  final DateTime createdAt;
  KitchenTicket copyWith(TicketStatus status) =>
      KitchenTicket(id, tableNumber, items, status, createdAt);
}

class CompletedOrder {
  const CompletedOrder(
    this.id,
    this.tableNumber,
    this.totalPaise,
    this.method,
    this.createdAt,
    this.lines, [
    this.payments = const [],
  ]);
  final String id;
  final int? tableNumber;
  final int totalPaise;
  final PaymentMethod method;
  final DateTime createdAt;
  final List<CartLine> lines;
  final List<PaymentAllocation> payments;
}

class PaymentAllocation {
  const PaymentAllocation(this.method, this.amountPaise);
  final PaymentMethod method;
  final int amountPaise;
}

class Bill {
  const Bill(
    this.subtotalPaise,
    this.discountPaise,
    this.taxPaise,
    this.totalPaise,
  );
  final int subtotalPaise;
  final int discountPaise;
  final int taxPaise;
  final int totalPaise;
}
