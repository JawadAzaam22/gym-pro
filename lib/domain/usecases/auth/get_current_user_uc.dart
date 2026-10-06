import "package:dartz/dartz.dart";
import "../../../core/errors/failures.dart";
import "../../entities/user.dart";
import "../../repositories/i_auth_repository.dart";

class GetCurrentUserUc {
  final IAuthRepository repository;
  GetCurrentUserUc(this.repository);
  Future<Either<Failure, User?>> call() => repository.getCurrentUser();
}

