import 'package:intl/intl.dart';

/// بيفورمات الأرقام بالجنيه المصري بأرقام غربية (0-9) مش عربية هندية
/// عشان تكون أوضح لمستخدمي القرية اللي اعتادوا عليها أكتر
String formatEGP(num amount) {
  final formatter = NumberFormat.currency(
    locale: 'en',
    symbol: 'ج.م ',
    decimalDigits: 2,
  );
  return formatter.format(amount);
}

/// بدون رمز العملة
String formatNumber(num amount) {
  return NumberFormat('#,##0.##', 'en').format(amount);
}
