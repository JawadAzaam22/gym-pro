import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/notification_item.dart';
import '../repositories/i_notification_repository.dart';

class GetMyNotifications {
  final INotificationRepository repository;

  const GetMyNotifications(this.repository);

  Future<Either<Failure, List<AppNotification>>> call() =>
      repository.getMyNotifications();
}

class WatchMyNotifications {
  final INotificationRepository repository;

  const WatchMyNotifications(this.repository);

  Stream<List<AppNotification>> call() => repository.watchMyNotifications();
}

class MarkNotificationAsRead {
  final INotificationRepository repository;

  const MarkNotificationAsRead(this.repository);

  Future<Either<Failure, void>> call(int notificationId) =>
      repository.markAsRead(notificationId);
}

class MarkAllNotificationsAsRead {
  final INotificationRepository repository;

  const MarkAllNotificationsAsRead(this.repository);

  Future<Either<Failure, void>> call() => repository.markAllAsRead();
}

class DeleteNotification {
  final INotificationRepository repository;

  const DeleteNotification(this.repository);

  Future<Either<Failure, void>> call(int notificationId) =>
      repository.deleteNotification(notificationId);
}
