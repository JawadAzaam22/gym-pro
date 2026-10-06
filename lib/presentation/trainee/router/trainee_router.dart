/// LEGACY — ملف ميت: غير مستورد في أي مكان.
/// النسخة الحيّة هي `lib/presentation/mobile/router/mobile_router.dart`
/// (تتضمن مثلاً مسار `/trainee/bookings/group` الناقص هنا).
/// أُبقي لأغراض المرجع فقط — يُحذف بقرار صاحب المشروع.
library;
import 'package:go_router/go_router.dart';
import '../../../core/auth/role_guard.dart';
import '../dashboard/screens/trainee_dashboard_screen.dart';
import '../qr_code/screens/my_qr_screen.dart';
import '../bookings/screens/my_bookings_screen.dart';
import '../my_program/screens/my_program_screen.dart';
import '../my_diet/screens/my_diet_screen.dart';
import '../my_trainer/screens/my_trainer_screen.dart';
import '../attendance/screens/my_attendance_screen.dart';
import '../../shared/schedule/screens/daily_schedule_screen.dart';
import '../../shared/auth/screens/login_screen.dart';

final traineeRouter = GoRouter(
  initialLocation: '/trainee/dashboard',
  routes: [
    GoRoute(path: '/', builder: (c, s) => const LoginScreen(entry: AppEntry.mobile)),
    GoRoute(path: '/trainee/dashboard', builder: (c, s) => const TraineeDashboardScreen()),
    GoRoute(path: '/trainee/qr', builder: (c, s) => const MyQrScreen()),
    GoRoute(path: '/trainee/bookings', builder: (c, s) => const MyBookingsScreen()),
    GoRoute(path: '/trainee/program', builder: (c, s) => const MyProgramScreen()),
    GoRoute(path: '/trainee/diet', builder: (c, s) => const MyDietScreen()),
    GoRoute(path: '/trainee/trainer', builder: (c, s) => const MyTrainerScreen()),
    GoRoute(path: '/trainee/attendance', builder: (c, s) => const MyAttendanceScreen()),
    GoRoute(path: '/trainee/schedule', builder: (c, s) => const DailyScheduleScreen()),
  ],
);
