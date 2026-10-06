import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/utils/day_of_week_helper.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/access_period.dart';
import '../../../../domain/entities/session.dart';

/// بيانات حصة جماعية جاهزة للعرض: الحصة + اسم المدرب + اسم القاعة + نص
/// جاهز بأيام/أوقات الانعقاد الفعلية (من access_periods المرتبطة عبر
/// session_periods) — الشاشة القديمة كانت تعرض الحصة بلا اسم مدرب ولا قاعة
/// ولا أي معلومة عن موعدها الأسبوعي الفعلي (فقط تاريخ بداية/نهاية التسجيل)،
/// فكانت عمليًا عديمة الفائدة لمتدرب يريد معرفة متى تنعقد الحصة.
class GroupSessionDisplay {
  final Session session;
  final String trainerName;
  final String hallName;
  final String scheduleText;
  const GroupSessionDisplay({
    required this.session,
    required this.trainerName,
    required this.hallName,
    required this.scheduleText,
  });
}

final groupSessionsDisplayProvider =
    FutureProvider<List<GroupSessionDisplay>>((ref) async {
  final sessionsRes = await ref.read(sessionRepositoryProvider).getSessions();
  final allSessions = sessionsRes.fold((l) => throw Exception(l.message), (r) => r);
  // لا تهم المتدرب الحصص الملغاة.
  final sessions =
      allSessions.where((s) => s.status != SessionStatus.cancelled).toList();
  if (sessions.isEmpty) return [];

  final usersRes = await ref.read(userRepositoryProvider).getAllUsers();
  final userNames = {
    for (final u in usersRes.getOrElse(() => [])) u.id: u.name,
  };

  final hallsRes = await ref.read(hallRepositoryProvider).getHalls();
  final hallNames = {
    for (final h in hallsRes.getOrElse(() => [])) h.id: h.name,
  };

  final sessionPeriodsRes =
      await ref.read(sessionRepositoryProvider).getAllSessionPeriods();
  final sessionPeriods = sessionPeriodsRes.getOrElse(() => {});

  final periodsRes = await ref.read(hallRepositoryProvider).getAllAccessPeriods();
  final periodsById = <int, AccessPeriod>{
    for (final p in periodsRes.getOrElse(() => <AccessPeriod>[])) p.id: p,
  };

  String scheduleTextFor(Session s) {
    final periodIds = sessionPeriods[s.id] ?? const <int>{};
    if (periodIds.isEmpty) return 'الموعد غير محدد بعد';
    final parts = periodIds
        .map((id) => periodsById[id])
        .whereType<AccessPeriod>()
        .map((p) =>
            '${DayOfWeekHelper.name(p.dayOfWeek)} ${p.startTime.substring(0, 5)}-${p.endTime.substring(0, 5)}')
        .toList()
      ..sort();
    return parts.join(' • ');
  }

  return sessions
      .map((s) => GroupSessionDisplay(
            session: s,
            trainerName: userNames[s.trainerId] ?? 'بدون مدرب',
            hallName: hallNames[s.hallId] ?? 'قاعة',
            scheduleText: scheduleTextFor(s),
          ))
      .toList();
});
