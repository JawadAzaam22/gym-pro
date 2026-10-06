import "package:dartz/dartz.dart";
import "../../../core/errors/failures.dart";
import "../../entities/membership.dart";
import "../../repositories/i_membership_repository.dart";

class RenewMembershipUc {
  final IMembershipRepository repository;
  RenewMembershipUc(this.repository);
  Future<Either<Failure, Membership>> call(String traineeId, DateTime newEndDate, String recordedBy) =>
      repository.renewMembership(traineeId, newEndDate, recordedBy);
}

