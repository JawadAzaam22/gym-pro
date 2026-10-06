import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/enums.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/attendance.dart';
import '../../../../domain/entities/user.dart';

class ReceptionStats {
  final int todayCheckins;
  final int totalTrainees;
  final int activeMemberships;
  final int pendingPayments;
  const ReceptionStats({
    required this.todayCheckins,
    required this.totalTrainees,
    required this.activeMemberships,
    required this.pendingPayments,
  });
}

final receptionStatsProvider = FutureProvider<ReceptionStats>((ref) async {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  final attendanceRes = await ref.read(attendanceRepositoryProvider).getAllAttendance(from: todayStart, to: todayEnd);
  final usersRes = await ref.read(userRepositoryProvider).getAllUsers();
  final membershipsRes = await ref.read(membershipRepositoryProvider).getAllMemberships();

  final failures = [
    attendanceRes.fold((l) => l.message, (_) => null),
    usersRes.fold((l) => l.message, (_) => null),
    membershipsRes.fold((l) => l.message, (_) => null),
  ].whereType<String>().toList();
  if (failures.isNotEmpty) throw Exception(failures.join('؛ '));

  final attendance = attendanceRes.getOrElse(() => []);
  final users = usersRes.getOrElse(() => []);
  final memberships = membershipsRes.getOrElse(() => []);

  return ReceptionStats(
    todayCheckins: attendance.length,
    totalTrainees: users.where((u) => u.role == UserRole.trainee).length,
    activeMemberships: memberships.where((m) => m.status.name == 'active').length,
    pendingPayments: 0,
  );
});

final recentCheckinsProvider = FutureProvider<List<Map<String, String>>>((ref) async {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  final attRes = await ref.read(attendanceRepositoryProvider).getAllAttendance(from: todayStart, to: todayEnd);
  final usersRes = await ref.read(userRepositoryProvider).getAllUsers();

  final failure = attRes.fold((l) => l.message, (_) => null) ?? usersRes.fold((l) => l.message, (_) => null);
  if (failure != null) throw Exception(failure);

  final List<Attendance> atts = attRes.getOrElse(() => <Attendance>[])..sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
  final List<User> users = usersRes.getOrElse(() => <User>[]);
  final Map<String, String> names = {for (final u in users) u.id: u.name};

  return atts.take(10).map((a) {
    final mins = now.difference(a.checkInTime).inMinutes;
    final ago = mins < 1 ? 'الآن' : mins < 60 ? 'منذ $mins دقيقة' : 'منذ ${mins ~/ 60} ساعة';
    return <String, String>{'name': names[a.traineeId] ?? 'متدرب', 'ago': ago, 'method': a.method.name};
  }).toList();
});
