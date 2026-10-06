import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/auth/auth_refresh.dart';
import '../../../core/auth/role_guard.dart';
import '../../../core/auth/session_role.dart';
import '../../../core/constants/enums.dart';
import '../../admin/users/screens/user_form_screen.dart';
import '../dashboard/screens/reception_dashboard_screen.dart';
import '../checkin/screens/checkin_screen.dart';
import '../checkin/screens/qr_scan_screen.dart';
import '../memberships/screens/membership_screen.dart';
import '../bookings/screens/group_bookings_screen.dart';
import '../bookings/screens/private_sessions_screen.dart';
import '../assignment/screens/trainer_assignment_screen.dart';
import '../payments/screens/record_payment_screen.dart';
import '../../shared/schedule/screens/daily_schedule_screen.dart';
import '../../shared/auth/screens/login_screen.dart';
import '../../shared/notifications/screens/notifications_screen.dart';
import 'reception_shell_screen.dart';

GoRouter createReceptionRouter() {
  return GoRouter(
    initialLocation: '/reception/dashboard',
    refreshListenable: AuthRefreshListenable(),
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('الصفحة غير موجودة')),
      body: Center(child: Text('المسار غير متاح: ${state.uri.path}')),
    ),
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;
      final atLogin = state.matchedLocation == '/';
      if (session == null) return atLogin ? null : '/';
      final info = await SessionRoleCache.resolve();
      if (info.isActive == false ||
          (info.role != null && info.role != 'reception')) {
        try {
          await Supabase.instance.client.auth.signOut();
        } catch (_) {}
        SessionRoleCache.invalidate();
        return atLogin ? null : '/';
      }
      if (atLogin) return '/reception/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (c, s) => const LoginScreen(entry: AppEntry.reception),
      ),
      GoRoute(
        path: '/reception/notifications',
        builder: (c, s) => const NotificationsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ReceptionShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reception/dashboard',
                builder: (c, s) => const ReceptionDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reception/checkin',
                builder: (c, s) => const CheckinScreen(),
                routes: [
                  GoRoute(
                    path: 'qr',
                    builder: (c, s) => const QrScanScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reception/memberships',
                builder: (c, s) => const MembershipScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reception/bookings/group',
                builder: (c, s) => const GroupBookingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reception/bookings/private',
                builder: (c, s) => const PrivateSessionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reception/trainer-assignment',
                builder: (c, s) => const TrainerAssignmentScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reception/payments/record',
                builder: (c, s) => const RecordPaymentScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reception/schedule',
                builder: (c, s) => const DailyScheduleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                // إنشاء متدرب من الاستقبال — الدور مقفل على trainee داخل الشاشة.
                path: '/reception/trainees/new',
                builder: (c, s) => const UserFormScreen(
                    lockedRole: UserRole.trainee),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

GoRouter? _receptionRouterInstance;
GoRouter get receptionRouter =>
    _receptionRouterInstance ??= createReceptionRouter();
