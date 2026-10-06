import "package:dartz/dartz.dart";
import "../../../core/errors/failures.dart";
import "../../entities/diet.dart";
import "../../repositories/i_diet_repository.dart";

class GetTraineeDietsUc {
  final IDietRepository repository;
  GetTraineeDietsUc(this.repository);
  Future<Either<Failure, List<Diet>>> call(String traineeId) =>
      repository.getDietsByTrainee(traineeId);
}

