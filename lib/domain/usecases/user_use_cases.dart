import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/i_user_repository.dart';

class UserUseCases {
  final IUserRepository repository;
  const UserUseCases(this.repository);

  Future<Either<Failure, List<User>>> getAllUsers() => repository.getAllUsers();
  Future<Either<Failure, List<User>>> getAllUsersIncludingInactive() =>
      repository.getAllUsersIncludingInactive();
  Future<Either<Failure, User>> getUserById(String id) =>
      repository.getUserById(id);
  Future<Either<Failure, User>> createUser(User user, String password) =>
      repository.createUser(user, password);
  Future<Either<Failure, User>> updateUser(User user) =>
      repository.updateUser(user);
  Future<Either<Failure, void>> deactivateUser(String id) =>
      repository.deactivateUser(id);
  Future<Either<Failure, void>> deleteUser(String id, {bool cascade = false}) =>
      repository.deleteUser(id, cascade: cascade);
  Future<Either<Failure, List<User>>> getUsersByRole(String role) =>
      repository.getUsersByRole(role);
}
