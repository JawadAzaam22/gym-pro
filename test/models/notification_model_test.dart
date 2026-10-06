import 'package:flutter_test/flutter_test.dart';
import 'package:gym_pro/core/constants/enums.dart';
import 'package:gym_pro/data/models/notification_model.dart';
import 'package:gym_pro/domain/entities/notification_item.dart';

void main() {
  Map<String, dynamic> jsonWith({
    int id = 7,
    bool? isRead,
    String? type = 'membership_expiry',
    Object? entityId = 42,
    String createdAt = '2026-01-01T10:30:00+00:00',
    String? body = 'باقي يومان',
  }) =>
      {
        'id': id,
        'user_id': 'u-1',
        'title': 'ينتهي اشتراكك قريباً',
        if (body != null) 'body': body,
        'type': type,
        'entity_id': entityId,
        if (isRead != null) 'is_read': isRead,
        'created_at': createdAt,
      };

  group('NotificationTypeX - تطبيع نوع الإشعار', () {
    test('toDbString ثم fromString يعود بنفس النوع لكل الأنواع', () {
      for (final t in NotificationType.values) {
        expect(NotificationTypeX.fromString(t.toDbString()), t,
            reason: 'فشل التحويل للنوع ${t.name}');
      }
    });

    test('null أو قيمة مجهولة تُخزَّن system', () {
      expect(NotificationTypeX.fromString(null), NotificationType.system);
      expect(NotificationTypeX.fromString(''), NotificationType.system);
      expect(NotificationTypeX.fromString('not_a_type'),
          NotificationType.system);
    });

    test('nameAr نص عربي غير فارغ لكل الأنواع', () {
      final arabic = RegExp(r'[\u0600-\u06FF]');
      for (final t in NotificationType.values) {
        expect(t.nameAr, isNotEmpty, reason: '${t.name} بلا تسمية عربية');
        expect(arabic.hasMatch(t.nameAr), isTrue,
            reason: '${t.name} ليست بالعربية: ${t.nameAr}');
      }
    });
  });

  group('NotificationModel.fromJson', () {
    test('يطبّع كل الحقول بأسمائها الصحيحة', () {
      final m = NotificationModel.fromJson(jsonWith());

      expect(m.id, 7);
      expect(m.userId, 'u-1');
      expect(m.title, 'ينتهي اشتراكك قريباً');
      expect(m.body, 'باقي يومان');
      expect(m.type, NotificationType.membershipExpiry);
      expect(m.entityId, 42);
      expect(m.isRead, isFalse);
      expect(m.createdAt, DateTime.parse('2026-01-01T10:30:00+00:00'));
    });

    test('is_read مفقود يعني غير مقروء (false)', () {
      final m = NotificationModel.fromJson(jsonWith());
      expect(m.isRead, isFalse);
    });

    test('entity_id و body null يمران كما هما', () {
      final m = NotificationModel.fromJson(
          jsonWith(entityId: null, body: null, type: 'system'));
      expect(m.entityId, isNull);
      expect(m.body, isNull);
      expect(m.type, NotificationType.system);
    });

    test('id رقمي (int) أو num يقبل التطبيع', () {
      final m = NotificationModel.fromJson(jsonWith(id: 12));
      expect(m.id, 12);
      expect(m.id, isA<int>());
    });
  });

  group('NotificationModel.toJson / toInsertJson', () {
    test('الدورة الكاملة fromJson ثم toJson تحافظ على القيمة', () {
      final m = NotificationModel.fromJson(jsonWith(isRead: true));
      final again = NotificationModel.fromJson(m.toJson());

      expect(again, m);
      expect(again.toJson(), m.toJson());
    });

    test('toJson يكتب type بصيغة قاعدة البيانات', () {
      final m = NotificationModel.fromJson(jsonWith(type: 'session_reminder'));
      expect(m.toJson()['type'], 'session_reminder');
      expect(m.toJson()['type'], m.type.toDbString());
    });

    test('toInsertJson يحذف id و created_at', () {
      final j = NotificationModel.fromJson(jsonWith()).toInsertJson();
      expect(j.containsKey('id'), isFalse);
      expect(j.containsKey('created_at'), isFalse);
      expect(j['user_id'], 'u-1');
      expect(j['is_read'], isFalse);
      expect(j.containsKey('type'), isTrue);
    });
  });

  group('NotificationModel <-> AppNotification', () {
    test('toEntity ينقل كل الحقول دون فقد', () {
      final m = NotificationModel.fromJson(jsonWith(isRead: true));
      final e = m.toEntity();
      expect(e, isA<AppNotification>());
      expect(e.id, m.id);
      expect(e.userId, m.userId);
      expect(e.title, m.title);
      expect(e.body, m.body);
      expect(e.type, m.type);
      expect(e.entityId, m.entityId);
      expect(e.isRead, m.isRead);
      expect(e.createdAt, m.createdAt);
    });

    test('fromEntity ثم toEntity عكسية (sameEntity)', () {
      final e = AppNotification(
        id: 5,
        userId: 'u-9',
        title: 'تم الحضور',
        body: null,
        type: NotificationType.attendance,
        entityId: null,
        isRead: false,
        createdAt: DateTime(2026, 2, 3, 9, 15),
      );
      expect(NotificationModel.fromEntity(e).toEntity(), e);
    });

    test('copyWith(isRead) لا يمس باقي الحقول', () {
      final m = NotificationModel.fromJson(jsonWith(isRead: false));
      final read = m.copyWith(isRead: true);
      expect(read.isRead, isTrue);
      expect(read.id, m.id);
      expect(read.title, m.title);
      expect(read.createdAt, m.createdAt);
      expect(m.isRead, isFalse, reason: 'الأصل يجب ألا يتغير');
    });
  });
}
