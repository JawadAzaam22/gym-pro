import "../../core/constants/enums.dart";
import "../../domain/entities/trainer_trainee.dart";

class TrainerTraineeModel extends TrainerTrainee {
  const TrainerTraineeModel({
    required super.id,
    required super.trainerId,
    required super.traineeId,
    required super.status,
    required super.assignedAt,
    required super.assignedBy,
    super.trainerName,
    super.traineeName,
  });

  factory TrainerTraineeModel.fromJson(Map<String, dynamic> json) {
    return TrainerTraineeModel(
      id: json['id'] as int,
      trainerId: json['trainer_id'] as String,
      traineeId: json['trainee_id'] as String,
      status: json['status'] == 'inactive'
          ? TrainerTraineeStatus.inactive
          : TrainerTraineeStatus.active,
      assignedAt: DateTime.parse(json['assigned_at'] as String),
      assignedBy: json['assigned_by'] as String?,
      trainerName: json['trainer'] is Map
          ? json['trainer']['name'] as String?
          : null,
      traineeName: json['trainee'] is Map
          ? json['trainee']['name'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trainer_id': trainerId,
        'trainee_id': traineeId,
        'status': status.name,
        'assigned_at': assignedAt.toIso8601String(),
        'assigned_by': assignedBy,
        if (trainerName != null) 'trainer_name': trainerName,
        if (traineeName != null) 'trainee_name': traineeName,
      };

  Map<String, dynamic> toInsertJson() {
    final j = toJson();
    j.remove('id');
    j.remove('assigned_at');
    return j;
  }

  factory TrainerTraineeModel.fromEntity(TrainerTrainee e) =>
      TrainerTraineeModel(
        id: e.id,
        trainerId: e.trainerId,
        traineeId: e.traineeId,
        status: e.status,
        assignedAt: e.assignedAt,
        assignedBy: e.assignedBy,
        trainerName: e.trainerName,
        traineeName: e.traineeName,
      );

  TrainerTrainee toEntity() => TrainerTrainee(
        id: id,
        trainerId: trainerId,
        traineeId: traineeId,
        status: status,
        assignedAt: assignedAt,
        assignedBy: assignedBy,
        trainerName: trainerName,
        traineeName: traineeName,
      );
}