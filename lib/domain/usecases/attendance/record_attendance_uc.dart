import "package:dartz/dartz.dart";
import "../../../core/errors/failures.dart";
import "../../entities/attendance.dart";
import "../../repositories/i_attendance_repository.dart";

class RecordAttendanceUc {
  final IAttendanceRepository repository;
  RecordAttendanceUc(this.repository);
  Future<Either<Failure, Attendance>> call(String traineeId, String method, {int? sessionId}) =>
      repository.recordAttendance(traineeId, method, sessionId: sessionId);
}

