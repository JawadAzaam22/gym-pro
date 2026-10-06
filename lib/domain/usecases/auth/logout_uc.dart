import "package:dartz/dartz.dart";
import "../../../core/errors/failures.dart";
import "../../repositories/i_auth_repository.dart";

class LogoutUc {
  final IAuthRepository repository;
  LogoutUc(this.repository);
  Future<Either<Failure, void>> call() => repository.logout();
}

