import '../domain/models.dart';

abstract class MenuRepository {
  List<MenuCategory> get categories;
  List<MenuProduct> get products;
  List<RestaurantTable> get tables;
  List<KitchenTicket> get tickets;
  List<CompletedOrder> get orders;
}

class DemoMenuRepository implements MenuRepository {
  static const pizzaGroups = [
    ModifierGroup('crust', 'Crust', [
      ModifierOption('thin', 'Thin Crust', 0),
      ModifierOption('classic', 'Classic Crust', 0),
    ], required: true),
    ModifierGroup('pizza_extra', 'Add extras', [
      ModifierOption('cheese40', 'Extra Cheese', 4000),
      ModifierOption('olives30', 'Olives', 3000),
      ModifierOption('jalapeno25', 'Jalapeños', 2500),
    ], multiple: true),
  ];
  static const burgerGroups = [
    ModifierGroup('burger_extra', 'Add extras', [
      ModifierOption('cheese20', 'Add Cheese', 2000),
      ModifierOption('patty70', 'Extra Patty', 7000),
    ], multiple: true),
    ModifierGroup('burger_note', 'Preferences', [
      ModifierOption('no_onion', 'No Onion', 0),
      ModifierOption('extra_sauce', 'Extra Sauce', 0),
    ], multiple: true),
  ];
  static const pastaGroups = [
    ModifierGroup('pasta_extra', 'Add extras', [
      ModifierOption('chicken60', 'Extra Chicken', 6000),
      ModifierOption('bread40', 'Garlic Bread', 4000),
    ], multiple: true),
    ModifierGroup('pasta_spice', 'Spice preference', [
      ModifierOption('mild', 'Mild', 0),
      ModifierOption('regular', 'Regular', 0),
      ModifierOption('spicy', 'Spicy', 0),
    ]),
  ];

  @override
  final List<MenuCategory> categories = const [
    MenuCategory('all', 'All Items', 'all'),
    MenuCategory('starters', 'Starters', 'starters'),
    MenuCategory('soups', 'Soups', 'soups'),
    MenuCategory('salads', 'Salads', 'salads'),
    MenuCategory('mains', 'Main Course', 'mains'),
    MenuCategory('rice', 'Biryani & Rice', 'rice'),
    MenuCategory('pizzas', 'Pizzas', 'pizzas'),
    MenuCategory('burgers', 'Burgers', 'burgers'),
    MenuCategory('sandwiches', 'Sandwiches', 'sandwiches'),
    MenuCategory('pasta', 'Pasta', 'pasta'),
    MenuCategory('chinese', 'Chinese', 'chinese'),
    MenuCategory('desserts', 'Desserts', 'desserts'),
    MenuCategory('beverages', 'Beverages', 'beverages'),
  ];

  @override
  late final List<MenuProduct> products = _buildProducts();

  List<MenuProduct> _buildProducts() {
    final rows =
        <(String, String, String, int, int, bool, List<ModifierGroup>)>[
          (
            'Margherita Pizza',
            'Classic tomato, mozzarella, basil',
            'pizzas',
            249,
            0,
            true,
            pizzaGroups,
          ),
          (
            'Chicken Tikka Pizza',
            'Spiced chicken, onion, capsicum',
            'pizzas',
            329,
            1,
            false,
            pizzaGroups,
          ),
          (
            'Paneer Butter Masala',
            'Rich and creamy curry',
            'mains',
            249,
            2,
            true,
            [],
          ),
          (
            'Butter Chicken',
            'Classic North Indian style',
            'mains',
            279,
            3,
            false,
            [],
          ),
          (
            'Veg Biryani',
            'Fragrant basmati with vegetables',
            'rice',
            219,
            4,
            true,
            [],
          ),
          ('Chicken Biryani', 'Hyderabadi style', 'rice', 269, 5, false, []),
          (
            'Caesar Salad',
            'Fresh greens, parmesan, croutons',
            'salads',
            169,
            6,
            true,
            [],
          ),
          ('French Fries', 'Crispy and golden', 'starters', 129, 7, true, []),
          (
            'Chicken Burger',
            'Grilled chicken and lettuce',
            'burgers',
            179,
            8,
            false,
            burgerGroups,
          ),
          (
            'Pasta Alfredo',
            'Creamy white sauce pasta',
            'pasta',
            229,
            9,
            true,
            pastaGroups,
          ),
          ('Grilled Fish', 'Lemon butter sauce', 'mains', 299, 10, false, []),
          (
            'Chocolate Brownie',
            'With vanilla ice cream',
            'desserts',
            139,
            11,
            true,
            [],
          ),
          (
            'Tomato Basil Soup',
            'Slow simmered tomatoes',
            'soups',
            129,
            2,
            true,
            [],
          ),
          (
            'Sweet Corn Soup',
            'Corn and spring onion',
            'soups',
            119,
            2,
            true,
            [],
          ),
          ('Hot and Sour Soup', 'Tangy and warming', 'soups', 139, 3, true, []),
          (
            'Greek Salad',
            'Cucumber, feta and olives',
            'salads',
            189,
            6,
            true,
            [],
          ),
          ('Garden Salad', 'Seasonal greens', 'salads', 149, 6, true, []),
          (
            'Chicken Caesar Salad',
            'Grilled chicken and greens',
            'salads',
            219,
            6,
            false,
            [],
          ),
          (
            'Paneer Tikka',
            'Tandoori paneer cubes',
            'starters',
            229,
            2,
            true,
            [],
          ),
          (
            'Chicken Tikka',
            'Chargrilled chicken bites',
            'starters',
            249,
            10,
            false,
            [],
          ),
          (
            'Garlic Bread',
            'Toasted with herb butter',
            'starters',
            109,
            9,
            true,
            [],
          ),
          (
            'Chilli Paneer',
            'Indo-Chinese favourite',
            'starters',
            219,
            2,
            true,
            [],
          ),
          ('Crispy Corn', 'Spiced golden corn', 'starters', 149, 7, true, []),
          (
            'Dal Makhani',
            'Slow cooked black lentils',
            'mains',
            199,
            2,
            true,
            [],
          ),
          ('Kadai Paneer', 'Paneer and peppers', 'mains', 249, 2, true, []),
          (
            'Chicken Curry',
            'Homestyle spiced gravy',
            'mains',
            259,
            3,
            false,
            [],
          ),
          (
            'Palak Paneer',
            'Spinach and cottage cheese',
            'mains',
            239,
            2,
            true,
            [],
          ),
          ('Jeera Rice', 'Cumin scented basmati', 'rice', 129, 4, true, []),
          ('Egg Fried Rice', 'Wok tossed with egg', 'rice', 169, 5, false, []),
          ('Paneer Biryani', 'Aromatic layered rice', 'rice', 249, 4, true, []),
          (
            'Mutton Biryani',
            'Slow cooked dum style',
            'rice',
            349,
            5,
            false,
            [],
          ),
          (
            'Farmhouse Pizza',
            'Vegetables and mozzarella',
            'pizzas',
            289,
            0,
            true,
            pizzaGroups,
          ),
          (
            'Pepperoni Pizza',
            'Classic pepperoni and cheese',
            'pizzas',
            349,
            1,
            false,
            pizzaGroups,
          ),
          (
            'BBQ Chicken Pizza',
            'Smoky barbecue chicken',
            'pizzas',
            359,
            1,
            false,
            pizzaGroups,
          ),
          (
            'Veg Burger',
            'Crispy vegetable patty',
            'burgers',
            159,
            8,
            true,
            burgerGroups,
          ),
          (
            'Paneer Burger',
            'Spiced paneer patty',
            'burgers',
            189,
            8,
            true,
            burgerGroups,
          ),
          (
            'Double Chicken Burger',
            'Two grilled patties',
            'burgers',
            269,
            8,
            false,
            burgerGroups,
          ),
          (
            'Club Sandwich',
            'Triple layer classic',
            'sandwiches',
            189,
            8,
            false,
            [],
          ),
          (
            'Grilled Cheese Sandwich',
            'Melted cheese on toast',
            'sandwiches',
            149,
            8,
            true,
            [],
          ),
          (
            'Chicken Sandwich',
            'Herb chicken filling',
            'sandwiches',
            199,
            8,
            false,
            [],
          ),
          (
            'Veg Sandwich',
            'Fresh seasonal vegetables',
            'sandwiches',
            129,
            6,
            true,
            [],
          ),
          (
            'Penne Arrabbiata',
            'Spicy tomato sauce',
            'pasta',
            209,
            9,
            true,
            pastaGroups,
          ),
          (
            'Pesto Pasta',
            'Basil and parmesan',
            'pasta',
            239,
            9,
            true,
            pastaGroups,
          ),
          (
            'Chicken Alfredo',
            'Cream sauce and chicken',
            'pasta',
            269,
            9,
            false,
            pastaGroups,
          ),
          (
            'Veg Hakka Noodles',
            'Wok tossed noodles',
            'chinese',
            179,
            5,
            true,
            [],
          ),
          (
            'Chicken Hakka Noodles',
            'Wok tossed with chicken',
            'chinese',
            219,
            5,
            false,
            [],
          ),
          (
            'Veg Manchurian',
            'Crisp bites in sauce',
            'chinese',
            199,
            2,
            true,
            [],
          ),
          (
            'Chilli Chicken',
            'Spicy wok-fried chicken',
            'chinese',
            249,
            3,
            false,
            [],
          ),
          (
            'Schezwan Fried Rice',
            'Fiery and aromatic',
            'chinese',
            199,
            4,
            true,
            [],
          ),
          (
            'Gulab Jamun',
            'Warm syrup-soaked sweet',
            'desserts',
            99,
            11,
            true,
            [],
          ),
          (
            'Brownie Sundae',
            'Chocolate and ice cream',
            'desserts',
            169,
            11,
            true,
            [],
          ),
          (
            'Vanilla Ice Cream',
            'Two creamy scoops',
            'desserts',
            89,
            11,
            true,
            [],
          ),
          ('Cheesecake', 'Baked cream cheese', 'desserts', 189, 11, true, []),
          (
            'Cold Coffee',
            'Chilled coffee blend',
            'beverages',
            119,
            12,
            true,
            [],
          ),
          ('Masala Chai', 'Spiced Indian tea', 'beverages', 59, 13, true, []),
          ('Fresh Lime Soda', 'Sweet or salted', 'beverages', 89, 14, true, []),
          (
            'Mango Lassi',
            'Thick mango yoghurt',
            'beverages',
            129,
            15,
            true,
            [],
          ),
          (
            'Cappuccino',
            'Espresso and steamed milk',
            'beverages',
            129,
            12,
            true,
            [],
          ),
          ('Iced Tea', 'Peach or lemon', 'beverages', 99, 14, true, []),
          (
            'Mineral Water',
            'Chilled bottled water',
            'beverages',
            39,
            14,
            true,
            [],
          ),
        ];
    return [
      for (var i = 0; i < rows.length; i++)
        MenuProduct(
          id: 'item_${i + 1}',
          name: rows[i].$1,
          description: rows[i].$2,
          categoryId: rows[i].$3,
          pricePaise: rows[i].$4 * 100,
          imageIndex: rows[i].$5,
          vegetarian: rows[i].$6,
          groups: rows[i].$7,
        ),
    ];
  }

  @override
  List<RestaurantTable> get tables => [
    for (var i = 1; i <= 15; i++)
      RestaurantTable(
        i,
        i % 4 == 0 ? 4 : 2,
        i == 8 || i == 3 || i == 11
            ? TableStatus.occupied
            : i == 5
            ? TableStatus.reserved
            : TableStatus.available,
      ),
  ];

  @override
  List<KitchenTicket> get tickets => [
    for (var i = 1; i <= 5; i++)
      KitchenTicket(
        'KOT-${1000 + i}',
        i + 2,
        ['${i + 1} × ${products[i].name}', products[i + 6].name],
        i <= 2
            ? TicketStatus.newOrder
            : i <= 4
            ? TicketStatus.preparing
            : TicketStatus.ready,
        DateTime.now().subtract(Duration(minutes: i * 4)),
      ),
  ];

  @override
  List<CompletedOrder> get orders => [
    for (var i = 1; i <= 10; i++)
      CompletedOrder(
        'ORD-${1040 + i}',
        i,
        (245 + i * 87) * 100,
        PaymentMethod.values[i % 3],
        DateTime.now().subtract(Duration(minutes: i * 32)),
        [],
      ),
  ];
}
