import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_pro/presentation/shared/schedule/screens/daily_schedule_screen.dart';
import 'package:gym_pro/presentation/shared/schedule/schedule_data_provider.dart';
import 'package:gym_pro/presentation/shared/auth/controllers/auth_controller.dart';
import 'package:gym_pro/core/constants/enums.dart';
import 'package:gym_pro/core/auth/role_guard.dart';
import 'package:gym_pro/core/auth/session_role.dart';
import 'package:gym_pro/core/auth/auth_refresh.dart';
import 'package:gym_pro/core/network/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}
class _MockGoRouter extends Mock implements GoRouter {}

void main() {
  group('DailyScheduleScreen', () {
    late _MockSupabaseClient mockSupabase;
    late _MockGoRouter mockRouter;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      registerFallbackValue(UserRole.trainee);
      registerFallbackValue(AppEntry.reception);
    });

    setUp(() {
      mockSupabase = _MockSupabaseClient();
      mockRouter = _MockGoRouter();
      when(() => mockRouter.push(any())).thenAnswer((_) async => null);
      when(() => mockRouter.go(any())).thenAnswer((_) async => null);
      when(() => mockRouter.pop(any())).thenAnswer((_) => null);
    });

    Widget createTestWidget({
      UserRole role = UserRole.admin,
    }) {
      return ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockSupabase),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/schedule',
                builder: (context, state) {
                  final extra = state.extra;
                  if (extra is Map && extra['selectionMode'] == true) {
                    return const DailyScheduleScreen();
                  }
                  return const DailyScheduleScreen();
                },
              ),
            ],
            initialLocation: '/schedule',
          ),
        ),
      );
    }

    testWidgets('renders app bar with correct title for admin', (tester) async {
      await tester.pumpWidget(createTestWidget(role: UserRole.admin));
      await tester.pumpAndSettle();

      expect(find.text('الجدول'), findsOneWidget);
      expect(find.byIcon(Icons.view_week), findsOneWidget);
      expect(find.byIcon(Icons.checklist), findsOneWidget); // multi-select for admin
    });

    testWidgets('renders app bar with correct title for reception', (tester) async {
      await tester.pumpWidget(createTestWidget(role: UserRole.reception));
      await tester.pumpAndSettle();

      expect(find.text('الجدول'), findsOneWidget);
      expect(find.byIcon(Icons.view_week), findsOneWidget);
      expect(find.byIcon(Icons.checklist), findsNothing);
    });

    testWidgets('toggles weekly/daily view when icon tapped', (tester) async {
      await tester.pumpWidget(createTestWidget(role: UserRole.admin));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.view_week), findsOneWidget);

      await tester.tap(find.byIcon(Icons.view_week));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.view_day), findsOneWidget);
    });

    testWidgets('shows day selector with 7 days', (tester) async {
      await tester.pumpWidget(createTestWidget(role: UserRole.admin));
      await tester.pumpAndSettle();

      final dayChips = find.byType(ChoiceChip);
      expect(dayChips, findsAtLeastNWidgets(7));
    });

    testWidgets('shows loading indicator while data loads', (tester) async {
      await tester.pumpWidget(createTestWidget(role: UserRole.admin));
      
      expect(find.text('جاري تحميل الجدول...'), findsOneWidget);
    });

    testWidgets('refresh button triggers data reload', (tester) async {
      await tester.pumpWidget(createTestWidget(role: UserRole.admin));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(find.text('جاري تحميل الجدول...'), findsOneWidget);
    });
  });
}