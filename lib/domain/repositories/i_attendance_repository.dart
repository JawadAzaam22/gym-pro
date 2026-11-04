import "package:dartz/dartz.dart";
import "../../core/errors/failures.dart";
import "../entities/attendance.dart";
import "../entities/qr_check_in.dart";

abstract class IAttendanceRepository {
  Future<Either<Failure, Attendance>> recordAttendance(
      String traineeId, String method,
      {int? sessionId});
  Future<Either<Failure, QrCheckIn>> checkInByQr(String token,
      {int? sessionId});
  Future<Either<Failure, List<Attendance>>> getAttendanceByTrainee(
      String traineeId);
  Future<Either<Failure, List<Attendance>>> getAllAttendance(
      {DateTime? from, DateTime? to});
  Stream<List<Attendance>> watchAttendance();
}
