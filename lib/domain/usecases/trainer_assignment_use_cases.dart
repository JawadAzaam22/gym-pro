import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/trainer_trainee.dart';
import '../repositories/i_booking_repository.dart';

class AssignTrainer {
  final IBookingRepository repository;

  const AssignTrainer(this.repository);

  Future<Either<Failure, TrainerTrainee>> call({
    required String trainerId,
    required String traineeId,
    required String assignedBy,
  }) {
    if (trainerId.trim().isEmpty ||
        traineeId.trim().isEmpty ||
        assignedBy.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('بيانات تعيين المدرب غير مكتملة')),
      );
    }
    return repository.assignTrainer(trainerId, traineeId, assignedBy);
  }
}

class ChangeTrainerAssignment {
  final IBookingRepository repository;

  const ChangeTrainerAssignment(this.repository);

  Future<Either<Failure, TrainerTrainee>> call({
    required int assignmentId,
    required String newTrainerId,
  }) {
    if (assignmentId <= 0 || newTrainerId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('بيانات تغيير المدرب غير صالحة')),
      );
    }
    return repository.changeTrainerAssignment(assignmentId, newTrainerId);
  }
}

class DeactivateTrainerAssignment {
  final IBookingRepository repository;

  const DeactivateTrainerAssignment(this.repository);

  Future<Either<Failure, void>> call(int assignmentId) {
    if (assignmentId <= 0) {
      return Future.value(
        const Left(ValidationFailure('معرّف التعيين غير صالح')),
      );
    }
    return repository.deactivateTrainerAssignment(assignmentId);
  }
}
