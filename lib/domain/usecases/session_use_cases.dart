import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/session.dart';
import '../repositories/i_session_repository.dart';

class SessionUseCases {
  final ISessionRepository repository;
  const SessionUseCases(this.repository);

  Future<Either<Failure, List<Session>>> getSessions() =>
      repository.getSessions();
  Future<Either<Failure, Session>> getSessionById(int id) =>
      repository.getSessionById(id);
  Future<Either<Failure, Session>> createSession(Session session) =>
      repository.createSession(session);
  Future<Either<Failure, Session>> updateSession(Session session) =>
      repository.updateSession(session);
  Future<Either<Failure, void>> cancelSession(int id) =>
      repository.cancelSession(id);
  Future<Either<Failure, void>> deleteSession(int id) =>
      repository.deleteSession(id);
  Future<Either<Failure, List<Session>>> getSessionsByTrainer(String id) =>
      repository.getSessionsByTrainer(id);
  Future<Either<Failure, List<Session>>> getSessionsByHall(int id) =>
      repository.getSessionsByHall(id);
  Future<Either<Failure, void>> createSessionPeriods(
          int sessionId, List<int> periodIds) =>
      repository.createSessionPeriods(sessionId, periodIds);
  Future<Either<Failure, Map<int, Set<int>>>> getAllSessionPeriods() =>
      repository.getAllSessionPeriods();
  Future<Either<Failure, Set<int>>> getSessionPeriods(int id) =>
      repository.getSessionPeriods(id);
}
