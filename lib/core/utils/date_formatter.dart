import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _full = DateFormat('d MMMM yyyy', 'id_ID');
  static final DateFormat _short = DateFormat('d MMM', 'id_ID');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'id_ID');
  static final DateFormat _dayMonth = DateFormat('EEE, d MMM', 'id_ID');

  /// Contoh: 5 September 2026
  static String formatFull(DateTime date) => _full.format(date);

  /// Contoh: 5 Sep
  static String formatShort(DateTime date) => _short.format(date);

  /// Contoh: September 2026
  static String formatMonthYear(DateTime date) => _monthYear.format(date);

  /// Contoh: Sab, 5 Sep
  static String formatDayMonth(DateTime date) => _dayMonth.format(date);

  /// Hari ini / Kemarin / tanggal
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return formatFull(date);
  }

  /// Apakah dua tanggal di bulan yang sama
  static bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }
}
