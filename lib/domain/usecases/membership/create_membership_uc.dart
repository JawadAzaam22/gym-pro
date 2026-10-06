import "package:dartz/dartz.dart";
import "../../../core/errors/failures.dart";
import "../../entities/membership.dart";
import "../../repositories/i_membership_repository.dart";

class CreateMembershipUc {
  final IMembershipRepository repository;
  CreateMembershipUc(this.repository);
  Future<Either<Failure, Membership>> call(Membership m) =>
      repository.createMembership(m);
}

