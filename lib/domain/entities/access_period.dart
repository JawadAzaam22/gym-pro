import "package:equatable/equatable.dart";
import "../../core/constants/enums.dart";

class AccessPeriod extends Equatable {
  final int id;
  final int hallId;
  final int dayOfWeek; // 1=????? .. 7=?????
  final String startTime; // TIME e.g. "08:00:00"
  final String endTime;
  final AccessType accessType;
  final String? trainerId;
  final String? titleOrReason;
  final bool isActive;

  const AccessPeriod({
    required this.id,
    required this.hallId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.accessType,
    this.trainerId,
    this.titleOrReason,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, hallId, dayOfWeek, startTime, endTime, accessType, trainerId, titleOrReason, isActive];
}
