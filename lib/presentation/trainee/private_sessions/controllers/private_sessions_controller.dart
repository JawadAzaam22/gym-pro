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
  final datasource = ref.read(bookingDatasourceProvider);
  final relations = await datasource.getTrainerTrainees(traineeId: traineeId);
  final relationIds = relations.map((r) => r.id).toSet();
  if (relationIds.isEmpty) return [];
  // ملاحظة أداء: getPrivateSessions تجلب كل الجلسات من الخادم ثم تُصفّي
  // محليًا حسب trainerTraineeId، لذا استدعاؤها مرة واحدة لكل علاقة (كما كان
  // سابقًا في حلقة for) كان يعيد تحميل الجدول كاملاً من الخادم N مرة بلا
  // داعٍ. نستدعيها هنا مرة واحدة فقط ونُصفّي محليًا لكل علاقات المتدرب معًا.
  final allSessions = await datasource.getPrivateSessions();
  final result = allSessions
      .where((s) => relationIds.contains(s.trainerTraineeId))
      .map((session) => session.toEntity())
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
  final res = await ref.read(bookingRepositoryProvider).getScheduleForTrainee(traineeId);
  return res.fold((l) => throw Exception(l.message), (r) => r);
});
