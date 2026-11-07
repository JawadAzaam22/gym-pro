import "package:equatable/equatable.dart";
import "../../core/constants/enums.dart";

class AppNotification extends Equatable {
  final int id;
  final String userId;
  final String title;
  final String? body;
  final NotificationType type;
  final int? entityId;
  final bool isRead;
  final DateTime createdAt;

  /// حمولة الـ jsonb من عمود `data` في السيرفر (مثل `{"screen": ...}`).
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    this.body,
    required this.type,
    this.entityId,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  /// قيمة مفتاح من حمولة `data` إن وُجدت، وإلا null.
  String? dataString(String key) {
    final v = data?[key];
    return v is String ? v : null;
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        entityId: entityId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        data: data,
      );

  @override
  List<Object?> get props =>
      [id, userId, title, body, type, entityId, isRead, createdAt, data];
}
