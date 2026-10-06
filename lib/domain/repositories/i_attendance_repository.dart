import "package:dartz/dartz.dart";
import "../../core/errors/failures.dart";
import "../entities/attendance.dart";

abstract class IAttendanceRepository {
  Future<Either<Failure, Attendance>> recordAttendance(String traineeId, String method, {int? sessionId});
  Future<Either<Failure, List<Attendance>>> getAttendanceByTrainee(String traineeId);
  Future<Either<Failure, List<Attendance>>> getAllAttendance({DateTime? from, DateTime? to});
  Stream<List<Attendance>> watchAttendance();
}
