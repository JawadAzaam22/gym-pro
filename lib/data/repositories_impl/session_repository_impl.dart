import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/i_session_repository.dart';
import '../datasources/supabase_session_datasource.dart';
import '../models/session_model.dart';

class SessionRepositoryImpl implements ISessionRepository {
  final SupabaseSessionDatasource datasource;
  SessionRepositoryImpl(this.datasource);

  @override
  Future<Either<Failure, List<Session>>> getSessions() async {
    try {
      final list = await datasource.getSessions();
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Session>> getSessionById(int id) async {
    try {
      final s = await datasource.getSessionById(id);
      return Right(s.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Session>>> getSessionsByTrainer(String trainerId) async {
    try {
      final list = await datasource.getSessionsByTrainer(trainerId);
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Session>>> getSessionsByHall(int hallId) async {
    try {
      final list = await datasource.getSessionsByHall(hallId);
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Session>> createSession(Session session) async {
    try {
      final model = SessionModel.fromEntity(session);
      final created = await datasource.createSession(model);
      return Right(created.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Session>> updateSession(Session session) async {
    try {
      final model = SessionModel.fromEntity(session);
      final updated = await datasource.updateSession(model);
      return Right(updated.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelSession(int id) async {
    try {
      await datasource.cancelSession(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSession(int id) async {
    try {
      await datasource.deleteSession(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createSessionPeriods(int sessionId, List<int> accessPeriodIds) async {
    try {
      await datasource.createSessionPeriods(sessionId, accessPeriodIds);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<int, Set<int>>>> getAllSessionPeriods() async {
    try {
      final result = await datasource.getAllSessionPeriods();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Set<int>>> getSessionPeriods(int sessionId) async {
    try {
      final result = await datasource.getSessionPeriods(sessionId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
