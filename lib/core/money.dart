import 'package:intl/intl.dart';

final _wholeRupees = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);
final _paise = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

String money(int paise) => paise % 100 == 0
    ? _wholeRupees.format(paise ~/ 100)
    : _paise.format(paise / 100);
