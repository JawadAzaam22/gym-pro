import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_pro/core/constants/enums.dart';
import 'package:gym_pro/core/errors/exceptions.dart';
import 'package:gym_pro/core/errors/failures.dart';
import 'package:gym_pro/data/datasources/supabase_notification_datasource.dart';
import 'package:gym_pro/data/models/notification_model.dart';
import 'package:gym_pro/data/repositories_impl/notification_repository_impl.dart';
import 'package:gym_pro/domain/entities/notification_item.dart';

class _MockDatasource extends Mock
    implements SupabaseNotificationDatasource {}

void main() {
  late _MockDatasource ds;
  late NotificationRepositoryImpl repo;

  setUp(() {
    ds = _MockDatasource();
    repo = NotificationRepositoryImpl(ds);
  });

  NotificationModel model({int id = 1, bool isRead = false}) =>
      NotificationModel(
        id: id,
        userId: 'u-1',
        title: 'عنوان $id',
        body: 'نص',
        type: NotificationType.membershipExpiry,
        entityId: 42,
        isRead: isRead,
        createdAt: DateTime(2026, 1, 1, 12),
      );

  group('getMyNotifications', () {
    test('ناجح → Right وتحوّل النماذج إلى كيانات', () async {
      when(() => ds.getMyNotifications())
          .thenAnswer((_) async => [model(id: 1), model(id: 2, isRead: true)]);

      final res = await repo.getMyNotifications();

      expect(res.isRight(), isTrue);
      final list = res.getOrElse(() => <AppNotification>[]);
      expect(list, hasLength(2));
      expect(list.first, isA<AppNotification>());
      expect(list.map((e) => e.id), [1, 2]);
      expect(list.first.type, NotificationType.membershipExpiry);
      expect(list.last.isRead, isTrue);
    });

    test('AuthException → AuthFailure بنفس الرسالة', () async {
      when(() => ds.getMyNotifications())
          .thenThrow(AuthException('يجب تسجيل الدخول لعرض الإشعارات'));

      final res = await repo.getMyNotifications();

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) {
          expect(f, isA<AuthFailure>());
          expect(f.message, 'يجب تسجيل الدخول لعرض الإشعارات');
        },
        (_) => fail('كان المتوقع Left'),
      );
    });

    test('ServerException → ServerFailure بنفس الرسالة', () async {
      when(() => ds.getMyNotifications())
          .thenThrow(ServerException('انقطاع الشبكة'));

      final res = await repo.getMyNotifications();

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) {
          expect(f, isA<ServerFailure>());
          expect(f.message, 'انقطاع الشبكة');
        },
        (_) => fail('كان المتوقع Left'),
      );
    });

    test('استثناء غير معروف → ServerFailure بديل (لا يتسرب)', () async {
      when(() => ds.getMyNotifications()).thenThrow(ArgumentError('boom'));

      final res = await repo.getMyNotifications();

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('كان المتوقع Left'),
      );
    });
  });

  group('watchMyNotifications', () {
    test('يحوّل النماذج الواردة إلى كيانات', () async {
      when(() => ds.watchMyNotifications())
          .thenAnswer((_) => Stream.fromIterable([
                [model(id: 10)],
                [model(id: 11), model(id: 12, isRead: true)],
              ]));

      final events = await repo.watchMyNotifications().toList();

      expect(events, hasLength(2));
      expect(events.first.single.id, 10);
      expect(events.last, hasLength(2));
      expect(events.last.last, isA<AppNotification>());
    });

    test('لا يبتلع أخطاء الـ stream (تظهر لطبقة الواجهة)', () async {
      when(() => ds.watchMyNotifications())
          .thenAnswer((_) => Stream<List<NotificationModel>>.error(
              ServerException('realtime انقطع')));

      await expectLater(
        repo.watchMyNotifications().toList(),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('markAsRead / markAllAsRead / deleteNotification', () {
    test('markAsRead ناجح → Right(null)', () async {
      when(() => ds.markAsRead(7)).thenAnswer((_) async {});

      final res = await repo.markAsRead(7);

      expect(res, isA<Right<Failure, void>>());
      verify(() => ds.markAsRead(7)).called(1);
    });

    test('markAsRead يرمي ServerException → Left(ServerFailure)', () async {
      when(() => ds.markAsRead(7)).thenThrow(ServerException('فشل الكتابة'));

      final res = await repo.markAsRead(7);

      expect(res.isLeft(), isTrue);
      expect(res, isA<Left<Failure, void>>());
    });

    test('markAsRead لا يمسّ البث (المصدر فقط من يقرر)', () async {
      when(() => ds.markAsRead(7)).thenAnswer((_) async {});

      await repo.markAsRead(7);

      verifyNever(() => ds.getMyNotifications());
      verifyNever(() => ds.watchMyNotifications());
    });

    test('markAllAsRead ناجح → Right', () async {
      when(() => ds.markAllAsRead()).thenAnswer((_) async {});

      final res = await repo.markAllAsRead();

      expect(res, isA<Right<Failure, void>>());
      verify(() => ds.markAllAsRead()).called(1);
    });

    test('markAllAsRead AuthException → Left(AuthFailure)', () async {
      when(() => ds.markAllAsRead())
          .thenThrow(AuthException('انتهت الجلسة'));

      final res = await repo.markAllAsRead();

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f, isA<AuthFailure>()),
        (_) => fail('كان المتوقع Left'),
      );
    });

    test('deleteNotification ناجح → Right', () async {
      when(() => ds.deleteNotification(3)).thenAnswer((_) async {});

      final res = await repo.deleteNotification(3);

      expect(res, isA<Right<Failure, void>>());
      verify(() => ds.deleteNotification(3)).called(1);
    });

    test('deleteNotification فشل → Left(ServerFailure)', () async {
      when(() => ds.deleteNotification(3)).thenThrow(ServerException('مرفوض'));

      final res = await repo.deleteNotification(3);

      expect(res, isA<Left<Failure, void>>());
    });
  });

  group('createNotification', () {
    test('ناجح → Right والكيان يحمل الحقول', () async {
      when(() => ds.createNotification(
            userId: 'u-9',
            title: 'تم اعتماد اشتراكك',
            body: 'مدة 3 أشهر',
            type: 'membership_expiry',
            entityId: 55,
          )).thenAnswer((_) async => model(id: 42));

      final res = await repo.createNotification(
        userId: 'u-9',
        title: 'تم اعتماد اشتراكك',
        body: 'مدة 3 أشهر',
        type: 'membership_expiry',
        entityId: 55,
      );

      expect(res.isRight(), isTrue);
      final n = res.getOrElse(() => model());
      expect(n.id, 42);
      expect(n.type, NotificationType.membershipExpiry);
    });

    test('AuthException → Left(AuthFailure)', () async {
      when(() => ds.createNotification(
            userId: 'u',
            title: 't',
            body: null,
            type: 'system',
            entityId: null,
          )).thenThrow(AuthException('غير مصرح'));

      final res = await repo.createNotification(userId: 'u', title: 't');

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f, isA<AuthFailure>()),
        (_) => fail('كان المتوقع Left'),
      );
    });
  });
}
