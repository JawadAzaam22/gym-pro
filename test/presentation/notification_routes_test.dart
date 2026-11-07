import 'package:flutter_test/flutter_test.dart';
import 'package:gym_pro/core/constants/enums.dart';
import 'package:gym_pro/domain/entities/notification_item.dart';
import 'package:gym_pro/presentation/shared/notifications/notification_routes.dart';

AppNotification _notif({Map<String, dynamic>? data}) => AppNotification(
      id: 1,
      userId: 'u-1',
      title: 'إشعار',
      type: NotificationType.system,
      isRead: false,
      createdAt: DateTime(2026, 1, 1),
      data: data,
    );

void main() {
  group('notificationRouteFor — عقد data.screen الستة', () {
    test('my_bookings → /trainee/bookings للتدريب فقط', () {
      final n = _notif(data: {'screen': 'my_bookings'});
      expect(notificationRouteFor(n, UserRole.trainee), '/trainee/bookings');
      expect(notificationRouteFor(n, UserRole.trainer), isNull);
      expect(notificationRouteFor(n, UserRole.admin), isNull);
      expect(notificationRouteFor(n, UserRole.reception), isNull);
    });

    test('membership → /trainee/membership للتدريب فقط', () {
      final n = _notif(data: {'screen': 'membership'});
      expect(notificationRouteFor(n, UserRole.trainee), '/trainee/membership');
      expect(notificationRouteFor(n, UserRole.trainer), isNull);
    });

    test('my_trainer → /trainee/trainer للتدريب فقط', () {
      final n = _notif(data: {'screen': 'my_trainer'});
      expect(notificationRouteFor(n, UserRole.trainee), '/trainee/trainer');
      expect(notificationRouteFor(n, UserRole.reception), isNull);
    });

    test('trainees → /trainer/trainees للمدرب فقط', () {
      final n = _notif(data: {'screen': 'trainees'});
      expect(notificationRouteFor(n, UserRole.trainer), '/trainer/trainees');
      expect(notificationRouteFor(n, UserRole.trainee), isNull);
    });

    test('fixed_schedule → جدول المدرب أو جلسات المتدرب حسب الدور', () {
      final n = _notif(data: {'screen': 'fixed_schedule'});
      expect(notificationRouteFor(n, UserRole.trainer), '/trainer/schedule');
      expect(
          notificationRouteFor(n, UserRole.trainee), '/trainee/private-sessions');
      expect(notificationRouteFor(n, UserRole.admin), isNull);
    });

    test('قيمة مجهولة أو غائبة تُرجع null ولا تُغيّر الشاشة', () {
      expect(notificationRouteFor(_notif(data: {'screen': 'wat'}), UserRole.trainee),
          isNull);
      expect(notificationRouteFor(_notif(), UserRole.trainee), isNull);
      expect(notificationRouteFor(_notif(data: {}), UserRole.trainee), isNull);
      expect(notificationRouteFor(_notif(data: {'screen': 42}), UserRole.trainee),
          isNull);
      expect(
          notificationRouteFor(
              _notif(data: {'screen': null}), UserRole.trainee),
          isNull);
    });
  });
}
