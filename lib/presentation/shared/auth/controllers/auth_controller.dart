import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/user.dart';
import '../../../../core/auth/role_guard.dart';
import '../../../../core/auth/session_role.dart';
import '../../../admin/users/controllers/users_controller.dart';
import '../../../trainee/my_program/controllers/my_program_controller.dart';
import '../../../trainee/my_diet/controllers/my_diet_controller.dart';
import '../../../trainee/membership/controllers/my_membership_controller.dart';
import '../../../trainee/bookings/controllers/my_bookings_controller.dart';
import '../../../trainee/dashboard/controllers/trainee_dashboard_controller.dart';
import '../../../trainee/attendance/screens/my_attendance_screen.dart';
import '../../../trainee/private_sessions/controllers/private_sessions_controller.dart';
import '../../../trainee/my_trainer/controllers/my_trainer_controller.dart';
import '../../../trainee/qr_code/controllers/qr_controller.dart';
import '../../../trainer/trainees/controllers/trainees_controller.dart';
import '../../../trainer/dashboard/controllers/trainer_dashboard_controller.dart';
import '../../../trainer/schedule/controllers/schedule_controller.dart';
import '../../../reception/dashboard/controllers/reception_dashboard_controller.dart';
import '../../../admin/finance/controllers/finance_controller.dart';
import '../../../reception/bookings/controllers/bookings_controller.dart';

class AuthController extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final repo = ref.read(authRepositoryProvider);
    final res = await repo.getCurrentUser();
    return res.fold((l) => null, (r) => r);
  }

  void _invalidateAllUserDependentProviders() {
    // Trainee-specific providers
    ref.invalidate(myProgramProvider);
    ref.invalidate(myDietProvider);
    ref.invalidate(myMembershipProvider);
    ref.invalidate(myBookingsProvider);
    ref.invalidate(traineeDashboardProvider);
    ref.invalidate(myAttendanceProvider);
    ref.invalidate(traineePrivateSessionsProvider);
    ref.invalidate(myTrainerProvider);
    ref.invalidate(traineeQrProvider);
    ref.invalidate(qrRefreshProvider);

    // Trainer-specific providers
    ref.invalidate(traineesControllerProvider);
    ref.invalidate(traineeDetailProvider);
    ref.invalidate(trainerDashboardProvider);
    ref.invalidate(trainerFixedScheduleProvider);
    ref.invalidate(trainerSessionsProvider);

    // Admin/Reception providers (data could leak across sessions)
    ref.invalidate(usersControllerProvider);
    ref.invalidate(userSearchQueryProvider);
    ref.invalidate(userRoleFilterProvider);
    ref.invalidate(filteredUsersProvider);
    ref.invalidate(userByIdProvider);
    ref.invalidate(receptionStatsProvider);
    ref.invalidate(recentCheckinsProvider);
    ref.invalidate(paymentsProvider);
    ref.invalidate(financeSummaryProvider);
    ref.invalidate(reportsProvider);
    ref.invalidate(attendanceSummaryProvider);
    ref.invalidate(weeklyAttendanceProvider);
    ref.invalidate(privateSessionsProvider);
    ref.invalidate(sessionBookingCountsProvider);
  }

  Future<bool> login(String email, String password, {required AppEntry entry}) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.login(email, password);
    return await result.fold(
      (failure) async {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (user) async {
        if (!RoleGuard.isAllowed(user.role, entry)) {
          // مهم: signInWithPassword نجح وأنشأ جلسة Supabase — يجب إبطالها
          // وإلا بقيت الجلسة نشطة وسيُعتبر المستخدم مسجلًا عند إعادة التشغيل
          try {
            await repo.logout();
          } catch (_) {}
          final msg = RoleGuard.errorMessage(user.role, entry);
          state = AsyncValue.error(msg, StackTrace.current);
          // لا نحفظ المستخدم إذا دوره غير مسموح
          return false;
        }
        // حماية إضافية: إبطال كل providers المعتمدة على المستخدم السابق
        // قبل تعيين المستخدم الجديد — يمنع تسريب البيانات حتى لو فشل logout
        _invalidateAllUserDependentProviders();
        state = AsyncValue.data(user);
        return true;
      },
    );
  }

  /// تسجيل دخول بدون فصل (للتوافق)
  Future<bool> loginSimple(String email, String password) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.login(email, password);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (user) {
        // نفس الحماية: إبطال providers المعتمدة على المستخدم السابق
        _invalidateAllUserDependentProviders();
        state = AsyncValue.data(user);
        return true;
      },
    );
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    SessionRoleCache.invalidate();
    // تنظيف شامل لكل الحالة المرتبطة بالمستخدم/الدور
    _invalidateAllUserDependentProviders();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(AuthController.new);

final currentUserRoleProvider = Provider((ref) {
  final user = ref.watch(authControllerProvider).value;
  return user?.role;
});
