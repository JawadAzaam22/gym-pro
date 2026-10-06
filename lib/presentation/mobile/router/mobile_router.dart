import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_pro/presentation/shared/auth/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/auth/auth_refresh.dart';
import '../../../core/auth/role_guard.dart';
import '../../../core/auth/session_role.dart';
import '../../../domain/entities/training_program.dart';
import '../../../domain/entities/diet.dart';
import '../../../core/constants/app_colors.dart';
import '../../trainer/dashboard/screens/trainer_dashboard_screen.dart';
import '../../trainer/trainees/screens/trainees_list_screen.dart';
import '../../trainer/trainees/screens/trainee_detail_screen.dart';
import '../../trainer/program_builder/screens/create_program_screen.dart';
import '../../trainer/program_builder/screens/program_days_screen.dart';
import '../../trainer/program_builder/screens/exercises_screen.dart';
import '../../trainer/diet_builder/screens/create_diet_screen.dart';
import '../../trainer/diet_builder/screens/diet_days_screen.dart';
import '../../trainer/diet_builder/screens/meals_screen.dart';
import '../../trainer/attendance/screens/trainees_attendance_screen.dart';
import '../../shared/schedule/screens/daily_schedule_screen.dart';
import '../../trainer/schedule/screens/my_schedule_screen.dart';import '../../trainee/dashboard/screens/trainee_dashboard_screen.dart';
import '../../trainee/qr_code/screens/my_qr_screen.dart';
import '../../trainee/bookings/screens/my_bookings_screen.dart';
import '../../trainee/bookings/screens/group_sessions_screen.dart';
import '../../trainee/membership/screens/my_membership_screen.dart';
import '../../trainee/my_program/screens/my_program_screen.dart';
import '../../trainee/my_diet/screens/my_diet_screen.dart';
import '../../trainee/my_trainer/screens/my_trainer_screen.dart';
import '../../trainee/attendance/screens/my_attendance_screen.dart';
import '../../trainee/private_sessions/screens/private_sessions_screen.dart';
import '../../shared/settings/screens/settings_screen.dart';
import '../../shared/notifications/screens/notifications_screen.dart';

import '../../shared/auth/controllers/auth_controller.dart';

class MobileShellScreen extends ConsumerStatefulWidget {
  const MobileShellScreen({super.key});

  @override
  ConsumerState<MobileShellScreen> createState() => _MobileShellScreenState();
}

class _MobileShellScreenState extends ConsumerState<MobileShellScreen> {
  int _currentIndex = 0;
  String? _lastRole;

  List<Widget> _buildTrainerPages() => [
        const TrainerDashboardScreen(),
        const TraineesListScreen(),
        // "جدولي": حصصه الجماعية + مواعيده الثابتة + فترات مناوبته في
        // القاعات، كلها مُجمّعة ومنسّقة خصيصًا لهذا المدرب (3 تبويبات
        // داخلية). "الجدول" أدناه هو الجدول العام المشترك لكل القاعات،
        // أُعيد كتبويبة منفصلة في الأسفل كما طُلب.
        const MyScheduleScreen(),
        const DailyScheduleScreen(),
        const SettingsScreen(role: 'trainer'),
      ];

  List<Widget> _buildTraineePages() => [
        const TraineeDashboardScreen(),
        const DailyScheduleScreen(),
        const MyBookingsScreen(),
        const TraineePrivateSessionsScreen(),
        const SettingsScreen(role: 'trainee'),
      ];

  List<BottomNavigationBarItem> _trainerItems() => const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
        BottomNavigationBarItem(icon: Icon(Icons.group), label: 'المتدربون'),
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month), label: 'جدولي'),
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_view_week), label: 'الجدول'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
      ];

  List<BottomNavigationBarItem> _traineeItems() => const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month), label: 'الجدول'),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'حجوزاتي'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_pin), label: 'مواعيدي الثابتة'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
      ];

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authControllerProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('خطأ'))),
      data: (user) {
        final role = user?.role.name;
        if (role != _lastRole) {
          _lastRole = role;
          _currentIndex = 0;
        }
        final isTrainer = role == 'trainer';
        final pages = isTrainer ? _buildTrainerPages() : _buildTraineePages();
        final items = isTrainer ? _trainerItems() : _traineeItems();

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex.clamp(0, pages.length - 1),
            children: pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex.clamp(0, items.length - 1),
            onTap: (index) {
              if (index != _currentIndex) {
                setState(() => _currentIndex = index);
              }
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textMuted,
            items: items,
          ),
        );
      },
    );
  }
}

GoRouter createMobileRouter() {
  return GoRouter(
    initialLocation: '/mobile',
    refreshListenable: AuthRefreshListenable(),
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('الصفحة غير موجودة')),
      body: Center(child: Text('المسار غير متاح: ${state.uri.path}')),
    ),
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;
      final atLogin = state.matchedLocation == '/';
      if (session == null) return atLogin ? null : '/';
      // كان هذا الراوتر يستعلم عن role فقط ولا يتحقق من is_active إطلاقًا،
      // فكان المستخدم الموقوف (Ban) يبقى قادرًا على استخدام تطبيق الموبايل
      // بالكامل رغم إيقافه من لوحة الأدمن. نستخدم الآن نفس آلية admin/
      // reception (SessionRoleCache) التي تتحقق من is_active وتُخرج
      // المستخدم فورًا إذا أُوقف، مع الاستفادة من نفس الكاش لتفادي تكرار
      // الاستعلام على كل تنقل.
      final info = await SessionRoleCache.resolve();
      final role = info.role;
      if (info.isActive == false ||
          (role != null && role != 'trainer' && role != 'trainee')) {
        try {
          await Supabase.instance.client.auth.signOut();
        } catch (_) {}
        SessionRoleCache.invalidate();
        return atLogin ? null : '/';
      }
      if (atLogin) return '/mobile';

      final path = state.uri.path;
      final trainerPath = path.startsWith('/trainer/');
      final traineePath = path.startsWith('/trainee/');
      if (trainerPath && role != 'trainer') return '/mobile';
      if (traineePath && role != 'trainee') return '/mobile';
      return null;
    },
    routes: [
      GoRoute(
          path: '/',
          builder: (c, s) => const LoginScreen(entry: AppEntry.mobile)),
      GoRoute(path: '/mobile', builder: (c, s) => const MobileShellScreen()),
      GoRoute(
        path: '/mobile/settings',
        builder: (c, s) =>
            SettingsScreen(role: s.uri.queryParameters['role'] ?? 'trainee'),
      ),
      GoRoute(
          path: '/mobile/notifications',
          builder: (c, s) => const NotificationsScreen()),
      GoRoute(
          path: '/trainer/dashboard',
          builder: (c, s) => const TrainerDashboardScreen()),
      GoRoute(
          path: '/trainer/trainees',
          builder: (c, s) => const TraineesListScreen()),
      GoRoute(
          path: '/trainer/trainees/:id',
          builder: (c, s) =>
              TraineeDetailScreen(traineeId: s.pathParameters['id'] ?? '')),
      GoRoute(
          path: '/trainer/programs/new',
          builder: (c, s) {
            final extra = s.extra;
            TrainingProgram? program;
            String? initialTraineeId;
            if (extra is TrainingProgram) {
              program = extra;
            } else if (extra is Map) {
              program = extra['program'] is TrainingProgram
                  ? extra['program'] as TrainingProgram
                  : null;
              initialTraineeId = extra['initialTraineeId'] as String?;
            }
            return CreateProgramScreen(
                program: program, initialTraineeId: initialTraineeId);
          }),
      GoRoute(
          path: '/trainer/programs/:id/days',
          builder: (c, s) {
            final program = s.extra;
            final id = int.tryParse(s.pathParameters['id'] ?? '0') ?? 0;
            return ProgramDaysScreen(
                programId: id,
                program: program is TrainingProgram ? program : null);
          }),
      GoRoute(
          path: '/trainer/diets/new',
          builder: (c, s) {
            final extra = s.extra;
            Diet? diet;
            String? initialTraineeId;
            if (extra is Diet) {
              diet = extra;
            } else if (extra is Map) {
              diet = extra['diet'] is Diet ? extra['diet'] as Diet : null;
              initialTraineeId = extra['initialTraineeId'] as String?;
            }
            return CreateDietScreen(
                diet: diet, initialTraineeId: initialTraineeId);
          }),
      GoRoute(
          path: '/trainer/diets/:id/days',
          builder: (c, s) {
            final diet = s.extra;
            final id = int.tryParse(s.pathParameters['id'] ?? '0') ?? 0;
            return DietDaysScreen(dietId: id, diet: diet is Diet ? diet : null);
          }),
      GoRoute(
          path: '/trainer/programs/days/:dayId/exercises',
          builder: (c, s) {
            final dayId = int.tryParse(s.pathParameters['dayId'] ?? '0') ?? 0;
            return ExercisesScreen(dayId: dayId);
          }),
      GoRoute(
          path: '/trainer/programs/:programId/days/:dayId/exercises',
          builder: (c, s) {
            final dayId = int.tryParse(s.pathParameters['dayId'] ?? '0') ?? 0;
            return ExercisesScreen(dayId: dayId);
          }),
      GoRoute(
          path: '/trainer/diets/days/:dayId/meals',
          builder: (c, s) {
            final dayId = int.tryParse(s.pathParameters['dayId'] ?? '0') ?? 0;
            return MealsScreen(dayId: dayId);
          }),
      GoRoute(
          path: '/trainer/diets/:dietId/days/:dayId/meals',
          builder: (c, s) {
            final dayId = int.tryParse(s.pathParameters['dayId'] ?? '0') ?? 0;
            return MealsScreen(dayId: dayId);
          }),
      GoRoute(
          path: '/trainer/attendance',
          builder: (c, s) => const TraineesAttendanceScreen()),
      GoRoute(
          path: '/trainer/schedule',
          builder: (c, s) => const MyScheduleScreen()),
      GoRoute(
          path: '/trainer/all-schedule',
          builder: (c, s) => const DailyScheduleScreen()),
      GoRoute(
          path: '/trainee/dashboard',
          builder: (c, s) => const TraineeDashboardScreen()),
      GoRoute(path: '/trainee/qr', builder: (c, s) => const MyQrScreen()),
      GoRoute(
          path: '/trainee/bookings',
          builder: (c, s) => const MyBookingsScreen()),
      GoRoute(
          path: '/trainee/bookings/group',
          builder: (c, s) => const GroupSessionsScreen()),
      GoRoute(
          path: '/trainee/membership',
          builder: (c, s) => const MyMembershipScreen()),
      GoRoute(
          path: '/trainee/schedule',
          builder: (c, s) => const DailyScheduleScreen()),
      GoRoute(
          path: '/trainee/program', builder: (c, s) => const MyProgramScreen()),
      GoRoute(path: '/trainee/diet', builder: (c, s) => const MyDietScreen()),
      GoRoute(
          path: '/trainee/trainer', builder: (c, s) => const MyTrainerScreen()),
      GoRoute(
          path: '/trainee/attendance',
          builder: (c, s) => const MyAttendanceScreen()),
      GoRoute(
          path: '/trainee/private-sessions',
          builder: (c, s) => const TraineePrivateSessionsScreen()),
    ],
  );
}

GoRouter? _mobileRouterInstance;
GoRouter get mobileRouter => _mobileRouterInstance ??= createMobileRouter();
