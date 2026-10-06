import "package:equatable/equatable.dart";
import "../../core/constants/enums.dart";

class TrainerTrainee extends Equatable {
  final int id;
  final String trainerId;
  final String traineeId;
  final TrainerTraineeStatus status;
  final DateTime assignedAt;
  final String? assignedBy;
  final String? trainerName;
  final String? traineeName;

  const TrainerTrainee({
    required this.id,
    required this.trainerId,
    required this.traineeId,
    required this.status,
    required this.assignedAt,
    this.assignedBy,
    this.trainerName,
    this.traineeName,
  });

  @override
  List<Object?> get props => [id, trainerId, traineeId, status, assignedAt, assignedBy, trainerName, traineeName];
}
