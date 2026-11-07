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
  final traineesResult =
      await ref.read(getTrainerTraineesProvider).call(trainerId: trainerId);
  final trainees =
      traineesResult.fold((l) => throw Exception(l.message), (r) => r);
  final programsResult =
      await ref.read(programUseCasesProvider).getProgramsByTrainer(trainerId);
  final programs =
      programsResult.fold((l) => throw Exception(l.message), (r) => r);
  final dietsResult =
      await ref.read(dietUseCasesProvider).getDietsByTrainer(trainerId);
  final diets = dietsResult.fold((l) => throw Exception(l.message), (r) => r);
  // عدّ جلسات هذا المدرب فقط عبر علاقاته (getPrivateSessions بلا فلتر
  // يعيد جلسات كل المدربين — تسريب بيانات).
  int sessionsCount = 0;
  final today = DateTime.now();
  final todayPrivateSessions = <DateTime>[];
  for (final rel in trainees) {
    final sessionsResult = await ref
        .read(getPrivateTrainingSessionsProvider)
        .call(trainerTraineeId: rel.id);
    final sessions =
        sessionsResult.fold((l) => throw Exception(l.message), (r) => r);
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
