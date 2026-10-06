import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/access_period.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/entities/hall.dart';
import '../../../data/providers.dart';
import '../auth/controllers/auth_controller.dart';

final scheduleDataProvider = FutureProvider((ref) async {
  // نبدأ كل الاستعلامات المستقلة فورًا (بدون await) قبل انتظار أي واحد منها،
  // فتُنفَّذ كلها بالتوازي على الشبكة بدل التسلسل. كانت هذه الاستعلامات
  // (sessions/users/halls/periods/sessionPeriods) تُنتظر واحدة تلو الأخرى
  // رغم عدم اعتماد أي منها على نتيجة الأخرى، فيتضاعف زمن تحميل شاشة الجدول
  // بلا داعٍ. الآن الزمن الكلي يقترب من زمن أبطأ استعلام واحد فقط.
  final sessionsFuture = ref.read(sessionRepositoryProvider).getSessions();
  final usersFuture = ref.read(userRepositoryProvider).getAllUsers();
  final hallsFuture = ref.read(hallRepositoryProvider).getHalls();
  // كانت فترات الوصول تُجلب قاعة قاعة (N طلب شبكة لكل N قاعة) داخل حلقة for.
  // استبدلناها باستدعاء واحد (getAllAccessPeriods) يجلب كل الفترات دفعة واحدة.
  final periodsFuture = ref.read(hallRepositoryProvider).getAllAccessPeriods();
  final sessionPeriodsFuture =
      ref.read(sessionRepositoryProvider).getAllSessionPeriods();
  final userId = ref.read(authControllerProvider).value?.id;
  final bookingsFuture = userId != null
      ? ref.read(bookingRepositoryProvider).getBookingsByTrainee(userId)
      : null;

  final sessionsRes = await sessionsFuture;
  final usersRes = await usersFuture;
  final hallsRes = await hallsFuture;
  final periodsRes = await periodsFuture;
  final sessionPeriodsRes = await sessionPeriodsFuture;

  final sessions = sessionsRes.getOrElse(() => []);
  final users = usersRes.getOrElse(() => []);
  final halls = hallsRes.getOrElse(() => []);
  final periods = periodsRes.getOrElse(() => <AccessPeriod>[]);
  final sessionPeriods = sessionPeriodsRes.getOrElse(() => {});

  Set<int> myBookingSessionIds = {};
  if (bookingsFuture != null) {
    final bookingsRes = await bookingsFuture;
    bookingsRes.fold((_) {}, (bookings) {
      myBookingSessionIds = bookings
          .where((b) => b.status.name == 'confirmed')
          .map((b) => b.sessionId)
          .toSet();
    });
  }

  final userMap = {for (final u in users) u.id: u.name};
  final hallMap = {for (final h in halls) h.id: h.name};

  return ScheduleData(
    sessions: sessions,
    periods: periods,
    halls: halls,
    userMap: userMap,
    hallMap: hallMap,
    sessionPeriods: sessionPeriods,
    myBookingSessionIds: myBookingSessionIds,
  );
});

class ScheduleData {
  final List<Session> sessions;
  final List<AccessPeriod> periods;
  final List<Hall> halls;
  final Map<String, String> userMap;
  final Map<int, String> hallMap;
  final Map<int, Set<int>> sessionPeriods;
  final Set<int> myBookingSessionIds;
  const ScheduleData({
    required this.sessions,
    required this.periods,
    required this.halls,
    required this.userMap,
    required this.hallMap,
    required this.sessionPeriods,
    this.myBookingSessionIds = const {},
  });
}
