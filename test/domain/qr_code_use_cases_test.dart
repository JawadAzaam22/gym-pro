import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_pro/core/constants/enums.dart';
import 'package:gym_pro/core/errors/failures.dart';
import 'package:gym_pro/domain/entities/user.dart';
import 'package:gym_pro/domain/repositories/i_user_repository.dart';
import 'package:gym_pro/domain/usecases/attendance_use_cases.dart';
import 'package:mocktail/mocktail.dart';

class _UserRepositoryMock extends Mock implements IUserRepository {}

User _user({UserRole role = UserRole.trainee}) => User(
      id: 'user-1',
      name: 'Test User',
      phone: '000',
      email: 'test@example.com',
      role: role,
      gender: Gender.male,
      isActive: true,
      createdAt: DateTime(2026),
    );

void main() {
  test('ResolveTraineeQrCode rejects pending and malformed payloads', () async {
    final repository = _UserRepositoryMock();
    final useCase = ResolveTraineeQrCode(repository);

    final pending = await useCase.call('trainee_pending');
    final malformed = await useCase.call('   ');

    expect(pending, isA<Left<Failure, User>>());
    expect(malformed, isA<Left<Failure, User>>());
    verifyNever(() => repository.resolveTraineeQrToken(any()));
  });

  test('ResolveTraineeQrCode rejects users that are not trainees', () async {
    final repository = _UserRepositoryMock();
    when(() => repository.resolveTraineeQrToken('gympro_qr_v1:token'))
        .thenAnswer((_) async => Right(_user(role: UserRole.trainer)));

    final result =
        await ResolveTraineeQrCode(repository).call('gympro_qr_v1:token');

    expect(result, isA<Left<Failure, User>>());
    verify(() => repository.resolveTraineeQrToken('gympro_qr_v1:token'))
        .called(1);
  });
}
