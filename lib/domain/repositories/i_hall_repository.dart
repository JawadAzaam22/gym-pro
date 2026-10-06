import "package:dartz/dartz.dart";
import "../../core/errors/failures.dart";
import "../entities/hall.dart";
import "../entities/access_period.dart";

abstract class IHallRepository {
  Future<Either<Failure, List<Hall>>> getHalls();
  Future<Either<Failure, Hall>> getHallById(int id);
  Future<Either<Failure, Hall>> createHall(Hall hall);
  Future<Either<Failure, Hall>> updateHall(Hall hall);
  Future<Either<Failure, void>> deactivateHall(int id);
  // Access periods
  Future<Either<Failure, List<AccessPeriod>>> getAccessPeriods(int hallId);
  /// يجلب كل فترات الوصول لكل القاعات بطلب واحد (بديل N+1 عند بناء الجدول).
  Future<Either<Failure, List<AccessPeriod>>> getAllAccessPeriods();
  Future<Either<Failure, AccessPeriod>> createAccessPeriod(AccessPeriod period);
  Future<Either<Failure, AccessPeriod>> updateAccessPeriod(AccessPeriod period);
  Future<Either<Failure, void>> deleteAccessPeriod(int id);
}
