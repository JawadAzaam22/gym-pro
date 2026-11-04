import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/access_period.dart';
import '../entities/hall.dart';
import '../repositories/i_hall_repository.dart';

class HallUseCases {
  final IHallRepository repository;
  const HallUseCases(this.repository);

  Future<Either<Failure, List<Hall>>> getHalls() => repository.getHalls();
  Future<Either<Failure, Hall>> getHallById(int id) =>
      repository.getHallById(id);
  Future<Either<Failure, Hall>> createHall(Hall hall) =>
      repository.createHall(hall);
  Future<Either<Failure, Hall>> updateHall(Hall hall) =>
      repository.updateHall(hall);
  Future<Either<Failure, void>> deactivateHall(int id) =>
      repository.deactivateHall(id);
  Future<Either<Failure, List<AccessPeriod>>> getAccessPeriods(int hallId) =>
      repository.getAccessPeriods(hallId);
  Future<Either<Failure, List<AccessPeriod>>> getAllAccessPeriods() =>
      repository.getAllAccessPeriods();
  Future<Either<Failure, AccessPeriod>> createAccessPeriod(
          AccessPeriod period) =>
      repository.createAccessPeriod(period);
  Future<Either<Failure, AccessPeriod>> updateAccessPeriod(
          AccessPeriod period) =>
      repository.updateAccessPeriod(period);
  Future<Either<Failure, void>> deleteAccessPeriod(int id) =>
      repository.deleteAccessPeriod(id);
}
