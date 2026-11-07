import "../../core/constants/enums.dart";
import "../../domain/entities/notification_item.dart";

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.title,
    super.body,
    required super.type,
    super.entityId,
    required super.isRead,
    required super.createdAt,
    super.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: (json['id'] as num).toInt(),
        userId: json['user_id'] as String,
        title: json['title'] as String,
        body: json['body'] as String?,
        type: NotificationTypeX.fromString(json['type'] as String?),
        entityId: (json['entity_id'] as num?)?.toInt(),
        isRead: json['is_read'] as bool? ?? false,
        // يبقى UTC كما أرسله السيرفر؛ طبقة العرض (Formatters) تحوّل للمنطقة
        // المحلية عند التنسيق كي لا تنكسر مقارنات DateTime (isUtc).
        createdAt: DateTime.parse(json['created_at'] as String),
        data: json['data'] is Map
            ? Map<String, dynamic>.from(json['data'] as Map)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type.toDbString(),
        'entity_id': entityId,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
        if (data != null) 'data': data,
      };

  Map<String, dynamic> toInsertJson() {
    final j = toJson();
    j.remove('id');
    j.remove('created_at');
    // `entity_id` غير موجود في جدول السيرفر — إرساله يفشل بـ PostgREST.
    j.remove('entity_id');
    return j;
  }

  factory NotificationModel.fromEntity(AppNotification e) => NotificationModel(
        id: e.id,
        userId: e.userId,
        title: e.title,
        body: e.body,
        type: e.type,
        entityId: e.entityId,
        isRead: e.isRead,
        createdAt: e.createdAt,
        data: e.data,
      );

  AppNotification toEntity() => AppNotification(
        id: id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        entityId: entityId,
        isRead: isRead,
        createdAt: createdAt,
        data: data,
      );
}
