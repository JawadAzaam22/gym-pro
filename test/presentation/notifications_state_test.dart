import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_pro/core/constants/enums.dart';
import 'package:gym_pro/core/errors/failures.dart';
import 'package:gym_pro/data/datasources/supabase_auth_datasource.dart';
import 'package:gym_pro/data/providers.dart';
import 'package:gym_pro/data/repositories_impl/auth_repository_impl.dart';
import 'package:gym_pro/domain/entities/notification_item.dart';
import 'package:gym_pro/domain/repositories/i_notification_repository.dart';
import 'package:gym_pro/presentation/shared/auth/controllers/auth_controller.dart';
import 'package:gym_pro/presentation/shared/notifications/controllers/notifications_controller.dart';
import 'package:mocktail/mocktail.dart';

AppNotification _n(int id, {bool read = false}) => AppNotification(
      id: id,
      userId: 'u-1',
      title: 't$id',
      type: NotificationType.system,
      isRead: read,
      createdAt: DateTime(2026, 1, 1),
    );

class _FakeNotifRepo implements INotificationRepository {
  _FakeNotifRepo(this.source);
  final Stream<List<AppNotification>> source;
  int watchCalls = 0;

  @override
  Stream<List<AppNotification>> watchMyNotifications() {
    watchCalls++;
    return source;
  }

  @override
  Future<Either<Failure, List<AppNotification>>> getMyNotifications() async =>
      Right([]);
  @override
  Future<Either<Failure, void>> markAsRead(int id) async => const Right(null);
  @override
  Future<Either<Failure, void>> markAllAsRead() async => const Right(null);
  @override
  Future<Either<Failure, void>> deleteNotification(int id) async =>
      const Right(null);
  @override
  Future<Either<Failure, AppNotification>> createNotification({
    required String userId,
    required String title,
    String? body,
    String type = 'system',
    int? entityId,
  }) async =>
      throw UnimplementedError();
}

class _MockAuthDatasource extends Mock implements SupabaseAuthDatasource {}

void main() {
  group('unreadNotificationsCountProvider', () {
    test('عدّ غير المقروءات = العناصر غير المقروءة (فارغ → 0)', () {
      final c = ProviderContainer(overrides: [
        notificationRepositoryProvider
            .overrideWithValue(_FakeNotifRepo(const Stream.empty())),
      ]);
      addTearDown(c.dispose);
      expect(c.read(unreadNotificationsCountProvider), 0);
    });

    test('يتحدث حياً مع كل حدث بث (إضافة/تعديل/حذف)', () async {
      final controller = StreamController<List<AppNotification>>();
      final c = ProviderContainer(overrides: [
        notificationRepositoryProvider
            .overrideWithValue(_FakeNotifRepo(controller.stream)),
      ]);
      addTearDown(c.dispose);
      addTearDown(controller.close);

      // قراءة أولى تفتح الاشتراك على البث قبل إرسال الأحداث.
      expect(c.read(unreadNotificationsCountProvider), 0);

      controller.add([_n(1), _n(2, read: true), _n(3)]);
      await pumpEventQueue();
      expect(c.read(unreadNotificationsCountProvider), 2);

      // UPDATE: تعليم الكل كمقروء
      controller.add([_n(1, read: true), _n(2, read: true), _n(3, read: true)]);
      await pumpEventQueue();
      expect(c.read(unreadNotificationsCountProvider), 0);

      // DELETE: إزالة غير المقروء
      controller.add([_n(1), _n(2, read: true)]);
      await pumpEventQueue();
      expect(c.read(unreadNotificationsCountProvider), 1);
    });

    test('خطأ البث → 0 (لا يُسقط الشارة)', () async {
      final controller = StreamController<List<AppNotification>>();
      final c = ProviderContainer(overrides: [
        notificationRepositoryProvider
            .overrideWithValue(_FakeNotifRepo(controller.stream)),
      ]);
      addTearDown(c.dispose);
      addTearDown(controller.close);

      controller.addError(StateError('boom'));
      await pumpEventQueue();
      expect(c.read(unreadNotificationsCountProvider), 0);
    });
  });

  group('logout — تنظيف حالة الإشعارات', () {
    test('logout يستدعي repo.logout ثم يُبطل بث الإشعارات (اشتراك جديد)', () async {
      final ds = _MockAuthDatasource();
      when(() => ds.getCurrentUser()).thenAnswer((_) async => null);
      when(() => ds.logout()).thenAnswer((_) async {});
      final notif = _FakeNotifRepo(const Stream.empty());
      final c = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(AuthRepositoryImpl(ds)),
        notificationRepositoryProvider.overrideWithValue(notif),
      ]);
      addTearDown(c.dispose);

      // تهيئة الحالة + مراقبة بث الإشعارات.
      await c.read(authControllerProvider.future);
      c.read(notificationsProvider);
      expect(notif.watchCalls, 1);

      await c.read(authControllerProvider.notifier).logout();

      verify(() => ds.logout()).called(1);
      expect(c.read(authControllerProvider).valueOrNull, isNull);
      // إعادة القراءة بعد الإبطال تفتح اشتراكاً جديداً (المزوّد القديم أُبطل).
      c.read(notificationsProvider);
      expect(notif.watchCalls, 2);
      // عدّاد الشارة يعود 0 بعد الإبطال (لا بيانات للمستخدم الجديد بعد).
      expect(c.read(unreadNotificationsCountProvider), 0);
    });
  });
}
