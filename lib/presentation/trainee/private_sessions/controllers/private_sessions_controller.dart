import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers.dart';
import '../../../shared/auth/controllers/auth_controller.dart';
import '../../../../domain/entities/private_training_session.dart';
import '../../../../domain/entities/private_training_schedule.dart';

final traineePrivateSessionsProvider =
    FutureProvider<List<PrivateTrainingSession>>((ref) async {
  final traineeId = ref.read(authControllerProvider).value?.id ?? '';
  if (traineeId.isEmpty) {
    throw Exception('لا يوجد مستخدم مسجل الدخول');
  }
  final relationsResult = await ref.read(getTrainerTraineesProvider).call(
        traineeId: traineeId,
      );
  final relations =
      relationsResult.fold((l) => throw Exception(l.message), (r) => r);
  final relationIds = relations.map((r) => r.id).toSet();
  if (relationIds.isEmpty) return [];
  // ملاحظة أداء: getPrivateSessions تجلب كل الجلسات من الخادم ثم تُصفّي
  // محليًا حسب trainerTraineeId، لذا استدعاؤها مرة واحدة لكل علاقة (كما كان
  // سابقًا في حلقة for) كان يعيد تحميل الجدول كاملاً من الخادم N مرة بلا
  // داعٍ. نستدعيها هنا مرة واحدة فقط ونُصفّي محليًا لكل علاقات المتدرب معًا.
  final sessionsResult =
      await ref.read(getPrivateTrainingSessionsProvider).call();
  final allSessions =
      sessionsResult.fold((l) => throw Exception(l.message), (r) => r);
  final result = allSessions
      .where((s) => relationIds.contains(s.trainerTraineeId))
      .toList();
  result.sort((a, b) => a.sessionDate.compareTo(b.sessionDate));
  return result;
});

/// المواعيد الثابتة الأسبوعية للمتدرب (قراءة فقط)
final traineeFixedScheduleProvider =
    FutureProvider<List<PrivateTrainingSchedule>>((ref) async {
  final traineeId = ref.read(authControllerProvider).value?.id ?? '';
  if (traineeId.isEmpty) {
    throw Exception('لا يوجد مستخدم مسجل الدخول');
  }
  final res =
      await ref.read(getPrivateScheduleForTraineeProvider).call(traineeId);
  return res.fold((l) => throw Exception(l.message), (r) => r);
});
