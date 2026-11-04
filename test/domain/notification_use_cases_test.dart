import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_pro/core/errors/failures.dart';
import 'package:gym_pro/domain/entities/notification_item.dart';
import 'package:gym_pro/domain/repositories/i_notification_repository.dart';
import 'package:gym_pro/domain/usecases/notification_use_cases.dart';

class _FakeNotificationRepository implements INotificationRepository {
  int? markedId;
  bool markedAll = false;
  int? deletedId;

  @override
  Future<Either<Failure, List<AppNotification>>> getMyNotifications() async =>
      const Right([]);

  @override
  Stream<List<AppNotification>> watchMyNotifications() =>
      Stream.value(const []);

  @override
  Future<Either<Failure, void>> markAsRead(int id) async {
    markedId = id;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    markedAll = true;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteNotification(int id) async {
    deletedId = id;
    return const Right(null);
  }

  @override
  Future<Either<Failure, AppNotification>> createNotification({
    required String userId,
    required String title,
    String? body,
    String type = 'system',
    int? entityId,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  test('notification commands delegate intent to the repository', () async {
    final repository = _FakeNotificationRepository();

    expect(await MarkNotificationAsRead(repository).call(4), const Right(null));
    expect(await MarkAllNotificationsAsRead(repository).call(), const Right(null));
    expect(await DeleteNotification(repository).call(7), const Right(null));
    expect(repository.markedId, 4);
    expect(repository.markedAll, isTrue);
    expect(repository.deletedId, 7);
  });

  test('watch use case exposes the repository stream', () async {
    final repository = _FakeNotificationRepository();

    expect(await WatchMyNotifications(repository).call().first, isEmpty);
  });
}
