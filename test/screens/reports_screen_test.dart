import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_pro/presentation/admin/finance/screens/reports_screen.dart';
import 'package:gym_pro/presentation/admin/finance/controllers/finance_controller.dart';
import 'package:gym_pro/core/constants/enums.dart';
import 'package:gym_pro/core/auth/role_guard.dart';
import 'package:gym_pro/core/network/supabase_client.dart';
import 'package:gym_pro/data/providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}
class _MockGoRouter extends Mock implements GoRouter {}

void main() {
  group('ReportsScreen (Admin)', () {
    late _MockSupabaseClient mockSupabase;
    late _MockGoRouter mockRouter;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      registerFallbackValue(UserRole.admin);
      registerFallbackValue(AppEntry.admin);
    });

    setUp(() {
      mockSupabase = _MockSupabaseClient();
      mockRouter = _MockGoRouter();
      when(() => mockRouter.push(any())).thenAnswer((_) async => null);
      when(() => mockRouter.go(any())).thenAnswer((_) async => null);
      when(() => mockRouter.pop(any())).thenAnswer((_) => null);
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockSupabase),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/admin/finance/reports',
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
            initialLocation: '/admin/finance/reports',
          ),
        ),
      );
    }

    testWidgets('renders app bar with correct title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('التقارير'), findsOneWidget);
    });

    testWidgets('shows report type dropdown', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('نوع التقرير'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('shows date preset chips', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('أسبوعي'), findsOneWidget);
      expect(find.text('شهري'), findsOneWidget);
      expect(find.text('3 أشهر'), findsOneWidget);
      expect(find.text('مخصص'), findsOneWidget);
    });

    testWidgets('shows generate report button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('توليد التقرير'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });

    testWidgets('shows previous reports section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('التقارير السابقة'), findsOneWidget);
    });

    testWidgets('date preset selection updates date range', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('أسبوعي'));
      await tester.pumpAndSettle();

      expect(find.textContaining('من:'), findsOneWidget);
      expect(find.textContaining('إلى:'), findsOneWidget);
    });
  });
}