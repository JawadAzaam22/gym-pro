import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/private_training_session.dart';
import '../../domain/entities/private_training_schedule.dart';
import '../../domain/entities/trainer_trainee.dart';
import '../../domain/repositories/i_booking_repository.dart';
import '../datasources/supabase_booking_datasource.dart';
import '../models/private_training_session_model.dart';
import '../models/private_training_schedule_model.dart';
// import '../models/trainer_trainee_model.dart'; // غير مستخدم حالياً

class BookingRepositoryImpl implements IBookingRepository {
  final SupabaseBookingDatasource datasource;
  BookingRepositoryImpl(this.datasource);

  @override
  Future<Either<Failure, List<Booking>>> getBookingsBySession(int sessionId) async {
    try {
      final list = await datasource.getBookingsBySession(sessionId);
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Booking>>> getBookingsByTrainee(String traineeId) async {
    try {
      final list = await datasource.getBookingsByTrainee(traineeId);
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Booking>> bookSession(String traineeId, int sessionId) async {
    try {
      final booking = await datasource.bookSession(traineeId, sessionId);
      return Right(booking.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelBooking(int bookingId) async {
    try {
      await datasource.cancelBooking(bookingId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getBookingCount(int sessionId) async {
    try {
      final count = await datasource.getBookingCount(sessionId);
      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<int, int>>> getBookingCounts() async {
    try {
      final counts = await datasource.getAllBookingCounts();
      return Right(counts);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPrivateSessions() async {
    try {
      final list = await datasource.getPrivateSessions();
      return Right(list.map((e) => e.toJson()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PrivateTrainingSession>> schedulePrivateSession(
      PrivateTrainingSession session) async {
    try {
      final created = await datasource
          .schedulePrivateSession(PrivateTrainingSessionModel.fromEntity(session));
      return Right(created.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PrivateTrainingSession>> updatePrivateSession(
      int sessionId, PrivateTrainingSession session) async {
    try {
      final updated = await datasource.updatePrivateSession(
        sessionId,
        PrivateTrainingSessionModel.fromEntity(session),
      );
      return Right(updated.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBooking(int id) async {
    try {
      await datasource.deleteBooking(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePrivateSession(int id) async {
    try {
      await datasource.deletePrivateSession(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTrainerTraineeRelation(int id) async {
    try {
      await datasource.deleteTrainerTraineeRelation(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TrainerTrainee>> assignTrainer(String trainerId, String traineeId, String assignedBy) async {
    try {
      final created = await datasource.assignTrainer(trainerId, traineeId, assignedBy);
      return Right(created.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TrainerTrainee>>> getTrainerTrainees({String? trainerId, String? traineeId}) async {
    try {
      final list = await datasource.getTrainerTrainees(trainerId: trainerId, traineeId: traineeId);
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PrivateTrainingSchedule>>> getScheduleForTrainerTrainee(
      int trainerTraineeId) async {
    try {
      final list = await datasource.getScheduleForTrainerTrainee(trainerTraineeId);
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PrivateTrainingSchedule>>> getScheduleForTrainer(
      String trainerId) async {
    try {
      final list = await datasource.getScheduleForTrainer(trainerId);
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PrivateTrainingSchedule>>> getScheduleForTrainee(
      String traineeId) async {
    try {
      final list = await datasource.getScheduleForTrainee(traineeId);
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PrivateTrainingSchedule>> addScheduleSlot(
      PrivateTrainingSchedule slot) async {
    try {
      final created = await datasource.addScheduleSlot(
          PrivateTrainingScheduleModel.fromEntity(slot));
      return Right(created.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PrivateTrainingSchedule>> updateScheduleSlot(
      int id, PrivateTrainingSchedule slot) async {
    try {
      final updated = await datasource.updateScheduleSlot(
          id, PrivateTrainingScheduleModel.fromEntity(slot));
      return Right(updated.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteScheduleSlot(int id) async {
    try {
      await datasource.deleteScheduleSlot(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
