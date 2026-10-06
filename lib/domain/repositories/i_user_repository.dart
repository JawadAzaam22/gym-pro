import "package:dartz/dartz.dart";
import "../../core/errors/failures.dart";
import "../entities/user.dart";

abstract class IUserRepository {
  Future<Either<Failure, List<User>>> getAllUsers();
  Future<Either<Failure, List<User>>> getAllUsersIncludingInactive();
  Future<Either<Failure, User>> getUserById(String id);
  Future<Either<Failure, User>> createUser(User user, String password);
  Future<Either<Failure, User>> updateUser(User user);
  Future<Either<Failure, void>> deactivateUser(String id);
  Future<Either<Failure, void>> deleteUser(String id, {bool cascade = false});
  Future<Either<Failure, List<User>>> getUsersByRole(String role);
}
