import "package:dartz/dartz.dart";
import "../../../core/errors/failures.dart";
import "../../entities/training_program.dart";
import "../../repositories/i_program_repository.dart";

class GetTraineeProgramsUc {
  final IProgramRepository repository;
  GetTraineeProgramsUc(this.repository);
  Future<Either<Failure, List<TrainingProgram>>> call(String traineeId) =>
      repository.getProgramsByTrainee(traineeId);
}

