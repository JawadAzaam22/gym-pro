import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/attendance.dart';
import '../entities/booking.dart';
import '../entities/diet.dart';
import '../entities/diet_day.dart';
import '../entities/diet_meal.dart';
import '../entities/private_training_schedule.dart';
import '../entities/private_training_session.dart';
import '../entities/program_day.dart';
import '../entities/program_exercise.dart';
import '../entities/training_program.dart';
import '../repositories/i_attendance_repository.dart';
import '../repositories/i_booking_repository.dart';
import '../repositories/i_diet_repository.dart';
import '../repositories/i_program_repository.dart';

class AttendanceUseCases {
  final IAttendanceRepository repository;
  const AttendanceUseCases(this.repository);

  Future<Either<Failure, List<Attendance>>> getAttendanceByTrainee(String id) =>
      repository.getAttendanceByTrainee(id);
  Future<Either<Failure, List<Attendance>>> getAllAttendance(
          {DateTime? from, DateTime? to}) =>
      repository.getAllAttendance(from: from, to: to);
}

class BookingUseCases {
  final IBookingRepository repository;
  const BookingUseCases(this.repository);

  Future<Either<Failure, List<Booking>>> getBookingsByTrainee(String id) =>
      repository.getBookingsByTrainee(id);
  Future<Either<Failure, List<Booking>>> getBookingsBySession(int id) =>
      repository.getBookingsBySession(id);
  Future<Either<Failure, int>> getBookingCount(int id) =>
      repository.getBookingCount(id);
  Future<Either<Failure, Map<int, int>>> getBookingCounts() =>
      repository.getBookingCounts();
  Future<Either<Failure, Booking>> bookSession(
          String traineeId, int sessionId) =>
      repository.bookSession(traineeId, sessionId);
  Future<Either<Failure, void>> cancelBooking(int id) =>
      repository.cancelBooking(id);
  Future<Either<Failure, void>> deleteBooking(int id) =>
      repository.deleteBooking(id);
  Future<Either<Failure, void>> deletePrivateSession(int id) =>
      repository.deletePrivateSession(id);
  Future<Either<Failure, void>> deleteTrainerTraineeRelation(int id) =>
      repository.deleteTrainerTraineeRelation(id);
  Future<Either<Failure, PrivateTrainingSchedule>> addScheduleSlot(
          PrivateTrainingSchedule slot) =>
      repository.addScheduleSlot(slot);
  Future<Either<Failure, List<PrivateTrainingSchedule>>> getScheduleForTrainer(
          String id) =>
      repository.getScheduleForTrainer(id);
  Future<Either<Failure, PrivateTrainingSession>> schedulePrivateSession(
          PrivateTrainingSession session) =>
      repository.schedulePrivateSession(session);
}

class ProgramUseCases {
  final IProgramRepository repository;
  const ProgramUseCases(this.repository);

  Future<Either<Failure, List<TrainingProgram>>> getProgramsByTrainee(
          String id) =>
      repository.getProgramsByTrainee(id);
  Future<Either<Failure, List<TrainingProgram>>> getProgramsByTrainer(
          String id) =>
      repository.getProgramsByTrainer(id);
  Future<Either<Failure, TrainingProgram>> getProgramById(int id) =>
      repository.getProgramById(id);
  Future<Either<Failure, TrainingProgram>> createProgram(
          TrainingProgram program) =>
      repository.createProgram(program);
  Future<Either<Failure, TrainingProgram>> updateProgram(
          TrainingProgram program) =>
      repository.updateProgram(program);
  Future<Either<Failure, void>> deactivateProgram(int id) =>
      repository.deactivateProgram(id);
  Future<Either<Failure, void>> deleteProgram(int id) =>
      repository.deleteProgram(id);
  Future<Either<Failure, ProgramDay>> addDay(ProgramDay day) =>
      repository.addDay(day);
  Future<Either<Failure, List<ProgramDay>>> getDays(int id) =>
      repository.getDays(id);
  Future<Either<Failure, List<ProgramExercise>>> getExercises(int id) =>
      repository.getExercises(id);
  Future<Either<Failure, ProgramExercise>> addExercise(ProgramExercise value) =>
      repository.addExercise(value);
  Future<Either<Failure, void>> deleteExercise(int id) =>
      repository.deleteExercise(id);
  Future<Either<Failure, ProgramExercise>> updateExercise(
          ProgramExercise value) =>
      repository.updateExercise(value);
}

class DietUseCases {
  final IDietRepository repository;
  const DietUseCases(this.repository);

  Future<Either<Failure, List<Diet>>> getDietsByTrainee(String id) =>
      repository.getDietsByTrainee(id);
  Future<Either<Failure, List<Diet>>> getDietsByTrainer(String id) =>
      repository.getDietsByTrainer(id);
  Future<Either<Failure, Diet>> createDiet(Diet diet) =>
      repository.createDiet(diet);
  Future<Either<Failure, Diet>> updateDiet(Diet diet) =>
      repository.updateDiet(diet);
  Future<Either<Failure, void>> deactivateDiet(int id) =>
      repository.deactivateDiet(id);
  Future<Either<Failure, void>> deleteDiet(int id) => repository.deleteDiet(id);
  Future<Either<Failure, void>> deleteDay(int id) => repository.deleteDay(id);
  Future<Either<Failure, List<DietDay>>> getDays(int id) =>
      repository.getDays(id);
  Future<Either<Failure, List<DietMeal>>> getMeals(int id) =>
      repository.getMeals(id);
}
