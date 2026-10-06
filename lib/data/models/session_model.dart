import "../../core/constants/enums.dart";
import "../../domain/entities/session.dart";

class SessionModel extends Session {
  const SessionModel({
    required super.id,
    required super.name,
    super.description,
    required super.hallId,
    required super.trainerId,
    super.accessPeriodId,
    required super.startDate,
    required super.endDate,
    required super.capacity,
    required super.status,
    required super.createdBy,
    required super.createdAt,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    String s = json['status'] as String;
    SessionStatus st;
    switch (s) {
      case 'cancelled':
        st = SessionStatus.cancelled;
        break;
      case 'completed':
        st = SessionStatus.completed;
        break;
      default:
        st = SessionStatus.scheduled;
    }
    return SessionModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      hallId: json['hall_id'] as int,
      trainerId: json['trainer_id'] as String?,
      accessPeriodId: json['access_period_id'] as int?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      capacity: json['capacity'] as int,
      status: st,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'hall_id': hallId,
        'trainer_id': trainerId,
        'access_period_id': accessPeriodId,
        'start_date': startDate.toIso8601String().split('T').first,
        'end_date': endDate.toIso8601String().split('T').first,
        'capacity': capacity,
        'status': status.name,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toInsertJson() {
    final j = toJson();
    j.remove('id');
    j.remove('created_at');
    return j;
  }

  factory SessionModel.fromEntity(Session e) => SessionModel(
        id: e.id,
        name: e.name,
        description: e.description,
        hallId: e.hallId,
        trainerId: e.trainerId,
        accessPeriodId: e.accessPeriodId,
        startDate: e.startDate,
        endDate: e.endDate,
        capacity: e.capacity,
        status: e.status,
        createdBy: e.createdBy,
        createdAt: e.createdAt,
      );

  Session toEntity() => Session(
        id: id,
        name: name,
        description: description,
        hallId: hallId,
        trainerId: trainerId,
        accessPeriodId: accessPeriodId,
        startDate: startDate,
        endDate: endDate,
        capacity: capacity,
        status: status,
        createdBy: createdBy,
        createdAt: createdAt,
      );
}
