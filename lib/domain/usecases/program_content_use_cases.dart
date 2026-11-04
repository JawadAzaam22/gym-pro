import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/program_day.dart';
import '../entities/program_exercise.dart';
import '../repositories/i_program_repository.dart';

class ProgramContentUseCases {
  final IProgramRepository repository;

  const ProgramContentUseCases(this.repository);

  Future<Either<Failure, List<ProgramDay>>> getDays(int programId) =>
      repository.getDays(programId);
  Future<Either<Failure, List<ProgramExercise>>> getExercises(int dayId) =>
      repository.getExercises(dayId);
  Future<Either<Failure, ProgramDay>> addDay(ProgramDay day) =>
      repository.addDay(day);
  Future<Either<Failure, void>> deleteDay(int id) => repository.deleteDay(id);
  Future<Either<Failure, ProgramExercise>> addExercise(ProgramExercise ex) =>
      repository.addExercise(ex);
  Future<Either<Failure, void>> deleteExercise(int id) =>
      repository.deleteExercise(id);
  Future<Either<Failure, ProgramExercise>> updateExercise(ProgramExercise ex) =>
      repository.updateExercise(ex);
}
