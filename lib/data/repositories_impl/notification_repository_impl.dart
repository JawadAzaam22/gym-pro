import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/i_notification_repository.dart';
import '../datasources/supabase_notification_datasource.dart';

class NotificationRepositoryImpl implements INotificationRepository {
  final SupabaseNotificationDatasource datasource;
  NotificationRepositoryImpl(this.datasource);

  @override
  Future<Either<Failure, List<AppNotification>>> getMyNotifications() async {
    try {
      final list = await datasource.getMyNotifications();
      return Right(list.map((e) => e.toEntity()).toList());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<AppNotification>> watchMyNotifications() =>
      datasource.watchMyNotifications().map((l) => l.map((e) => e.toEntity()).toList());

  @override
  Future<Either<Failure, void>> markAsRead(int id) async {
    try {
      await datasource.markAsRead(id);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    try {
      await datasource.markAllAsRead();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(int id) async {
    try {
      await datasource.deleteNotification(id);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppNotification>> createNotification({
    required String userId,
    required String title,
    String? body,
    String type = 'system',
    int? entityId,
  }) async {
    try {
      final n = await datasource.createNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        entityId: entityId,
      );
      return Right(n.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
