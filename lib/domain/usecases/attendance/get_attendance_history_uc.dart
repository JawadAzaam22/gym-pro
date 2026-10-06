import "package:dartz/dartz.dart";
import "../../../core/errors/failures.dart";
import "../../entities/attendance.dart";
import "../../repositories/i_attendance_repository.dart";

class GetAttendanceHistoryUc {
  final IAttendanceRepository repository;
  GetAttendanceHistoryUc(this.repository);
  Future<Either<Failure, List<Attendance>>> call(String traineeId) =>
      repository.getAttendanceByTrainee(traineeId);
}

