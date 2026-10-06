import "package:dartz/dartz.dart";
import "../../../core/errors/failures.dart";
import "../../entities/membership.dart";
import "../../repositories/i_membership_repository.dart";

class CheckMembershipStatusUc {
  final IMembershipRepository repository;
  CheckMembershipStatusUc(this.repository);
  Future<Either<Failure, Membership>> call(String traineeId) =>
      repository.checkStatus(traineeId);
}

