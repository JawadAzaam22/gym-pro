import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/day_of_week_helper.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/access_period.dart';
import '../../../../domain/entities/private_training_schedule.dart';
import '../../../../domain/entities/session.dart';


/// المواعيد الثابتة الأسبوعية للمدرب (قراءة فقط)
final trainerFixedScheduleProvider =
    FutureProvider.family<List<PrivateTrainingSchedule>, String>((ref, trainerId) async {
  final res = await ref.read(bookingRepositoryProvider).getScheduleForTrainer(trainerId);
  return res.fold((l) => throw Exception(l.message), (r) => r);
});

final trainerSessionsProvider = FutureProvider.family<List<Session>, String>((ref, trainerId) async {
  final res = await ref.read(sessionRepositoryProvider).getSessionsByTrainer(trainerId);
  return res.fold((l) => throw Exception(l.message), (r) => r);
});

/// نفس حصص المدرب الجماعية لكن مُغناة باسم القاعة ونص الموعد الأسبوعي
/// الفعلي (كانت الشاشة تعرض فقط تاريخ بداية/نهاية التسجيل بلا أي فكرة عن
/// اليوم/الوقت الحقيقي الذي تنعقد فيه الحصة).
final trainerSessionsDisplayProvider =
    FutureProvider.family<List<TrainerSessionDisplay>, String>((ref, trainerId) async {
  final sessions = await ref.watch(trainerSessionsProvider(trainerId).future);
  if (sessions.isEmpty) return [];

  final hallsRes = await ref.read(hallRepositoryProvider).getHalls();
  final hallNames = {for (final h in hallsRes.getOrElse(() => [])) h.id: h.name};

  final sessionPeriodsRes =
      await ref.read(sessionRepositoryProvider).getAllSessionPeriods();
  final sessionPeriods = sessionPeriodsRes.getOrElse(() => {});

  final periodsRes = await ref.read(hallRepositoryProvider).getAllAccessPeriods();
  final periodsById = <int, AccessPeriod>{
    for (final p in periodsRes.getOrElse(() => <AccessPeriod>[])) p.id: p,
  };

  String scheduleTextFor(Session s) {
    final ids = sessionPeriods[s.id] ?? const <int>{};
    if (ids.isEmpty) return 'الموعد غير محدد بعد';
    final parts = ids
        .map((id) => periodsById[id])
        .whereType<AccessPeriod>()
        .map((p) =>
            '${DayOfWeekHelper.name(p.dayOfWeek)} ${p.startTime.substring(0, 5)}-${p.endTime.substring(0, 5)}')
        .toList()
      ..sort();
    return parts.join(' • ');
  }

  return sessions
      .map((s) => TrainerSessionDisplay(
            session: s,
            hallName: hallNames[s.hallId] ?? 'قاعة',
            scheduleText: scheduleTextFor(s),
          ))
      .toList();
});

class TrainerSessionDisplay {
  final Session session;
  final String hallName;
  final String scheduleText;
  const TrainerSessionDisplay(
      {required this.session, required this.hallName, required this.scheduleText});
}

/// فترات مناوبة المدرب في القاعات (access_periods.trainer_id = هو) عبر كل
/// القاعات، مع اسم القاعة جاهزًا للعرض. نستخدم getAllAccessPeriods() (جلب
/// دفعة واحدة لكل القاعات) بدل استعلام لكل قاعة على حدة، ثم نُصفّي محليًا
/// لفترات هذا المدرب فقط.
final trainerShiftPeriodsProvider =
    FutureProvider.family<List<TrainerShiftPeriod>, String>((ref, trainerId) async {
  final periodsRes = await ref.read(hallRepositoryProvider).getAllAccessPeriods();
  final periods = periodsRes.fold((l) => throw Exception(l.message), (r) => r);
  final mine = periods.where((p) => p.trainerId == trainerId).toList();
  if (mine.isEmpty) return [];

  final hallsRes = await ref.read(hallRepositoryProvider).getHalls();
  final hallNames = {
    for (final h in hallsRes.getOrElse(() => [])) h.id: h.name,
  };

  return mine
      .map((p) => TrainerShiftPeriod(
            dayOfWeek: p.dayOfWeek,
            startTime: p.startTime,
            endTime: p.endTime,
            hallName: hallNames[p.hallId] ?? 'قاعة',
            isActive: p.isActive,
          ))
      .toList();
});

class TrainerShiftPeriod {
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String hallName;
  final bool isActive;
  const TrainerShiftPeriod({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.hallName,
    required this.isActive,
  });
}
