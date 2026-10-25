import 'package:flutter_test/flutter_test.dart';
import 'package:foodzy_pos/features/pos/data/demo_repository.dart';
import 'package:foodzy_pos/features/pos/domain/billing.dart';
import 'package:foodzy_pos/features/pos/domain/models.dart';

void main() {
  final products = DemoMenuRepository().products;
  test('initial reference order totals are internally consistent', () {
    final lines = [
      CartLine(
        key: 'pizza',
        product: products[0],
        modifiers: [DemoMenuRepository.pizzaGroups[1].options[0]],
        quantity: 1,
      ),
      CartLine(
        key: 'burger',
        product: products[8],
        modifiers: [DemoMenuRepository.burgerGroups[0].options[0]],
        quantity: 1,
      ),
      CartLine(
        key: 'pasta',
        product: products[9],
        modifiers: DemoMenuRepository.pastaGroups[0].options,
        quantity: 2,
      ),
      CartLine(
        key: 'coffee',
        product: products[53],
        modifiers: const [],
        quantity: 1,
      ),
    ];
    final bill = Billing.calculate(lines, fixedDiscountPaise: 10000);
    expect(bill.subtotalPaise, 126500);
    expect(bill.discountPaise, 10000);
    expect(bill.taxPaise, 5800);
    expect(bill.totalPaise, 122300);
  });

  test('discount cannot exceed subtotal and tax changes with policy', () {
    final lines = [
      CartLine(
        key: 'one',
        product: products[0],
        modifiers: const [],
        quantity: 1,
      ),
    ];
    expect(Billing.calculate(lines, fixedDiscountPaise: 100000).totalPaise, 0);
    expect(Billing.calculate(lines, taxBasisPoints: 0).totalPaise, 24900);
  });
}
