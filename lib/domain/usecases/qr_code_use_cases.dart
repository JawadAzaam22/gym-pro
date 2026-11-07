import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/repositories/i_user_repository.dart';

class IssueTraineeQrCode {
  final IUserRepository repository;

  const IssueTraineeQrCode(this.repository);

  Future<Either<Failure, String>> call() => repository.issueTraineeQrToken();
}
