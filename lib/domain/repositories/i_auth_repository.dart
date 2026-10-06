import "package:dartz/dartz.dart";
import "../../core/errors/failures.dart";
import "../entities/user.dart";

abstract class IAuthRepository {
  Future<Either<Failure, User>> login(String email, String password);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, User?>> getCurrentUser();
  Stream<User?> authStateChanges();
}
