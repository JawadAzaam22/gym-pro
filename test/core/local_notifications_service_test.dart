import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:gym_pro/core/notifications/local_notifications_service.dart';

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _MockAndroid extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class _MockIos extends Mock implements IOSFlutterLocalNotificationsPlugin {}

void main() {
  late _MockPlugin plugin;

  setUpAll(() {
    tzdata.initializeTimeZones();
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(tz.TZDateTime(tz.UTC, 2026));
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
  });

  setUp(() {
    plugin = _MockPlugin();
    when(() => plugin.initialize(any())).thenAnswer((_) async => true);
    when(() => plugin.show(any(), any(), any(), any(),
            payload: any(named: 'payload')))
        .thenAnswer((_) async {});
    when(() => plugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        )).thenAnswer((_) async {});
    when(() => plugin.cancel(any())).thenAnswer((_) async {});
    when(() => plugin.cancelAll()).thenAnswer((_) async {});
    when(() =>
            plugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>())
        .thenReturn(null);
    when(() =>
            plugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>())
        .thenReturn(null);
  });

  LocalNotificationsService build() => LocalNotificationsService(plugin: plugin);

  Future<void> initReady(LocalNotificationsService s) async {
    await s.init();
    expect(s.isReady, isTrue);
  }

  group('الدوال النقية', () {
    test('toTz تحافظ على اللحظة نفسها (غير المعاملات الزمنية)', () {
      final local = DateTime(2026, 6, 15, 18, 30);
      final converted = LocalNotificationsService.toTz(local);

      expect(
        converted.millisecondsSinceEpoch,
        local.millisecondsSinceEpoch,
        reason: 'اللحظة يجب ألا تتغير عند التحويل',
      );
      expect(converted, isA<tz.TZDateTime>());
    });

    test('toTz تعمل مع وقت UTC أيضاً', () {
      final utc = DateTime.utc(2026, 6, 15, 18, 30);
      final converted = LocalNotificationsService.toTz(utc);
      expect(converted.millisecondsSinceEpoch, utc.millisecondsSinceEpoch);
    });

    group('isSchedulable', () {
      final now = DateTime(2026, 6, 15, 12, 0);

      test('موعد مستقبلي صالح', () {
        expect(
            LocalNotificationsService.isSchedulable(
                now.add(const Duration(hours: 1)), now),
            isTrue);
      });

      test('موعد ماضٍ مرفوض', () {
        expect(
            LocalNotificationsService.isSchedulable(
                now.subtract(const Duration(hours: 1)), now),
            isFalse);
      });

      test('موعد بعد ثوانٍ صالح (الجدولة لا تسبق الموعد أبداً)', () {
        expect(
            LocalNotificationsService.isSchedulable(
                now.add(const Duration(seconds: 30)), now),
            isTrue);
      });

      test('موعد منضبط على الآن صالح', () {
        expect(LocalNotificationsService.isSchedulable(now, now), isTrue);
      });

      test('اللحظة قبل الآن بدقيقة واحدة تُرفض', () {
        expect(
            LocalNotificationsService.isSchedulable(
                now.subtract(const Duration(minutes: 1)), now),
            isFalse);
      });
    });

    group('idFor', () {
      test('ثابت لنفس المفتاح (لا يتغير بين الاستدعاءات)', () {
        expect(LocalNotificationsService.idFor('membership-1'),
            LocalNotificationsService.idFor('membership-1'));
      });

      test('مختلف لمفاتيح مختلفة', () {
        expect(LocalNotificationsService.idFor('a'),
            isNot(LocalNotificationsService.idFor('b')));
      });

      test('محصور في المدى الموجب (id صالح للمنصّات)', () {
        const keys = [
          'membership-1',
          'session-2026-06-15',
          'very-long-key-with-dashes-',
          '',
        ];
        for (final k in keys) {
          final id = LocalNotificationsService.idFor(k);
          expect(id, greaterThanOrEqualTo(0), reason: 'مفتاح: $k');
          expect(id, lessThanOrEqualTo(0x7fffffff), reason: 'مفتاح: $k');
        }
      });
    });
  });

  group('init', () {
    test('ناجح → isReady true', () async {
      final s = build();
      expect(s.isReady, isFalse);
      await s.init();
      expect(s.isReady, isTrue);
      verify(() => plugin.initialize(any())).called(1);
    });

    test('استدعاء ثانٍ لا يعيد التهيئة (محمية بـ _ready)', () async {
      final s = build();
      await s.init();
      await s.init();
      verify(() => plugin.initialize(any())).called(1);
    });

    test('فشل التهيئة لا يُسقط التطبيق ويبقى isReady false', () async {
      when(() => plugin.initialize(any())).thenThrow(Exception('no channel'));
      final s = build();
      await expectLater(s.init(), completes);
      expect(s.isReady, isFalse);
    });
  });

  group('requestPermission', () {
    test('تستدعي Android و iOS حسب توفّر المنصّة', () async {
      final android = _MockAndroid();
      final ios = _MockIos();
      when(() => android.requestNotificationsPermission())
          .thenAnswer((_) async => true);
      when(() => ios.requestPermissions(
              alert: any(named: 'alert'),
              badge: any(named: 'badge'),
              sound: any(named: 'sound')))
          .thenAnswer((_) async => true);
      when(() =>
              plugin.resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>())
          .thenReturn(android);
      when(() =>
              plugin.resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>())
          .thenReturn(ios);

      await build().requestPermission();

      verify(() => android.requestNotificationsPermission()).called(1);
      verify(() => ios.requestPermissions(
          alert: true, badge: true, sound: true)).called(1);
    });

    test('غياب المنصّة لا يُسقط التطبيق', () async {
      await expectLater(build().requestPermission(), completes);
    });

    test('رفض الصلاحية لا يُسقط التطبيق', () async {
      final android = _MockAndroid();
      when(() => android.requestNotificationsPermission())
          .thenAnswer((_) async => false);
      when(() =>
              plugin.resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>())
          .thenReturn(android);

      await expectLater(build().requestPermission(), completes);
      verify(() => android.requestNotificationsPermission()).called(1);
    });
  });

  group('قبل التهيئة', () {
    test('showNow ترجع false ولا تلمس الـ plugin', () async {
      final s = build();
      expect(await s.showNow(id: 1, title: 't'), isFalse);
      verifyNever(() => plugin.show(any(), any(), any(), any()));
    });

    test('scheduleAt ترجع false ولا تجدول', () async {
      final s = build();
      expect(
        await s.scheduleAt(
            id: 1,
            title: 't',
            when: DateTime.now().add(const Duration(days: 1))),
        isFalse,
      );
      verifyNever(() => plugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            payload: any(named: 'payload'),
          ));
    });

    test('cancel/cancelAll لا يتسببان في خطأ', () async {
      final s = build();
      await expectLater(s.cancel(1), completes);
      await expectLater(s.cancelAll(), completes);
    });
  });

  group('showNow بعد التهيئة', () {
    test('تعرض الإشعار وتُرجع true', () async {
      final s = build();
      await initReady(s);

      final ok = await s.showNow(
          id: 7, title: 'حصتك بعد ساعة', body: 'قاعة 1', payload: 'session:7');

      expect(ok, isTrue);
      verify(() => plugin.show(7, 'حصتك بعد ساعة', 'قاعة 1', any(),
              payload: 'session:7'))
          .called(1);
    });

    test('فشل الـ plugin → false بلا استثناء', () async {
      when(() => plugin.show(any(), any(), any(), any(),
              payload: any(named: 'payload')))
          .thenThrow(Exception('عرض مرفوض'));
      final s = build();
      await initReady(s);

      expect(await s.showNow(id: 1, title: 't'), isFalse);
    });
  });

  group('scheduleAt بعد التهيئة', () {
    test('موعد مستقبلي → true ويُجدول بنفس اللحظة', () async {
      final s = build();
      await initReady(s);
      final when = DateTime.now().add(const Duration(days: 2));

      final ok = await s.scheduleAt(
          id: 5,
          title: 'موعدك غداً',
          body: 'مع مدرب أحمد',
          when: when,
          payload: 'session:5');

      expect(ok, isTrue);
      final captured = verify(() => plugin.zonedSchedule(
            5,
            'موعدك غداً',
            'مع مدرب أحمد',
            captureAny(),
            captureAny(),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: 'session:5',
          )      ).captured;
      // captureAny() الأولى تقابل المعامل الرابع (موعد الجدولة).
      expect(captured[0], isA<tz.TZDateTime>());
      expect((captured[0] as tz.TZDateTime).millisecondsSinceEpoch,
          when.millisecondsSinceEpoch,
          reason: 'موعد الجدولة يجب أن يساوي الموعد المطلوب');
    });

    test('موعد ماضٍ → false ولا يجدول', () async {
      final s = build();
      await initReady(s);

      final ok = await s.scheduleAt(
          id: 6,
          title: 'متأخر',
          when: DateTime.now().subtract(const Duration(hours: 1)));

      expect(ok, isFalse);
      verifyNever(() => plugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            payload: any(named: 'payload'),
          ));
    });

    test('فشل الجدولة → false بلا استثناء', () async {
      when(() => plugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            payload: any(named: 'payload'),
          )).thenThrow(Exception('جدولة مرفوضة'));
      final s = build();
      await initReady(s);

      expect(
        await s.scheduleAt(
            id: 8,
            title: 't',
            when: DateTime.now().add(const Duration(hours: 3))),
        isFalse,
      );
    });
  });

  group('cancel بعد التهيئة', () {
    test('تستدعي إلغاء الـ plugin', () async {
      final s = build();
      await initReady(s);

      await s.cancel(42);

      verify(() => plugin.cancel(42)).called(1);
    });

    test('cancelAll تستدعي إلغاء الكل', () async {
      final s = build();
      await initReady(s);

      await s.cancelAll();

      verify(() => plugin.cancelAll()).called(1);
    });

    test('فشل الإلغاء لا يُسقط التطبيق', () async {
      when(() => plugin.cancel(any())).thenThrow(Exception('fail'));
      when(() => plugin.cancelAll()).thenThrow(Exception('fail'));
      final s = build();
      await initReady(s);

      await expectLater(s.cancel(1), completes);
      await expectLater(s.cancelAll(), completes);
    });
  });
}
