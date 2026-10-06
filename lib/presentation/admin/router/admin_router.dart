import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/auth/auth_refresh.dart';
import '../../../core/auth/role_guard.dart';
import '../../../core/auth/session_role.dart';
import '../../../domain/entities/user.dart' as app_user;
import '../../../domain/entities/session.dart' as app_session;
import '../dashboard/screens/admin_dashboard_screen.dart';
import '../users/screens/users_list_screen.dart';
import '../users/screens/user_form_screen.dart';
import '../halls/screens/halls_list_screen.dart';
import '../halls/screens/access_periods_screen.dart';
import '../sessions/screens/sessions_list_screen.dart';
import '../sessions/screens/session_form_screen.dart';
import '../finance/screens/reports_screen.dart';
import '../../shared/schedule/screens/daily_schedule_screen.dart';
import '../../shared/auth/screens/login_screen.dart';
import '../../shared/notifications/screens/notifications_screen.dart';
import 'admin_shell_screen.dart';

/// يُبنى بعد bootstrap حصرًا (Supabase يجب أن يكون مهيأً).
GoRouter createAdminRouter() {
  return GoRouter(
    initialLocation: '/admin/dashboard',
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
          (info.role != null && info.role != 'admin')) {
        try {
          await Supabase.instance.client.auth.signOut();
        } catch (_) {}
        SessionRoleCache.invalidate();
        return atLogin ? null : '/';
      }
      if (atLogin) return '/admin/dashboard';
      return null;
    },
    routes: [
      GoRoute(
          path: '/',
          builder: (c, s) => const LoginScreen(entry: AppEntry.admin)),
      GoRoute(
          path: '/admin/notifications',
          builder: (c, s) => const NotificationsScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/dashboard',
                builder: (c, s) => const AdminDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/users',
                builder: (c, s) => const UsersListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (c, s) => const UserFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (c, s) {
                      final extra = s.extra;
                      return UserFormScreen(
                        userId: s.pathParameters['id'],
                        user: extra is app_user.User ? extra : null,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/halls',
                builder: (c, s) => const HallsListScreen(),
                routes: [
                  GoRoute(
                    path: ':id/periods',
                    builder: (c, s) {
                      final id =
                          int.tryParse(s.pathParameters['id'] ?? '1') ?? 1;
                      final hall = s.extra;
                      final hallName =
                          hall != null ? (hall as dynamic).name as String? : null;
                      return AccessPeriodsScreen(
                          hallId: id, hallName: hallName);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/sessions',
                builder: (c, s) => const SessionsListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (c, s) {
                      final session = s.extra;
                      return SessionFormScreen(
                          session:
                              session is app_session.Session ? session : null);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/finance/reports',
                builder: (c, s) => const ReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/schedule',
                builder: (c, s) => const DailyScheduleScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// للتوافق الخلفي — يُبنى lazily عند أول استخدام (بعد bootstrap حتمًا).
GoRouter? _adminRouterInstance;
GoRouter get adminRouter => _adminRouterInstance ??= createAdminRouter();
