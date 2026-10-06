import "package:dartz/dartz.dart";
import "../../../core/errors/failures.dart";
import "../../entities/training_program.dart";
import "../../repositories/i_program_repository.dart";

class CreateTrainingProgramUc {
  final IProgramRepository repository;
  CreateTrainingProgramUc(this.repository);
  Future<Either<Failure, TrainingProgram>> call(TrainingProgram p) =>
      repository.createProgram(p);
}

