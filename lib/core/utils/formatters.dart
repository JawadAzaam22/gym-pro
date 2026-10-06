import 'package:intl/intl.dart';

abstract class Formatters {
  static final _dateFormat = DateFormat('yyyy-MM-dd');
  static final _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final _timeFormat = DateFormat('HH:mm');
  static final _currencyFormat = NumberFormat.currency(
    locale: 'ar_SY',
    symbol: 'ل.س ',
    decimalDigits: 2,
  );

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
  static String formatTime(DateTime time) => _timeFormat.format(time);

  /// يحول "14:30:00" إلى "02:30 PM" أو يبقيها حسب الحاجة
  static String formatTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final dt = DateTime(0, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      return _timeFormat.format(dt);
    } catch (_) {
      return timeStr;
    }
  }

  static String formatCurrency(double amount) => _currencyFormat.format(amount);

  static String formatPhone(String phone) {
    if (phone.length == 11 && phone.startsWith('01')) {
      return '${phone.substring(0, 3)} ${phone.substring(3, 7)} ${phone.substring(7)}';
    }
    return phone;
  }

  static String? tryFormatDate(DateTime? date) =>
      date == null ? null : formatDate(date);

  /// صيغة زمن نسبي بالعربية: "الآن" / "منذ 5 دقائق" / "منذ 3 ساعات" / "أمس" / تاريخ.
  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.isNegative) return formatDateTime(date);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return formatDateTime(date);
  }
}
