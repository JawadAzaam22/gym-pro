import "package:dartz/dartz.dart";
import "../../core/errors/failures.dart";
import "../entities/training_program.dart";
import "../entities/program_day.dart";
import "../entities/program_exercise.dart";

abstract class IProgramRepository {
  Future<Either<Failure, TrainingProgram>> createProgram(TrainingProgram program);
  Future<Either<Failure, TrainingProgram>> updateProgram(TrainingProgram program);
  Future<Either<Failure, void>> deactivateProgram(int id);
  Future<Either<Failure, void>> deleteProgram(int id);
  Future<Either<Failure, List<TrainingProgram>>> getProgramsByTrainee(String traineeId);
  Future<Either<Failure, List<TrainingProgram>>> getProgramsByTrainer(String trainerId);
  Future<Either<Failure, TrainingProgram>> getProgramById(int id);
  // Days & Exercises
  Future<Either<Failure, ProgramDay>> addDay(ProgramDay day);
  Future<Either<Failure, ProgramExercise>> addExercise(ProgramExercise exercise);
  Future<Either<Failure, List<ProgramDay>>> getDays(int programId);
  Future<Either<Failure, List<ProgramExercise>>> getExercises(int dayId);
}
