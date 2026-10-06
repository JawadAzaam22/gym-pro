import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_pro/core/constants/enums.dart';
import 'package:gym_pro/core/errors/failures.dart';
import 'package:gym_pro/data/providers.dart';
import 'package:gym_pro/domain/entities/notification_item.dart';
import 'package:gym_pro/domain/repositories/i_notification_repository.dart';
import 'package:gym_pro/presentation/shared/notifications/screens/notifications_screen.dart';

class _MockNotificationRepo extends Mock implements INotificationRepository {}

void main() {
  late _MockNotificationRepo repo;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    repo = _MockNotificationRepo();
    when(() => repo.watchMyNotifications())
        .thenAnswer((_) => Stream<List<AppNotification>>.value(const []));
  });

  AppNotification notif({
    int id = 1,
    String title = 'ينتهي اشتراكك قريباً',
    bool isRead = false,
    NotificationType type = NotificationType.membershipExpiry,
  }) =>
      AppNotification(
        id: id,
        userId: 'u-1',
        title: title,
        body: 'باقي يومان',
        type: type,
        entityId: 42,
        isRead: isRead,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

  Widget build(Widget child) => ProviderScope(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: Directionality(textDirection: TextDirection.rtl, child: child),
        ),
      );

  Future<void> pumpScreen(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(build(child));
    await tester.pumpAndSettle();
  }

  group('NotificationsScreen - البنية العامة', () {
    testWidgets('يعرض عنوان الشاشة وزر تعليم الكل كمقروء', (tester) async {
      await pumpScreen(tester, const NotificationsScreen());

      expect(find.text('الإشعارات'), findsOneWidget);
      expect(find.text('تعليم الكل كمقروء'), findsOneWidget);
    });

    testWidgets('يجلب إشعارات المستخدم مرة واحدة على الأقل', (tester) async {
      await pumpScreen(tester, const NotificationsScreen());

      verify(() => repo.watchMyNotifications()).called(1);
    });
  });

  group('NotificationsScreen - الحالات', () {
    testWidgets('قائمة فارغة تعرض رسالة "لا توجد إشعارات بعد"',
        (tester) async {
      await pumpScreen(tester, const NotificationsScreen());

      expect(find.text('لا توجد إشعارات بعد'), findsOneWidget);
      expect(find.text('تعليم الكل كمقروء'), findsOneWidget);
    });

    testWidgets('الإشعارات تعرض عناوينها ونصوصها', (tester) async {
      when(() => repo.watchMyNotifications()).thenAnswer(
        (_) => Stream.value([
          notif(id: 1, title: 'اشتراكك ينتهي قريباً'),
          notif(
              id: 2,
              title: 'تم تسجيل حضورك',
              type: NotificationType.attendance),
        ]),
      );

      await pumpScreen(tester, const NotificationsScreen());

      expect(find.text('اشتراكك ينتهي قريباً'), findsOneWidget);
      expect(find.text('تم تسجيل حضورك'), findsOneWidget);
      expect(find.text('باقي يومان'), findsNWidgets(2));
      expect(find.text('الإشعارات'), findsOneWidget);
    });

    testWidgets('فشل البث تعرض واجهة خطأ مع زر إعادة المحاولة',
        (tester) async {
      when(() => repo.watchMyNotifications())
          .thenThrow(Exception('connection lost'));

      await pumpScreen(tester, const NotificationsScreen());

      expect(tester.takeException(), isNull);
      expect(find.text('تعذّر تحميل الإشعارات'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('إعادة المحاولة'), findsOneWidget);
    });
  });

  group('NotificationsScreen - زر تعليم الكل كمقروء', () {
    testWidgets('معطّل عندما لا يوجد أي إشعار غير مقروء', (tester) async {
      when(() => repo.watchMyNotifications()).thenAnswer(
          (_) => Stream.value([notif(id: 1, isRead: true, title: 'قديم')]));

      await pumpScreen(tester, const NotificationsScreen());

      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'تعليم الكل كمقروء'),
      );
      expect(button.onPressed, isNull);
      expect(find.text('قديم'), findsOneWidget);
      verifyNever(() => repo.markAllAsRead());
    });

    testWidgets('فعّال عند وجود إشعار غير مقروء', (tester) async {
      when(() => repo.watchMyNotifications())
          .thenAnswer((_) => Stream.value([notif(id: 1, isRead: false)]));

      await pumpScreen(tester, const NotificationsScreen());

      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'تعليم الكل كمقروء'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('الضغط يستدعي markAllAsRead وينجح', (tester) async {
      when(() => repo.watchMyNotifications())
          .thenAnswer((_) => Stream.value([notif(id: 1, isRead: false)]));
      when(() => repo.markAllAsRead())
          .thenAnswer((_) async => const Right(null));

      await pumpScreen(tester, const NotificationsScreen());

      await tester.tap(find.widgetWithText(TextButton, 'تعليم الكل كمقروء'));
      await tester.pump();
      await tester.pumpAndSettle();

      verify(() => repo.markAllAsRead()).called(1);
      expect(find.text('تم تعليم كل الإشعارات كمقروءة'), findsOneWidget);
    });
  });

  group('NotificationsScreen - التفاعل مع إشعار واحد', () {
    testWidgets('الضغط على إشعار غير مقروء يستدعي markAsRead',
        (tester) async {
      when(() => repo.watchMyNotifications()).thenAnswer(
          (_) => Stream.value([notif(id: 9, isRead: false, title: 'عنوان 9')]));
      when(() => repo.markAsRead(9))
          .thenAnswer((_) async => const Right(null));

      await pumpScreen(tester, const NotificationsScreen());

      await tester.tap(find.text('عنوان 9'));
      await tester.pump();
      await tester.pumpAndSettle();

      verify(() => repo.markAsRead(9)).called(1);
    });

    testWidgets('الضغط على إشعار مقروء مسبقاً لا يستدعي الـ repo',
        (tester) async {
      when(() => repo.watchMyNotifications()).thenAnswer(
          (_) => Stream.value([notif(id: 3, isRead: true, title: 'مقروء 3')]));

      await pumpScreen(tester, const NotificationsScreen());

      await tester.tap(find.text('مقروء 3'));
      await tester.pump();
      await tester.pumpAndSettle();

      verifyNever(() => repo.markAsRead(3));
    });

    testWidgets('فشل markAllAsRead يعرض رسالة خطأ دون تعطيل الشاشة',
        (tester) async {
      when(() => repo.watchMyNotifications())
          .thenAnswer((_) => Stream.value([notif(id: 1, isRead: false)]));
      when(() => repo.markAllAsRead()).thenAnswer(
          (_) async => const Left<Failure, void>(ServerFailure('server down')));

      await pumpScreen(tester, const NotificationsScreen());

      await tester.tap(find.widgetWithText(TextButton, 'تعليم الكل كمقروء'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('server down'), findsOneWidget);
      expect(find.text('الإشعارات'), findsOneWidget);
      verifyNever(() => repo.markAsRead(1));
    });
  });
}
