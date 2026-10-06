import "package:dartz/dartz.dart";
import "../../../core/errors/failures.dart";
import "../../entities/diet.dart";
import "../../repositories/i_diet_repository.dart";

class CreateDietPlanUc {
  final IDietRepository repository;
  CreateDietPlanUc(this.repository);
  Future<Either<Failure, Diet>> call(Diet d) => repository.createDiet(d);
}

