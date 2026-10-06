import "../../core/constants/enums.dart";
import "../../domain/entities/private_training_session.dart";

class PrivateTrainingSessionModel extends PrivateTrainingSession {
  const PrivateTrainingSessionModel({
    required super.id,
    super.slotId,
    required super.trainerTraineeId,
    required super.sessionDate,
    required super.status,
    required super.recordedBy,
    required super.createdAt,
    super.trainerName,
    super.traineeName,
  });

  factory PrivateTrainingSessionModel.fromJson(Map<String, dynamic> json) {
    String s = json['status'] as String;
    PrivateSessionStatus st;
    switch (s) {
      case 'cancelled':
        st = PrivateSessionStatus.cancelled;
        break;
      case 'completed':
        st = PrivateSessionStatus.completed;
        break;
      default:
        st = PrivateSessionStatus.scheduled;
    }
    // اسم المدرب/المتدرب قد يصل بشكلين حسب الاستعلام:
    // 1) مباشرة كحقول علوية: json['trainer'] / json['trainee']
    // 2) متداخلة تحت العلاقة: json['trainer_trainees']['trainer' | 'trainee']
    //    (هذا هو الشكل الفعلي القادم من استعلامات getPrivateSessions وما شابه،
    //    وكان يُقرأ خطأً من المستوى العلوي فيظهر دائمًا null فيعرض الـ id الخام
    //    بدل الاسم في الواجهة).
    final nestedRel = json['trainer_trainees'];
    final trainerMap = json['trainer'] is Map
        ? json['trainer']
        : (nestedRel is Map ? nestedRel['trainer'] : null);
    final traineeMap = json['trainee'] is Map
        ? json['trainee']
        : (nestedRel is Map ? nestedRel['trainee'] : null);
    return PrivateTrainingSessionModel(
      id: json['id'] as int,
      slotId: json['slot_id'] as int?,
      trainerTraineeId: json['trainer_trainee_id'] as int,
      sessionDate: DateTime.parse(json['session_date'] as String),
      status: st,
      recordedBy: json['recorded_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      trainerName: trainerMap is Map ? trainerMap['name'] as String? : null,
      traineeName: traineeMap is Map ? traineeMap['name'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slot_id': slotId,
        'trainer_trainee_id': trainerTraineeId,
        'session_date': sessionDate.toIso8601String(),
        'status': status.name,
        'recorded_by': recordedBy,
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

  factory PrivateTrainingSessionModel.fromEntity(PrivateTrainingSession e) =>
      PrivateTrainingSessionModel(
          id: e.id,
          slotId: e.slotId,
          trainerTraineeId: e.trainerTraineeId,
          sessionDate: e.sessionDate,
          status: e.status,
          recordedBy: e.recordedBy,
          createdAt: e.createdAt,
          trainerName: e.trainerName,
          traineeName: e.traineeName);
  PrivateTrainingSession toEntity() => PrivateTrainingSession(
      id: id,
      slotId: slotId,
      trainerTraineeId: trainerTraineeId,
      sessionDate: sessionDate,
      status: status,
      recordedBy: recordedBy,
      createdAt: createdAt,
      trainerName: trainerName,
      traineeName: traineeName);
}
