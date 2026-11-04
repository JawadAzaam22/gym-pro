import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/membership.dart';
import '../repositories/i_membership_repository.dart';

class CreateMembership {
  final IMembershipRepository repository;

  const CreateMembership(this.repository);

  Future<Either<Failure, Membership>> call(Membership membership) {
    if (membership.traineeId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('معرّف المتدرب مطلوب')),
      );
    }
    if (!membership.endDate.isAfter(membership.startDate)) {
      return Future.value(
        const Left(ValidationFailure(
          'تاريخ الانتهاء يجب أن يكون بعد تاريخ البداية',
        )),
      );
    }
    return repository.createMembership(membership);
  }
}

class RenewMembership {
  final IMembershipRepository repository;

  const RenewMembership(this.repository);

  Future<Either<Failure, Membership>> call({
    required String traineeId,
    required DateTime newEndDate,
    required String recordedBy,
  }) {
    if (traineeId.trim().isEmpty || recordedBy.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('بيانات تجديد العضوية غير مكتملة')),
      );
    }
    return repository.renewMembership(traineeId, newEndDate, recordedBy);
  }
}

class DeleteMembership {
  final IMembershipRepository repository;

  const DeleteMembership(this.repository);

  Future<Either<Failure, void>> call(int membershipId) {
    if (membershipId <= 0) {
      return Future.value(
        const Left(ValidationFailure('معرّف العضوية غير صالح')),
      );
    }

    return repository.deleteMembership(membershipId);
  }
}

class MembershipQueries {
  final IMembershipRepository repository;

  const MembershipQueries(this.repository);

  Future<Either<Failure, List<Membership>>> getMembershipsByTrainee(
          String traineeId) =>
      repository.getMembershipsByTrainee(traineeId);
  Future<Either<Failure, Membership?>> getActiveMembership(String traineeId) =>
      repository.getActiveMembership(traineeId);
  Future<Either<Failure, Membership?>> getLatestMembership(String traineeId) =>
      repository.getLatestMembership(traineeId);
  Future<Either<Failure, List<Membership>>> getAllMemberships() =>
      repository.getAllMemberships();
  Future<Either<Failure, Membership>> checkStatus(String traineeId) =>
      repository.checkStatus(traineeId);
  Future<Either<Failure, void>> deleteMembership(int id) =>
      repository.deleteMembership(id);
}
