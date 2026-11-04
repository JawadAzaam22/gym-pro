import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/private_training_session.dart';
import '../entities/private_training_schedule.dart';
import '../entities/trainer_trainee.dart';
import '../repositories/i_booking_repository.dart';

class GetTrainerTrainees {
  final IBookingRepository repository;

  const GetTrainerTrainees(this.repository);

  Future<Either<Failure, List<TrainerTrainee>>> call({
    String? trainerId,
    String? traineeId,
  }) =>
      repository.getTrainerTrainees(
        trainerId: trainerId,
        traineeId: traineeId,
      );
}

class GetPrivateTrainingSessions {
  final IBookingRepository repository;

  const GetPrivateTrainingSessions(this.repository);

  Future<Either<Failure, List<PrivateTrainingSession>>> call({
    int? trainerTraineeId,
  }) =>
      repository.getPrivateSessions(trainerTraineeId: trainerTraineeId);
}

class GetPrivateScheduleForRelation {
  final IBookingRepository repository;

  const GetPrivateScheduleForRelation(this.repository);

  Future<Either<Failure, List<PrivateTrainingSchedule>>> call(
          int trainerTraineeId) =>
      repository.getScheduleForTrainerTrainee(trainerTraineeId);
}

class GetPrivateScheduleForTrainer {
  final IBookingRepository repository;

  const GetPrivateScheduleForTrainer(this.repository);

  Future<Either<Failure, List<PrivateTrainingSchedule>>> call(
          String trainerId) =>
      repository.getScheduleForTrainer(trainerId);
}

class GetPrivateScheduleForTrainee {
  final IBookingRepository repository;

  const GetPrivateScheduleForTrainee(this.repository);

  Future<Either<Failure, List<PrivateTrainingSchedule>>> call(
          String traineeId) =>
      repository.getScheduleForTrainee(traineeId);
}

class DeletePrivateScheduleSlot {
  final IBookingRepository repository;

  const DeletePrivateScheduleSlot(this.repository);

  Future<Either<Failure, void>> call(int id) {
    if (id <= 0) {
      return Future.value(
        const Left(ValidationFailure('معرّف الموعد غير صالح')),
      );
    }
    return repository.deleteScheduleSlot(id);
  }
}
