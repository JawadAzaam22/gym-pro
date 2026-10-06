import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers.dart';
import '../../../shared/auth/controllers/auth_controller.dart';

class TrainerDashboardData {
  final int traineesCount;
  final int programsCount;
  final int dietsCount;
  final int todaySessions;
  final List<DateTime> todayPrivateSessions;
  const TrainerDashboardData(
      {required this.traineesCount,
      required this.programsCount,
      required this.dietsCount,
      required this.todaySessions,
      required this.todayPrivateSessions});
}

final trainerDashboardProvider =
    FutureProvider<TrainerDashboardData>((ref) async {
  // أي استثناء من الـ datasources ينتشر تلقائيًا كـ AsyncValue.error
  // (بدون قيم بديلة مزخرفة).
  final trainerId = ref.read(authControllerProvider).value?.id ?? '';
  if (trainerId.isEmpty) {
    throw Exception('لا يوجد مستخدم مسجّل — سجّل الدخول أولاً');
  }
  final ds = ref.read(bookingDatasourceProvider);
  final trainees = await ds.getTrainerTrainees(trainerId: trainerId);
  final programs =
      await ref.read(programDatasourceProvider).getProgramsByTrainer(trainerId);
  final diets =
      await ref.read(dietDatasourceProvider).getDietsByTrainer(trainerId);
  // عدّ جلسات هذا المدرب فقط عبر علاقاته (getPrivateSessions بلا فلتر
  // يعيد جلسات كل المدربين — تسريب بيانات).
  int sessionsCount = 0;
  final today = DateTime.now();
  final todayPrivateSessions = <DateTime>[];
  for (final rel in trainees) {
    final sessions = await ds.getPrivateSessions(trainerTraineeId: rel.id);
    final todaysSessions = sessions.where((session) =>
        session.sessionDate.year == today.year &&
        session.sessionDate.month == today.month &&
        session.sessionDate.day == today.day &&
        session.status.name == 'scheduled');
    todayPrivateSessions
        .addAll(todaysSessions.map((session) => session.sessionDate));
    sessionsCount += todaysSessions.length;
  }
  todayPrivateSessions.sort();
  return TrainerDashboardData(
      traineesCount: trainees.length,
      programsCount: programs.length,
      dietsCount: diets.length,
      todaySessions: sessionsCount,
      todayPrivateSessions: todayPrivateSessions);
});
