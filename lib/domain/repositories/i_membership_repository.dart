import "package:dartz/dartz.dart";
import "../../core/errors/failures.dart";
import "../entities/membership.dart";

abstract class IMembershipRepository {
  Future<Either<Failure, List<Membership>>> getMembershipsByTrainee(String traineeId);
  Future<Either<Failure, Membership?>> getActiveMembership(String traineeId);
  Future<Either<Failure, Membership?>> getLatestMembership(String traineeId);
  Future<Either<Failure, Membership>> createMembership(Membership membership);
  Future<Either<Failure, Membership>> renewMembership(String traineeId, DateTime newEndDate, String recordedBy);
  Future<Either<Failure, List<Membership>>> getAllMemberships();
  Future<Either<Failure, Membership>> checkStatus(String traineeId);
  Future<Either<Failure, void>> deleteMembership(int id);
}
