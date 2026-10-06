import "package:equatable/equatable.dart";

class PrivateTrainingSchedule extends Equatable {
  final int id;
  final int trainerTraineeId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final String? trainerName;
  final String? traineeName;

  const PrivateTrainingSchedule({
    required this.id,
    required this.trainerTraineeId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    this.trainerName,
    this.traineeName,
  });

  @override
  List<Object?> get props => [
        id,
        trainerTraineeId,
        dayOfWeek,
        startTime,
        endTime,
        isActive,
        createdBy,
        createdAt,
        trainerName,
        traineeName,
      ];
}