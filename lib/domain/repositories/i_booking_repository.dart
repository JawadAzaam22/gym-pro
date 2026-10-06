import "package:dartz/dartz.dart";
import "../../core/errors/failures.dart";
import "../entities/booking.dart";
import "../entities/private_training_session.dart";
import "../entities/private_training_schedule.dart";
import "../entities/trainer_trainee.dart";

abstract class IBookingRepository {
  Future<Either<Failure, List<Booking>>> getBookingsBySession(int sessionId);
  Future<Either<Failure, List<Booking>>> getBookingsByTrainee(String traineeId);
  Future<Either<Failure, Booking>> bookSession(String traineeId, int sessionId);
  Future<Either<Failure, void>> cancelBooking(int bookingId);
  Future<Either<Failure, void>> deleteBooking(int id);
  Future<Either<Failure, int>> getBookingCount(int sessionId);
  Future<Either<Failure, Map<int, int>>> getBookingCounts();
  // Private training sessions (one-off)
  Future<Either<Failure, List<Map<String, dynamic>>>> getPrivateSessions();
  Future<Either<Failure, PrivateTrainingSession>> schedulePrivateSession(
      PrivateTrainingSession session);
  Future<Either<Failure, PrivateTrainingSession>> updatePrivateSession(
      int sessionId, PrivateTrainingSession session);
  Future<Either<Failure, void>> deletePrivateSession(int id);
  // Private training schedule (weekly fixed appointments)
  Future<Either<Failure, List<PrivateTrainingSchedule>>> getScheduleForTrainerTrainee(
      int trainerTraineeId);
  Future<Either<Failure, List<PrivateTrainingSchedule>>> getScheduleForTrainer(
      String trainerId);
  Future<Either<Failure, List<PrivateTrainingSchedule>>> getScheduleForTrainee(
      String traineeId);
  Future<Either<Failure, PrivateTrainingSchedule>> addScheduleSlot(
      PrivateTrainingSchedule slot);
  Future<Either<Failure, PrivateTrainingSchedule>> updateScheduleSlot(
      int id, PrivateTrainingSchedule slot);
  Future<Either<Failure, void>> deleteScheduleSlot(int id);
  // Trainer-Trainee relations
  Future<Either<Failure, List<TrainerTrainee>>> getTrainerTrainees({String? trainerId, String? traineeId});
  Future<Either<Failure, TrainerTrainee>> assignTrainer(String trainerId, String traineeId, String assignedBy);
  Future<Either<Failure, void>> deleteTrainerTraineeRelation(int id);
}
