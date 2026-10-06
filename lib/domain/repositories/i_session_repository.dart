import "package:dartz/dartz.dart";
import "../../core/errors/failures.dart";
import "../entities/session.dart";

abstract class ISessionRepository {
  Future<Either<Failure, List<Session>>> getSessions();
  Future<Either<Failure, Session>> getSessionById(int id);
  Future<Either<Failure, Session>> createSession(Session session);
  Future<Either<Failure, Session>> updateSession(Session session);
  Future<Either<Failure, void>> cancelSession(int id);
  Future<Either<Failure, void>> deleteSession(int id);
  Future<Either<Failure, List<Session>>> getSessionsByTrainer(String trainerId);
  Future<Either<Failure, List<Session>>> getSessionsByHall(int hallId);
  Future<Either<Failure, void>> createSessionPeriods(int sessionId, List<int> accessPeriodIds);
  Future<Either<Failure, Map<int, Set<int>>>> getAllSessionPeriods();
  Future<Either<Failure, Set<int>>> getSessionPeriods(int sessionId);
}
