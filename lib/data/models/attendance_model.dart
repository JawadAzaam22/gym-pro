import "../../core/constants/enums.dart";
import "../../domain/entities/attendance.dart";

class AttendanceModel extends Attendance {
  const AttendanceModel({required super.id, required super.traineeId, required super.checkInTime, required super.method, super.sessionId});

  factory AttendanceModel.fromJson(Map<String, dynamic> json) => AttendanceModel(
        id: json['id'] as int,
        traineeId: json['trainee_id'] as String,
        checkInTime: DateTime.parse(json['check_in_time'] as String),
        method: json['method'] == 'manual' ? AttendanceMethod.manual : AttendanceMethod.qr,
        sessionId: json['session_id'] as int?,
      );

  Map<String, dynamic> toJson() => {'id': id, 'trainee_id': traineeId, 'check_in_time': checkInTime.toIso8601String(), 'method': method.name, 'session_id': sessionId};
  Map<String, dynamic> toInsertJson() {
    final j = toJson();
    j.remove('id');
    return j;
  }

  factory AttendanceModel.fromEntity(Attendance e) => AttendanceModel(id: e.id, traineeId: e.traineeId, checkInTime: e.checkInTime, method: e.method, sessionId: e.sessionId);
  Attendance toEntity() => Attendance(id: id, traineeId: traineeId, checkInTime: checkInTime, method: method, sessionId: sessionId);
}
