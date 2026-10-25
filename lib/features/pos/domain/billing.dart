import 'models.dart';

abstract final class Billing {
  /// Tax is applied after discount and rounded to the nearest whole rupee.
  static Bill calculate(
    List<CartLine> lines, {
    int fixedDiscountPaise = 0,
    int percentageDiscountBasisPoints = 0,
    int taxBasisPoints = 500,
  }) {
    final subtotal = lines.fold<int>(0, (sum, line) => sum + line.totalPaise);
    final percentDiscount =
        (subtotal * percentageDiscountBasisPoints + 5000) ~/ 10000;
    final discount = (fixedDiscountPaise + percentDiscount).clamp(0, subtotal);
    final taxable = subtotal - discount;
    final rawTax = (taxable * taxBasisPoints + 5000) ~/ 10000;
    final roundedTax = ((rawTax + 50) ~/ 100) * 100;
    return Bill(subtotal, discount, roundedTax, taxable + roundedTax);
  }
}
