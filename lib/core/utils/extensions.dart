import 'package:intl/intl.dart';

extension StringX on String {
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  bool get isValidEmail =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);

  bool get isValidPhone => RegExp(r'^01[0-2,5]{1}[0-9]{8}$').hasMatch(this);
}

extension DateTimeX on DateTime {
  String get toDateString => DateFormat('yyyy-MM-dd').format(this);
  String get toDateTimeString => DateFormat('yyyy-MM-dd HH:mm').format(this);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isPast => isBefore(DateTime.now());
  bool get isFuture => isAfter(DateTime.now());
}

extension IterableX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
