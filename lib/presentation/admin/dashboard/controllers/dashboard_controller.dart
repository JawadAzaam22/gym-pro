import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/attendance.dart';
import '../../../../domain/entities/user.dart';

class AdminStats {
  final int totalUsers;
  final int totalHalls;
  final int activeMemberships;
  final int todayCheckins;
  final double income;
  final double expense;
  const AdminStats({required this.totalUsers, required this.totalHalls, required this.activeMemberships, required this.todayCheckins, required this.income, required this.expense});
}

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  // استخدام Repository بدلاً من Datasource مباشر - يحافظ على Either و Failure.
  // أي فشل ينتشر كـ AsyncValue.error (بدون قيم بديلة مزخرفة).
  final usersRes = await ref.read(userRepositoryProvider).getAllUsers();
  final hallsRes = await ref.read(hallRepositoryProvider).getHalls();
  final membershipsRes = await ref.read(membershipRepositoryProvider).getAllMemberships();
  final attendanceRes = await ref.read(attendanceRepositoryProvider).getAllAttendance(from: DateTime.now().subtract(const Duration(days: 1)));
  final incomeRes = await ref.read(paymentRepositoryProvider).getTotalIncome(DateTime.now().subtract(const Duration(days: 30)), DateTime.now());
  final expenseRes = await ref.read(paymentRepositoryProvider).getTotalExpense(DateTime.now().subtract(const Duration(days: 30)), DateTime.now());

  final failures = [
    usersRes.fold((l) => l.message, (_) => null),
    hallsRes.fold((l) => l.message, (_) => null),
    membershipsRes.fold((l) => l.message, (_) => null),
    attendanceRes.fold((l) => l.message, (_) => null),
    incomeRes.fold((l) => l.message, (_) => null),
    expenseRes.fold((l) => l.message, (_) => null),
  ].whereType<String>().toList();
  if (failures.isNotEmpty) throw Exception(failures.join('؛ '));

  final users = usersRes.getOrElse(() => []);
  final halls = hallsRes.getOrElse(() => []);
  final memberships = membershipsRes.getOrElse(() => []);
  final attendance = attendanceRes.getOrElse(() => []);
  final income = incomeRes.getOrElse(() => 0.0);
  final expense = expenseRes.getOrElse(() => 0.0);

  return AdminStats(
    totalUsers: users.length,
    totalHalls: halls.length,
    activeMemberships: memberships.where((m) => m.status.name == 'active').length,
    todayCheckins: attendance.length,
    income: income,
    expense: expense,
  );
});

/// أحدث 5 تسجيلات حضور مع أسماء المتدربين (للوحة التحكم).
final recentCheckinsProvider = FutureProvider<List<Map<String, String>>>((ref) async {
  final attRes = await ref.read(attendanceRepositoryProvider).getAllAttendance(from: DateTime.now().subtract(const Duration(days: 1)));
  final usersRes = await ref.read(userRepositoryProvider).getAllUsers();
  final failure = attRes.fold((l) => l.message, (_) => null) ?? usersRes.fold((l) => l.message, (_) => null);
  if (failure != null) throw Exception(failure);
  final List<Attendance> atts = attRes.getOrElse(() => <Attendance>[])..sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
  final List<User> users = usersRes.getOrElse(() => <User>[]);
  final Map<String, String> names = {for (final u in users) u.id: u.name};
  final now = DateTime.now();
  return atts.take(5).map((a) {
    final mins = now.difference(a.checkInTime).inMinutes;
    final ago = mins < 1 ? 'الآن' : mins < 60 ? 'منذ $mins دقيقة' : 'منذ ${mins ~/ 60} ساعة';
    return <String, String>{'name': names[a.traineeId] ?? 'متدرب', 'ago': ago, 'method': a.method.name};
  }).toList();
});
