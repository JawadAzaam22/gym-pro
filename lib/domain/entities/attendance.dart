import "package:equatable/equatable.dart";
import "../../core/constants/enums.dart";

class Attendance extends Equatable {
  final int id;
  final String traineeId;
  final DateTime checkInTime;
  final AttendanceMethod method;
  final int? sessionId;

  const Attendance({
    required this.id,
    required this.traineeId,
    required this.checkInTime,
    required this.method,
    this.sessionId,
  });

  @override
  List<Object?> get props => [id, traineeId, checkInTime, method, sessionId];
}
