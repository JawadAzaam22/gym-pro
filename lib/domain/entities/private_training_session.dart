import "package:equatable/equatable.dart";
import "../../core/constants/enums.dart";

class PrivateTrainingSession extends Equatable {
  final int id;
  final int? slotId;
  final int trainerTraineeId;
  final DateTime sessionDate;
  final PrivateSessionStatus status;
  final String? recordedBy;
  final DateTime createdAt;
  final String? trainerName;
  final String? traineeName;

  const PrivateTrainingSession({
    required this.id,
    this.slotId,
    required this.trainerTraineeId,
    required this.sessionDate,
    required this.status,
    this.recordedBy,
    required this.createdAt,
    this.trainerName,
    this.traineeName,
  });

  @override
  List<Object?> get props => [id, slotId, trainerTraineeId, sessionDate, status, recordedBy, createdAt, trainerName, traineeName];
}
