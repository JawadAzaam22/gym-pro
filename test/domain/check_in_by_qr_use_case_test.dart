import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_pro/core/constants/enums.dart';
import 'package:gym_pro/core/errors/failures.dart';
import 'package:gym_pro/domain/entities/attendance.dart';
import 'package:gym_pro/domain/entities/qr_check_in.dart';
import 'package:gym_pro/domain/repositories/i_attendance_repository.dart';
import 'package:gym_pro/domain/usecases/attendance_use_cases.dart';
import 'package:mocktail/mocktail.dart';

class _AttendanceRepositoryMock extends Mock
    implements IAttendanceRepository {}

QrCheckIn _result() => QrCheckIn(
      attendance: Attendance(
        id: 1,
        traineeId: 'trainee-1',
        checkInTime: DateTime(2026, 1, 1, 10),
        method: AttendanceMethod.qr,
      ),
      traineeName: 'Test Trainee',
    );

void main() {
  late _AttendanceRepositoryMock repository;
  late CheckInByQrCode useCase;

  setUp(() {
    repository = _AttendanceRepositoryMock();
    useCase = CheckInByQrCode(repository);
  });

  test('rejects payloads without the gympro_qr_v1 prefix or token', () async {
    final noPrefix = await useCase.call('trainee_pending');
    final empty = await useCase.call('   ');
    final emptyToken = await useCase.call('gympro_qr_v1:');

    expect(noPrefix, isA<Left<Failure, QrCheckIn>>());
    expect(empty, isA<Left<Failure, QrCheckIn>>());
    expect(emptyToken, isA<Left<Failure, QrCheckIn>>());
    verifyNever(
        () => repository.checkInByQr(any(), sessionId: any(named: 'sessionId')));
  });

  test('rejects a non-positive session id', () async {
    final result = await useCase.call('gympro_qr_v1:abc', sessionId: 0);

    expect(result, isA<Left<Failure, QrCheckIn>>());
    verifyNever(
        () => repository.checkInByQr(any(), sessionId: any(named: 'sessionId')));
  });

  test('delegates a valid, trimmed token to the repository', () async {
    when(() => repository.checkInByQr('gympro_qr_v1:abc',
            sessionId: any(named: 'sessionId')))
        .thenAnswer((_) async => Right(_result()));

    final result = await useCase.call('  gympro_qr_v1:abc  ');

    expect(result.isRight(), isTrue);
    verify(() => repository.checkInByQr('gympro_qr_v1:abc', sessionId: null))
        .called(1);
  });

  test('propagates repository failures unchanged', () async {
    final expired = MembershipExpiredFailure('expired', DateTime(2026, 1, 1));
    when(() => repository.checkInByQr(any(),
        sessionId: any(named: 'sessionId'))).thenAnswer((_) async => Left(expired));

    final result = await useCase.call('gympro_qr_v1:abc');

    expect(result, Left<Failure, QrCheckIn>(expired));
  });
}
