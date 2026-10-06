import "package:dartz/dartz.dart";
import "../../core/errors/failures.dart";
import "../entities/notification_item.dart";

abstract class INotificationRepository {
  /// جلب إشعارات المستخدم الحالي (أحدث أولاً).
  Future<Either<Failure, List<AppNotification>>> getMyNotifications();

  /// بث لحظي عبر Supabase Realtime — يتحدث فور وصول إشعار جديد.
  Stream<List<AppNotification>> watchMyNotifications();

  /// تعليم إشعار واحد كمقروء.
  Future<Either<Failure, void>> markAsRead(int id);

  /// تعليم كل إشعارات المستخدم كمقروءة.
  Future<Either<Failure, void>> markAllAsRead();

  /// حذف إشعار.
  Future<Either<Failure, void>> deleteNotification(int id);

  /// إنشاء إشعار (للموظفين: أدمن/استقبال).
  Future<Either<Failure, AppNotification>> createNotification({
    required String userId,
    required String title,
    String? body,
    String type = 'system',
    int? entityId,
  });
}
