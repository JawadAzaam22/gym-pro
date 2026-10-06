import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers.dart';
import '../../../shared/auth/controllers/auth_controller.dart';

class TraineeDashboardData {
  final int membershipDaysLeft;
  final int bookingsCount;
  final int attendanceCount;
  const TraineeDashboardData({required this.membershipDaysLeft, required this.bookingsCount, required this.attendanceCount});
}

final traineeDashboardProvider = FutureProvider<TraineeDashboardData>((ref) async {
  // أي فشل في الجلب ينتشر كـ AsyncValue.error (بدون قيم بديلة مزخرفة).
  // غياب العضوية النشطة ليس خطأ: الـ datasource يعيد null في هذه الحالة.
  final currentUser = ref.read(authControllerProvider).value;
  final traineeId = currentUser?.id ?? '';
  if (traineeId.isEmpty) throw Exception('لا يوجد مستخدم مسجّل — سجّل الدخول أولاً');
  // استخدام Repository بدلاً من Datasource مباشر
  final membershipRes = await ref.read(membershipRepositoryProvider).getActiveMembership(traineeId);
  final bookingsRes = await ref.read(bookingRepositoryProvider).getBookingsByTrainee(traineeId);
  final attendanceRes = await ref.read(attendanceRepositoryProvider).getAttendanceByTrainee(traineeId);

  final failure = membershipRes.fold((l) => l.message, (_) => null) ??
      bookingsRes.fold((l) => l.message, (_) => null) ??
      attendanceRes.fold((l) => l.message, (_) => null);
  if (failure != null) throw Exception(failure);

  final membership = membershipRes.getOrElse(() => null);
  final bookings = bookingsRes.getOrElse(() => []);
  final attendance = attendanceRes.getOrElse(() => []);

  final daysLeft = membership != null ? membership.endDate.difference(DateTime.now()).inDays : 0;
  return TraineeDashboardData(membershipDaysLeft: daysLeft, bookingsCount: bookings.length, attendanceCount: attendance.length);
});
