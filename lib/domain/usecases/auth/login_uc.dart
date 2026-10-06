import "package:dartz/dartz.dart";
import "../../../core/errors/failures.dart";
import "../../entities/user.dart";
import "../../repositories/i_auth_repository.dart";

class LoginUc {
  final IAuthRepository repository;
  LoginUc(this.repository);
  Future<Either<Failure, User>> call(String email, String password) =>
      repository.login(email, password);
}

