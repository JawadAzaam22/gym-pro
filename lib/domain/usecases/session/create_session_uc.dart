import "package:dartz/dartz.dart";
import "../../../core/errors/failures.dart";
import "../../entities/session.dart";
import "../../repositories/i_session_repository.dart";

class CreateSessionUc {
  final ISessionRepository repository;
  CreateSessionUc(this.repository);
  Future<Either<Failure, Session>> call(Session s) => repository.createSession(s);
}

