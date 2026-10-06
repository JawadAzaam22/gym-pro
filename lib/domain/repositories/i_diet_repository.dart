import "package:dartz/dartz.dart";
import "../../core/errors/failures.dart";
import "../entities/diet.dart";
import "../entities/diet_day.dart";
import "../entities/diet_meal.dart";

abstract class IDietRepository {
  Future<Either<Failure, Diet>> createDiet(Diet diet);
  Future<Either<Failure, Diet>> updateDiet(Diet diet);
  Future<Either<Failure, void>> deactivateDiet(int id);
  Future<Either<Failure, void>> deleteDiet(int id);
  Future<Either<Failure, void>> deleteDay(int id);
  Future<Either<Failure, List<Diet>>> getDietsByTrainee(String traineeId);
  Future<Either<Failure, List<Diet>>> getDietsByTrainer(String trainerId);
  Future<Either<Failure, Diet>> getDietById(int id);
  Future<Either<Failure, DietDay>> addDay(DietDay day);
  Future<Either<Failure, DietMeal>> addMeal(DietMeal meal);
  Future<Either<Failure, List<DietDay>>> getDays(int dietId);
  Future<Either<Failure, List<DietMeal>>> getMeals(int dayId);
}
