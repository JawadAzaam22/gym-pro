import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/diet_day.dart';
import '../entities/diet_meal.dart';
import '../repositories/i_diet_repository.dart';

class DietContentUseCases {
  final IDietRepository repository;

  const DietContentUseCases(this.repository);

  Future<Either<Failure, List<DietDay>>> getDays(int dietId) =>
      repository.getDays(dietId);
  Future<Either<Failure, List<DietMeal>>> getMeals(int dayId) =>
      repository.getMeals(dayId);
  Future<Either<Failure, DietDay>> addDay(DietDay day) =>
      repository.addDay(day);
  Future<Either<Failure, void>> deleteDay(int id) => repository.deleteDay(id);
  Future<Either<Failure, DietMeal>> addMeal(DietMeal meal) =>
      repository.addMeal(meal);
  Future<Either<Failure, void>> deleteMeal(int id) => repository.deleteMeal(id);
  Future<Either<Failure, DietMeal>> updateMeal(DietMeal meal) =>
      repository.updateMeal(meal);
}
