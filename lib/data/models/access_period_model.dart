import "../../core/constants/enums.dart";
import "../../domain/entities/access_period.dart";

class AccessPeriodModel extends AccessPeriod {
  const AccessPeriodModel({
    required super.id,
    required super.hallId,
    required super.dayOfWeek,
    required super.startTime,
    required super.endTime,
    required super.accessType,
    super.trainerId,
    super.titleOrReason,
    required super.isActive,
  });

  factory AccessPeriodModel.fromJson(Map<String, dynamic> json) => AccessPeriodModel(
        id: json['id'] as int,
        hallId: json['hall_id'] as int,
        dayOfWeek: json['day_of_week'] as int,
        startTime: json['start_time'] as String,
        endTime: json['end_time'] as String,
        accessType: AccessTypeX.fromString(json['access_type'] as String),
        trainerId: json['trainer_id'] as String?,
        titleOrReason: json['title_or_reason'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'hall_id': hallId,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'access_type': accessType.toDbString(),
        'trainer_id': trainerId,
        'title_or_reason': titleOrReason,
        'is_active': isActive,
      };

  Map<String, dynamic> toInsertJson() {
    final j = toJson();
    j.remove('id');
    return j;
  }

  factory AccessPeriodModel.fromEntity(AccessPeriod e) => AccessPeriodModel(
        id: e.id,
        hallId: e.hallId,
        dayOfWeek: e.dayOfWeek,
        startTime: e.startTime,
        endTime: e.endTime,
        accessType: e.accessType,
        trainerId: e.trainerId,
        titleOrReason: e.titleOrReason,
        isActive: e.isActive,
      );

  AccessPeriod toEntity() => AccessPeriod(
        id: id,
        hallId: hallId,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        accessType: accessType,
        trainerId: trainerId,
        titleOrReason: titleOrReason,
        isActive: isActive,
      );
}
