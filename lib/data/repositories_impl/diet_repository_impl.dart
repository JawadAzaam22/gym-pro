import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/diet.dart';
import '../../domain/entities/diet_day.dart';
import '../../domain/entities/diet_meal.dart';
import '../../domain/repositories/i_diet_repository.dart';
import '../datasources/supabase_diet_datasource.dart';
import '../models/diet_model.dart';
import '../models/diet_day_model.dart';
import '../models/diet_meal_model.dart';

class DietRepositoryImpl implements IDietRepository {
  final SupabaseDietDatasource datasource;
  DietRepositoryImpl(this.datasource);

  @override
  Future<Either<Failure, Diet>> createDiet(Diet diet) async {
    try {
      final model = DietModel.fromEntity(diet);
      final created = await datasource.createDiet(model);
      return Right(created.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deactivateDiet(int id) async {
    try {
      await datasource.deactivateDiet(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDiet(int id) async {
    try {
      await datasource.deleteDiet(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDay(int id) async {
    try {
      await datasource.deleteDay(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Diet>> getDietById(int id) async {
    try {
      final d = await datasource.getDietById(id);
      return Right(d.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Diet>>> getDietsByTrainee(String traineeId) async {
    try {
      final list = await datasource.getDietsByTrainee(traineeId);
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Diet>>> getDietsByTrainer(String trainerId) async {
    try {
      final list = await datasource.getDietsByTrainer(trainerId);
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Diet>> updateDiet(Diet diet) async {
    try {
      final model = DietModel.fromEntity(diet);
      final updated = await datasource.updateDiet(model);
      return Right(updated.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DietDay>> addDay(DietDay day) async {
    try {
      final model = DietDayModel.fromEntity(day);
      final created = await datasource.addDay(model);
      return Right(created.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DietDay>>> getDays(int dietId) async {
    try {
      final list = await datasource.getDays(dietId);
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DietMeal>> addMeal(DietMeal meal) async {
    try {
      final model = DietMealModel.fromEntity(meal);
      final created = await datasource.addMeal(model);
      return Right(created.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DietMeal>>> getMeals(int dayId) async {
    try {
      final list = await datasource.getMeals(dayId);
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
