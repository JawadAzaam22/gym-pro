import 'package:flutter_test/flutter_test.dart';
import 'package:gym_pro/core/constants/enums.dart';
import 'package:gym_pro/data/models/notification_model.dart';

/// اختبارات العقد الحقيقي للسيرفر: الأنواع الستة التي تُنشئها الـ triggers
/// والـ cron، مع حمولة `data` jsonb و`membership_id`.
void main() {
  Map<String, dynamic> serverJson({
    String type = 'booking_confirmed',
    Map<String, dynamic>? data,
  }) =>
      {
        'id': 10,
        'user_id': 'trainee-uuid',
        'title': 'تم تأكيد حجزك',
        'body': 'حصة صباحية',
        'type': type,
        'is_read': false,
        'created_at': '2026-03-01T08:00:00+00:00',
        if (data != null) 'data': data,
      };

  group('أنواع السيرفر الستة تُحلّل بلا system fallback', () {
    const contractTypes = {
      'booking_confirmed': NotificationType.bookingConfirmed,
      'membership_created': NotificationType.membershipCreated,
      'trainer_assigned': NotificationType.trainerAssigned,
      'trainee_assigned': NotificationType.traineeAssigned,
      'fixed_schedule_created': NotificationType.fixedScheduleCreated,
      'membership_expiring_soon': NotificationType.membershipExpiringSoon,
    };

    contractTypes.forEach((raw, expected) {
      test("'$raw' → ${expected.name}", () {
        final m = NotificationModel.fromJson(serverJson(type: raw));
        expect(m.type, expected);
        expect(m.type.toDbString(), raw,
            reason: 'دورة toDbString يجب أن تُعيد نص السيرفر نفسه');
      });
    });

    test('نوع مجهول لا ينهار ويرجع system', () {
      final m = NotificationModel.fromJson(serverJson(type: 'brand_new_type'));
      expect(m.type, NotificationType.system);
    });
  });

  group('حمولة data jsonb', () {
    test('تُحلّل كـ Map وتصلح dataString', () {
      final m = NotificationModel.fromJson(serverJson(
        type: 'membership_expiring_soon',
        data: {'screen': 'membership', 'membership_id': 55},
      ));
      expect(m.data, isNotNull);
      expect(m.dataString('screen'), 'membership');
      expect(m.data?['membership_id'], 55);
      // membership_id رقمي — dataString يرجع null للأنواع غير النصية.
      expect(m.dataString('membership_id'), isNull);
    });

    test('data مفقود أو null يمر كـ null بلا استثناء', () {
      expect(NotificationModel.fromJson(serverJson()).data, isNull);
      final j = serverJson();
      j['data'] = null;
      expect(NotificationModel.fromJson(j).data, isNull);
    });

    test('data بقيم غير Map (نص) لا يُسقط التحليل', () {
      final j = serverJson();
      j['data'] = 'oops';
      expect(NotificationModel.fromJson(j).data, isNull);
    });
  });

  group('حقول العقد الأخرى', () {
    test('created_at يبقى UTC كما أرسله السيرفر', () {
      final m = NotificationModel.fromJson(serverJson());
      expect(m.createdAt.isUtc, isTrue);
      expect(m.createdAt.toUtc(),
          DateTime.parse('2026-03-01T08:00:00+00:00'));
    });

    test('غياب entity_id (عمود غير موجود في السيرفر) لا يُسقط التحليل', () {
      final m = NotificationModel.fromJson(serverJson());
      expect(m.entityId, isNull);
    });

    test('toInsertJson لا يرسل entity_id ولا id ولا created_at', () {
      final j = NotificationModel.fromJson(
              serverJson(data: {'screen': 'membership'}))
          .toInsertJson();
      expect(j.containsKey('entity_id'), isFalse);
      expect(j.containsKey('id'), isFalse);
      expect(j.containsKey('created_at'), isFalse);
      expect(j['type'], 'booking_confirmed');
      expect(j['data'], {'screen': 'membership'});
    });
  });
}
