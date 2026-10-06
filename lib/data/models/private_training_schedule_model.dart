import "../../domain/entities/private_training_schedule.dart";

class PrivateTrainingScheduleModel extends PrivateTrainingSchedule {
  const PrivateTrainingScheduleModel({
    required super.id,
    required super.trainerTraineeId,
    required super.dayOfWeek,
    required super.startTime,
    required super.endTime,
    required super.isActive,
    required super.createdBy,
    required super.createdAt,
    super.trainerName,
    super.traineeName,
  });

  factory PrivateTrainingScheduleModel.fromJson(Map<String, dynamic> json) {
    // نفس ملاحظة PrivateTrainingSessionModel: الاسم قد يصل متداخلاً تحت
    // trainer_trainees بدل أن يكون حقلاً علويًا، وكانت القراءة القديمة
    // تتجاهل هذه الحالة فتُرجع null دائمًا وتظهر الأرقام بدل الأسماء.
    final nestedRel = json['trainer_trainees'];
    final trainerMap = json['trainer'] is Map
        ? json['trainer']
        : (nestedRel is Map ? nestedRel['trainer'] : null);
    final traineeMap = json['trainee'] is Map
        ? json['trainee']
        : (nestedRel is Map ? nestedRel['trainee'] : null);
    return PrivateTrainingScheduleModel(
      id: json['id'] as int,
      trainerTraineeId: json['trainer_trainee_id'] as int,
      dayOfWeek: json['day_of_week'] as int,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      isActive: json['is_active'] as bool,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      trainerName: trainerMap is Map ? trainerMap['name'] as String? : null,
      traineeName: traineeMap is Map ? traineeMap['name'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trainer_trainee_id': trainerTraineeId,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'is_active': isActive,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        if (trainerName != null) 'trainer_name': trainerName,
        if (traineeName != null) 'trainee_name': traineeName,
      };

  Map<String, dynamic> toInsertJson() {
    final j = toJson();
    j.remove('id');
    j.remove('created_at');
    return j;
  }

  factory PrivateTrainingScheduleModel.fromEntity(PrivateTrainingSchedule e) =>
      PrivateTrainingScheduleModel(
        id: e.id,
        trainerTraineeId: e.trainerTraineeId,
        dayOfWeek: e.dayOfWeek,
        startTime: e.startTime,
        endTime: e.endTime,
        isActive: e.isActive,
        createdBy: e.createdBy,
        createdAt: e.createdAt,
        trainerName: e.trainerName,
        traineeName: e.traineeName,
      );

  PrivateTrainingSchedule toEntity() => PrivateTrainingSchedule(
        id: id,
        trainerTraineeId: trainerTraineeId,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        isActive: isActive,
        createdBy: createdBy,
        createdAt: createdAt,
        trainerName: trainerName,
        traineeName: traineeName,
      );
}