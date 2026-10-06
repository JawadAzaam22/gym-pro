import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/payment_cost.dart';
import '../../../../domain/entities/report.dart';

final paymentsProvider = FutureProvider<List<PaymentCost>>((ref) async {
  final res = await ref.read(paymentRepositoryProvider).getAll();
  return res.fold((l) => throw Exception(l.message), (r) => r);
});

final financeSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final from = DateTime.now().subtract(const Duration(days: 30));
  final to = DateTime.now();
  final res = await ref.read(reportRepositoryProvider).getFinancialSummary(from, to);
  return res.fold((l) => throw Exception(l.message), (r) => r);
});

final reportsProvider = FutureProvider<List<Report>>((ref) async {
  final res = await ref.read(reportRepositoryProvider).getReports();
  return res.fold((l) => throw Exception(l.message), (r) => r);
});

/// ملخص الحضور لآخر 30 يوم (إجمالي + متدربون مميزون).
final attendanceSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final from = DateTime.now().subtract(const Duration(days: 30));
  final res = await ref.read(reportRepositoryProvider).getAttendanceSummary(from, DateTime.now());
  return res.fold((l) => throw Exception(l.message), (r) => r);
});

/// عدد تسجيلات الحضور لكل يوم من آخر 7 أيام (للرسم البياني).
final weeklyAttendanceProvider = FutureProvider<List<int>>((ref) async {
  final now = DateTime.now();
  final base = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
  final res = await ref.read(attendanceRepositoryProvider).getAllAttendance(from: base);
  final list = res.fold((l) => throw Exception(l.message), (r) => r);
  final counts = List<int>.filled(7, 0);
  for (final a in list) {
    final d = DateTime(a.checkInTime.year, a.checkInTime.month, a.checkInTime.day);
    final idx = d.difference(base).inDays;
    if (idx >= 0 && idx < 7) counts[idx]++;
  }
  return counts;
});
