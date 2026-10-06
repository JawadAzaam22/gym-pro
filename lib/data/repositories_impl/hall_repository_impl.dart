import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/hall.dart';
import '../../domain/entities/access_period.dart';
import '../../domain/repositories/i_hall_repository.dart';
import '../datasources/supabase_hall_datasource.dart';
import '../models/hall_model.dart';
import '../models/access_period_model.dart';

class HallRepositoryImpl implements IHallRepository {
  final SupabaseHallDatasource datasource;
  HallRepositoryImpl(this.datasource);

  @override
  Future<Either<Failure, List<Hall>>> getHalls() async {
    try {
      final list = await datasource.getHalls();
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Hall>> getHallById(int id) async {
    try {
      final hall = await datasource.getHallById(id);
      return Right(hall.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Hall>> createHall(Hall hall) async {
    try {
      final model = HallModel.fromEntity(hall);
      final created = await datasource.createHall(model);
      return Right(created.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Hall>> updateHall(Hall hall) async {
    try {
      final model = HallModel.fromEntity(hall);
      final updated = await datasource.updateHall(model);
      return Right(updated.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deactivateHall(int id) async {
    try {
      await datasource.deactivateHall(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AccessPeriod>>> getAccessPeriods(int hallId) async {
    try {
      final list = await datasource.getAccessPeriods(hallId);
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AccessPeriod>>> getAllAccessPeriods() async {
    try {
      final list = await datasource.getAllAccessPeriods();
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AccessPeriod>> createAccessPeriod(AccessPeriod period) async {
    try {
      final model = AccessPeriodModel.fromEntity(period);
      final created = await datasource.createAccessPeriod(model);
      return Right(created.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AccessPeriod>> updateAccessPeriod(AccessPeriod period) async {
    try {
      final model = AccessPeriodModel.fromEntity(period);
      final updated = await datasource.updateAccessPeriod(model);
      return Right(updated.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccessPeriod(int id) async {
    try {
      await datasource.deleteAccessPeriod(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
