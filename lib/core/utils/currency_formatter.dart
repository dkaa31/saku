import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _idr = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static final NumberFormat _compact = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 1,
  );

  /// Format: Rp 1.500.000
  static String format(double amount) => _idr.format(amount);

  /// Format: Rp 1,5 jt (untuk tampilan ringkas)
  static String formatCompact(double amount) {
    if (amount.abs() >= 1000000) {
      return _compact.format(amount);
    }
    return _idr.format(amount);
  }

  /// Parse string ke double, menghapus karakter non-numerik
  static double? parse(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  /// Format input angka saat mengetik (1500000 → 1.500.000)
  static String formatInput(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return '';
    final number = int.tryParse(cleaned) ?? 0;
    return NumberFormat('#,###', 'id_ID').format(number);
  }
}
