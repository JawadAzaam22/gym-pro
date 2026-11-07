import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_pro/core/constants/enums.dart';
import 'package:gym_pro/core/errors/failures.dart';
import 'package:gym_pro/domain/entities/membership.dart';
import 'package:gym_pro/domain/repositories/i_membership_repository.dart';
import 'package:gym_pro/domain/usecases/membership_use_cases.dart';
import 'package:mocktail/mocktail.dart';

class _MembershipRepositoryMock extends Mock implements IMembershipRepository {}

Membership _membership({
  String traineeId = 'trainee-1',
  DateTime? startDate,
  DateTime? endDate,
}) {
  return Membership(
    id: 0,
    traineeId: traineeId,
    startDate: startDate ?? DateTime(2026, 1, 1),
    endDate: endDate ?? DateTime(2026, 2, 1),
    status: MembershipStatus.active,
    recordedBy: 'staff-1',
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_membership());
  });

  test('CreateMembership rejects an invalid date range without repository call',
      () async {
    final repository = _MembershipRepositoryMock();

    final result = await CreateMembership(repository).call(
      _membership(endDate: DateTime(2025, 12, 31)),
    );

    expect(result, isA<Left<Failure, Membership>>());
    final failure = result.fold(
        (failure) => failure, (_) => throw StateError('missing failure'));
    expect(failure, isA<ValidationFailure>());
    verifyNever(() => repository.createMembership(any()));
  });

  test('CreateMembership delegates valid memberships', () async {
    final repository = _MembershipRepositoryMock();
    final membership = _membership();
    when(() => repository.createMembership(membership))
        .thenAnswer((_) async => Right(membership));

    final result = await CreateMembership(repository).call(membership);

    expect(result, Right(membership));
    verify(() => repository.createMembership(membership)).called(1);
  });

  test('DeleteMembership rejects non-positive IDs', () async {
    final repository = _MembershipRepositoryMock();

    final result = await DeleteMembership(repository).call(0);

    expect(result, isA<Left<Failure, void>>());
    verifyNever(() => repository.deleteMembership(any()));
  });
}
