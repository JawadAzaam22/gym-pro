/// LEGACY — ملف ميت: غير مستورد في أي مكان.
/// النسخة الحيّة لجهة المدرب/المتدرب هي `lib/presentation/mobile/router/mobile_router.dart`
/// (تتضمن مسارات التمارين/الوجبات و`initialTraineeId` وغيرها).
/// أُبقي لأغراض المرجع فقط — يُحذف بقرار صاحب المشروع.
library;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/role_guard.dart';
import '../../../domain/entities/training_program.dart';
import '../../../domain/entities/diet.dart';
import '../dashboard/screens/trainer_dashboard_screen.dart';
import '../trainees/screens/trainees_list_screen.dart';
import '../trainees/screens/trainee_detail_screen.dart';
import '../program_builder/screens/create_program_screen.dart';
import '../program_builder/screens/program_days_screen.dart';
import '../diet_builder/screens/create_diet_screen.dart';
import '../diet_builder/screens/diet_days_screen.dart';
import '../attendance/screens/trainees_attendance_screen.dart';
import '../schedule/screens/my_schedule_screen.dart';
import '../../shared/schedule/screens/daily_schedule_screen.dart';
import '../../shared/auth/screens/login_screen.dart';

final trainerRouter = GoRouter(
  initialLocation: '/trainer/dashboard',
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('الصفحة غير موجودة')),
    body: Center(child: Text('المسار غير متاح: ${state.uri.path}')),
  ),
  routes: [
    GoRoute(
        path: '/',
        builder: (c, s) => const LoginScreen(entry: AppEntry.mobile)),
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
          final program = s.extra;
          return CreateProgramScreen(
              program: program is TrainingProgram ? program : null);
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
          final diet = s.extra;
          return CreateDietScreen(diet: diet);
        }),
    GoRoute(
        path: '/trainer/diets/:id/days',
        builder: (c, s) {
          final diet = s.extra;
          final id = int.tryParse(s.pathParameters['id'] ?? '0') ?? 0;
          return DietDaysScreen(dietId: id, diet: diet is Diet ? diet : null);
        }),
    GoRoute(
        path: '/trainer/schedule', builder: (c, s) => const MyScheduleScreen()),
    GoRoute(
        path: '/trainer/attendance',
        builder: (c, s) => const TraineesAttendanceScreen()),
    GoRoute(
        path: '/trainer/all-schedule',
        builder: (c, s) => const DailyScheduleScreen()),
  ],
);
