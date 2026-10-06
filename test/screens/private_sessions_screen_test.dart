import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_pro/presentation/reception/bookings/screens/private_sessions_screen.dart';
import 'package:gym_pro/presentation/trainer/schedule/screens/my_schedule_screen.dart';
import 'package:gym_pro/presentation/trainee/private_sessions/screens/private_sessions_screen.dart';
import 'package:gym_pro/core/constants/enums.dart';
import 'package:gym_pro/core/auth/role_guard.dart';
import 'package:gym_pro/core/network/supabase_client.dart';
import 'package:gym_pro/presentation/shared/auth/controllers/auth_controller.dart';
import 'package:gym_pro/data/providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}
class _MockGoRouter extends Mock implements GoRouter {}

void main() {
  group('PrivateSessionsScreen (Reception)', () {
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

    Widget createReceptionTestWidget() {
      return ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockSupabase),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/reception/bookings/private',
                builder: (context, state) => const PrivateSessionsScreen(),
              ),
            ],
            initialLocation: '/reception/bookings/private',
          ),
        ),
      );
    }

    testWidgets('renders app bar with correct title', (tester) async {
      await tester.pumpWidget(createReceptionTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('الجلسات الخاصة'), findsOneWidget);
    });

    testWidgets('shows two tabs: individual and fixed schedule', (tester) async {
      await tester.pumpWidget(createReceptionTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('الجلسات الفردية'), findsOneWidget);
      expect(find.text('المواعيد الثابتة'), findsOneWidget);
    });

    testWidgets('shows FAB for scheduling session in individual tab', (tester) async {
      await tester.pumpWidget(createReceptionTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('جدولة جلسة'), findsOneWidget);
    });

    testWidgets('hides FAB in fixed schedule tab', (tester) async {
      await tester.pumpWidget(createReceptionTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('المواعيد الثابتة'));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('shows relation selector in fixed schedule tab', (tester) async {
      await tester.pumpWidget(createReceptionTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('المواعيد الثابتة'));
      await tester.pumpAndSettle();

      expect(find.text('اختر علاقة مدرب-متدرب'), findsOneWidget);
    });

    testWidgets('shows empty state when no sessions in individual tab', (tester) async {
      await tester.pumpWidget(createReceptionTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('لا توجد جلسات فردية'), findsOneWidget);
      expect(find.text('اضغط + في الشريط العلوي للإضافة'), findsOneWidget);
    });
  });

  group('MyScheduleScreen (Trainer)', () {
    late _MockSupabaseClient mockSupabase;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      registerFallbackValue(UserRole.trainer);
      registerFallbackValue(AppEntry.mobile);
    });

    setUp(() {
      mockSupabase = _MockSupabaseClient();
    });

    Widget createTrainerTestWidget() {
      return ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockSupabase),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/trainer/schedule',
                builder: (context, state) => const MyScheduleScreen(),
              ),
            ],
            initialLocation: '/trainer/schedule',
          ),
        ),
      );
    }

    testWidgets('renders app bar with correct title', (tester) async {
      await tester.pumpWidget(createTrainerTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('جدولي'), findsOneWidget);
    });

    testWidgets('shows three tabs: group, private, fixed', (tester) async {
      await tester.pumpWidget(createTrainerTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('الحصص الجماعية'), findsOneWidget);
      expect(find.text('جلساتي الخاصة'), findsOneWidget);
      expect(find.text('مواعيدي الثابتة'), findsOneWidget);
    });

    testWidgets('shows empty state when no group sessions', (tester) async {
      await tester.pumpWidget(createTrainerTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('لا توجد حصص جماعية مجدولة'), findsOneWidget);
    });

    testWidgets('shows empty state when no private sessions', (tester) async {
      await tester.pumpWidget(createTrainerTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('جلساتي الخاصة'));
      await tester.pumpAndSettle();

      expect(find.text('لا توجد جلسات خاصة مجدولة'), findsOneWidget);
    });

    testWidgets('shows empty state when no fixed schedule', (tester) async {
      await tester.pumpWidget(createTrainerTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('مواعيدي الثابتة'));
      await tester.pumpAndSettle();

      expect(find.text('لا توجد مواعيد ثابتة'), findsOneWidget);
    });
  });

  group('TraineePrivateSessionsScreen (Trainee)', () {
    late _MockSupabaseClient mockSupabase;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      registerFallbackValue(UserRole.trainee);
      registerFallbackValue(AppEntry.mobile);
    });

    setUp(() {
      mockSupabase = _MockSupabaseClient();
    });

    Widget createTraineeTestWidget() {
      return ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockSupabase),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/trainee/private-sessions',
                builder: (context, state) => const TraineePrivateSessionsScreen(),
              ),
            ],
            initialLocation: '/trainee/private-sessions',
          ),
        ),
      );
    }

    testWidgets('renders app bar with correct title', (tester) async {
      await tester.pumpWidget(createTraineeTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('جلساتي الخاصة'), findsOneWidget);
    });

    testWidgets('shows two tabs: scheduled and fixed', (tester) async {
      await tester.pumpWidget(createTraineeTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('الجلسات المجدولة'), findsOneWidget);
      expect(find.text('مواعيدي الثابتة'), findsOneWidget);
    });

    testWidgets('shows empty state when no scheduled sessions', (tester) async {
      await tester.pumpWidget(createTraineeTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('لا توجد جلسات خاصة مجدولة'), findsOneWidget);
    });

    testWidgets('shows empty state when no fixed schedule', (tester) async {
      await tester.pumpWidget(createTraineeTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('مواعيدي الثابتة'));
      await tester.pumpAndSettle();

      expect(find.text('لا توجد مواعيد ثابتة'), findsOneWidget);
    });
  });
}