import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_pro/core/constants/enums.dart';
import 'package:gym_pro/data/providers.dart';
import 'package:gym_pro/domain/entities/notification_item.dart';
import 'package:gym_pro/domain/repositories/i_notification_repository.dart';
import 'package:gym_pro/presentation/shared/widgets/notification_bell.dart';

class _MockNotificationRepo extends Mock implements INotificationRepository {}

void main() {
  late _MockNotificationRepo repo;

  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  setUp(() {
    repo = _MockNotificationRepo();
  });

  List<AppNotification> items(int unreadCount) => List.generate(
        unreadCount,
        (i) => AppNotification(
          id: i + 1,
          userId: 'u-1',
          title: 'إشعار ${i + 1}',
          type: i.isEven
              ? NotificationType.membershipExpiry
              : NotificationType.system,
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

  Future<void> pumpBell(WidgetTester tester, List<AppNotification> data) async {
    when(() => repo.watchMyNotifications())
        .thenAnswer((_) => Stream.value(data));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => Scaffold(
                  appBar: AppBar(
                    actions: const [NotificationBell(route: '/inbox')],
                    title: const Text('الرئيسية'),
                  ),
                  body: const Text('home'),
                ),
              ),
              GoRoute(
                path: '/inbox',
                builder: (context, state) => const Text('inbox-screen'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('NotificationBell - الشارة', () {
    testWidgets('يعرض شارةً بالعدد غير المقروء', (tester) async {
      await pumpBell(tester, items(3));

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byTooltip('الإشعارات (3 غير مقروء)'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('بدون إشعارات: بلا شارة ورسمة بلا تلميح عدّاد', (tester) async {
      await pumpBell(tester, const []);

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byTooltip('الإشعارات'), findsOneWidget);
      expect(find.byTooltip('الإشعارات (0 غير مقروء)'), findsNothing);
    });

    testWidgets('كل الإشعارات مقروءة يعني صفر على الشارة', (tester) async {
      await pumpBell(tester, [
        AppNotification(
          id: 1,
          userId: 'u-1',
          title: 'مقروء',
          type: NotificationType.booking,
          isRead: true,
          createdAt: DateTime.now(),
        ),
      ]);

      expect(find.byTooltip('الإشعارات'), findsOneWidget);
      expect(find.byTooltip('الإشعارات (1 غير مقروء)'), findsNothing);
    });

    testWidgets('أكتر من 99 يُعرض 99+', (tester) async {
      await pumpBell(tester, items(120));

      expect(find.text('99+'), findsOneWidget);
      expect(find.byTooltip('الإشعارات (120 غير مقروء)'), findsOneWidget);
    });

    testWidgets('فشل البث لا يُسقط الشريط العلوي والشارة تبقى 0',
        (tester) async {
      when(() => repo.watchMyNotifications())
          .thenThrow(Exception('realtime down'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => Scaffold(
                    appBar: AppBar(
                      actions: const [NotificationBell(route: '/inbox')],
                    ),
                    body: const Text('home'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('home'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byTooltip('الإشعارات'), findsOneWidget);
    });
  });

  group('NotificationBell - التنقل', () {
    testWidgets('الضغط على الجرس يفتح شاشة الإشعارات', (tester) async {
      await pumpBell(tester, items(2));

      expect(find.text('home'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(find.text('inbox-screen'), findsOneWidget);
      expect(find.text('home'), findsNothing);
    });
  });
}
