import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/training_program.dart';
import '../../domain/entities/program_day.dart';
import '../../domain/entities/program_exercise.dart';
import '../../domain/repositories/i_program_repository.dart';
import '../datasources/supabase_program_datasource.dart';
import '../models/training_program_model.dart';
import '../models/program_day_model.dart';
import '../models/program_exercise_model.dart';

class ProgramRepositoryImpl implements IProgramRepository {
  final SupabaseProgramDatasource datasource;
  ProgramRepositoryImpl(this.datasource);

  @override
  Future<Either<Failure, TrainingProgram>> createProgram(TrainingProgram program) async {
    try {
      final model = TrainingProgramModel.fromEntity(program);
      final created = await datasource.createProgram(model);
      return Right(created.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deactivateProgram(int id) async {
    try {
      await datasource.deactivateProgram(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProgram(int id) async {
    try {
      await datasource.deleteProgram(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TrainingProgram>> getProgramById(int id) async {
    try {
      final p = await datasource.getProgramById(id);
      return Right(p.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TrainingProgram>>> getProgramsByTrainee(String traineeId) async {
    try {
      final list = await datasource.getProgramsByTrainee(traineeId);
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TrainingProgram>>> getProgramsByTrainer(String trainerId) async {
    try {
      final list = await datasource.getProgramsByTrainer(trainerId);
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TrainingProgram>> updateProgram(TrainingProgram program) async {
    try {
      final model = TrainingProgramModel.fromEntity(program);
      final updated = await datasource.updateProgram(model);
      return Right(updated.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProgramDay>> addDay(ProgramDay day) async {
    try {
      final model = ProgramDayModel.fromEntity(day);
      final created = await datasource.addDay(model);
      return Right(created.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProgramDay>>> getDays(int programId) async {
    try {
      final list = await datasource.getDays(programId);
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProgramExercise>> addExercise(ProgramExercise exercise) async {
    try {
      final model = ProgramExerciseModel.fromEntity(exercise);
      final created = await datasource.addExercise(model);
      return Right(created.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProgramExercise>>> getExercises(int dayId) async {
    try {
      final list = await datasource.getExercises(dayId);
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
