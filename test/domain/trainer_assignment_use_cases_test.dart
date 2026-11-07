import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_pro/core/constants/enums.dart';
import 'package:gym_pro/core/errors/failures.dart';
import 'package:gym_pro/domain/entities/trainer_trainee.dart';
import 'package:gym_pro/domain/repositories/i_booking_repository.dart';
import 'package:gym_pro/domain/usecases/trainer_assignment_use_cases.dart';
import 'package:mocktail/mocktail.dart';

class _BookingRepositoryMock extends Mock implements IBookingRepository {}

void main() {
  test('AssignTrainer rejects incomplete identifiers', () async {
    final repository = _BookingRepositoryMock();

    final result = await AssignTrainer(repository).call(
      trainerId: '',
      traineeId: 'trainee-1',
      assignedBy: 'staff-1',
    );

    expect(result, isA<Left<Failure, TrainerTrainee>>());
    final failure = result.fold(
        (failure) => failure, (_) => throw StateError('missing failure'));
    expect(failure, isA<ValidationFailure>());
    verifyNever(() => repository.assignTrainer(any(), any(), any()));
  });

  test('ChangeTrainerAssignment delegates valid input', () async {
    final repository = _BookingRepositoryMock();
    final assignment = TrainerTrainee(
      id: 3,
      trainerId: 'trainer-2',
      traineeId: 'trainee-1',
      status: TrainerTraineeStatus.active,
      assignedAt: DateTime(2026, 1, 1),
    );
    when(() => repository.changeTrainerAssignment(3, 'trainer-2'))
        .thenAnswer((_) async => Right(assignment));

    final result = await ChangeTrainerAssignment(repository).call(
      assignmentId: 3,
      newTrainerId: 'trainer-2',
    );

    expect(result, Right(assignment));
    verify(() => repository.changeTrainerAssignment(3, 'trainer-2')).called(1);
  });

  test('DeactivateTrainerAssignment rejects invalid IDs', () async {
    final repository = _BookingRepositoryMock();

    final result = await DeactivateTrainerAssignment(repository).call(-1);

    expect(result, isA<Left<Failure, void>>());
    verifyNever(() => repository.deactivateTrainerAssignment(any()));
  });
}
