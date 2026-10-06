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

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    this.body,
    required this.type,
    this.entityId,
    required this.isRead,
    required this.createdAt,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        entityId: entityId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props =>
      [id, userId, title, body, type, entityId, isRead, createdAt];
}
