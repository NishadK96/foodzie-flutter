import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodzy_pos/features/pos/data/demo_repository.dart';
import 'package:foodzy_pos/features/pos/domain/models.dart';
import 'package:foodzy_pos/features/pos/presentation/pos_controller.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('search and category filters combine', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(posControllerProvider.notifier);
    controller.setCategory('pizzas');
    controller.setSearch('tikka');
    expect(controller.visibleProducts().map((p) => p.name), [
      'Chicken Tikka Pizza',
    ]);
  });

  test(
    'identical configurations merge while distinct options stay separate',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(posControllerProvider.notifier);
      controller.selectTable(1);
      final product = container.read(menuRepositoryProvider).products[0];
      controller.addProduct(product, [
        DemoMenuRepository.pizzaGroups[0].options[0],
      ]);
      controller.addProduct(product, [
        DemoMenuRepository.pizzaGroups[0].options[0],
      ]);
      controller.addProduct(product, [
        DemoMenuRepository.pizzaGroups[0].options[1],
      ]);
      final cart = container.read(posControllerProvider).cart;
      expect(cart.length, 2);
      expect(cart.first.quantity, 2);
    },
  );

  test('kitchen sends only new quantities and does not duplicate tickets', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(posControllerProvider.notifier);
    final initial = container.read(posControllerProvider).tickets.length;
    expect(controller.sendToKitchen(), isNotNull);
    expect(controller.sendToKitchen(), isNull);
    expect(container.read(posControllerProvider).tickets.length, initial + 1);
    final key = container.read(posControllerProvider).cart.first.key;
    controller.changeQuantity(key, 1);
    expect(controller.sendToKitchen()!.items.first, contains('1 ×'));
  });

  test('payment closes order and adds to shift total', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(posControllerProvider.notifier);
    final before = container.read(posControllerProvider).shiftTotalPaise;
    final total = container.read(posControllerProvider).bill.totalPaise;
    final order = controller.completePayment(PaymentMethod.cash);
    expect(order!.totalPaise, total);
    expect(container.read(posControllerProvider).cart, isEmpty);
    expect(
      container.read(posControllerProvider).shiftTotalPaise,
      before + total,
    );
  });
}
