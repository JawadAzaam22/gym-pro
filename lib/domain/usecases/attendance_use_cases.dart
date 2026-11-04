import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/constants/enums.dart';
import '../entities/attendance.dart';
import '../entities/qr_check_in.dart';
import '../entities/user.dart';
import '../repositories/i_attendance_repository.dart';
import '../repositories/i_user_repository.dart';

class RecordAttendance {
  final IAttendanceRepository repository;

  const RecordAttendance(this.repository);

  Future<Either<Failure, Attendance>> call({
    required String traineeId,
    required String method,
    int? sessionId,
  }) {
    if (traineeId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('معرّف المتدرب غير صالح')),
      );
    }
    if (method.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('طريقة تسجيل الحضور مطلوبة')),
      );
    }
    if (sessionId != null && sessionId <= 0) {
      return Future.value(
        const Left(ValidationFailure('رقم الحصة غير صالح')),
      );
    }
    return repository.recordAttendance(
      traineeId,
      method,
      sessionId: sessionId,
    );
  }
}

class GetAttendanceForTrainee {
  final IAttendanceRepository repository;

  const GetAttendanceForTrainee(this.repository);

  Future<Either<Failure, List<Attendance>>> call(String traineeId) {
    if (traineeId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('معرّف المتدرب غير صالح')),
      );
    }

    return repository.getAttendanceByTrainee(traineeId);
  }
}

class GetAllAttendance {
  final IAttendanceRepository repository;

  const GetAllAttendance(this.repository);

  Future<Either<Failure, List<Attendance>>> call({
    DateTime? from,
    DateTime? to,
  }) =>
      repository.getAllAttendance(from: from, to: to);
}

/// Superseded by [CheckInByQrCode]: resolving a token does not consume it.
/// Kept only for the existing tests and until the RPC is dropped server-side.
class ResolveTraineeQrCode {
  final IUserRepository repository;

  const ResolveTraineeQrCode(this.repository);

  Future<Either<Failure, User>> call(String rawCode) {
    final raw = rawCode.trim();
    if (!raw.startsWith('gympro_qr_v1:') ||
        raw.substring('gympro_qr_v1:'.length).isEmpty) {
      return Future.value(
        const Left(ValidationFailure('رمز المتدرب غير صالح')),
      );
    }
    return repository.resolveTraineeQrToken(raw).then(
          (result) => result.fold(
            (failure) => Left(failure),
            (user) => user.role == UserRole.trainee
                ? Right(user)
                : const Left(ValidationFailure('رمز المستخدم لا يخص متدربًا')),
          ),
        );
  }
}

/// Single-use QR check-in: validates the payload shape locally, then lets the
/// database consume the token and record attendance atomically.
class CheckInByQrCode {
  final IAttendanceRepository repository;

  const CheckInByQrCode(this.repository);

  Future<Either<Failure, QrCheckIn>> call(String rawCode, {int? sessionId}) {
    final raw = rawCode.trim();
    if (!raw.startsWith('gympro_qr_v1:') ||
        raw.substring('gympro_qr_v1:'.length).isEmpty) {
      return Future.value(
        const Left(ValidationFailure('رمز المتدرب غير صالح')),
      );
    }
    if (sessionId != null && sessionId <= 0) {
      return Future.value(
        const Left(ValidationFailure('رقم الحصة غير صالح')),
      );
    }
    return repository.checkInByQr(raw, sessionId: sessionId);
  }
}
