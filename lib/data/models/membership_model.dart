import "../../core/constants/enums.dart";
import "../../domain/entities/membership.dart";

class MembershipModel extends Membership {
  const MembershipModel({
    required super.id,
    required super.traineeId,
    required super.startDate,
    required super.endDate,
    required super.status,
    required super.recordedBy,
    required super.createdAt,
  });

  factory MembershipModel.fromJson(Map<String, dynamic> json) {
    final String s = json['status'] as String;
    final DateTime endDate = DateTime.parse(json['end_date'] as String);
    MembershipStatus st;
    switch (s) {
      case 'expired':
        st = MembershipStatus.expired;
        break;
      case 'suspended':
        st = MembershipStatus.suspended;
        break;
      default:
        // تطبيع دفاعي: عضوية منتهية المدة لا تُعتبر نشطة حتى لو لم يُحدَّث
        // حقل status في القاعدة بعد (هجرة 008 / استدعاء الدالة).
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final normalizedEnd =
            DateTime(endDate.year, endDate.month, endDate.day);
        st = normalizedEnd.isBefore(today)
            ? MembershipStatus.expired
            : MembershipStatus.active;
    }
    return MembershipModel(
      id: json['id'] as int,
      traineeId: json['trainee_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: endDate,
      status: st,
      recordedBy: json['recorded_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trainee_id': traineeId,
        'start_date': startDate.toIso8601String().split('T').first,
        'end_date': endDate.toIso8601String().split('T').first,
        'status': status.name,
        'recorded_by': recordedBy,
        'created_at': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toInsertJson() {
    final j = toJson();
    j.remove('id');
    j.remove('created_at');
    return j;
  }

  factory MembershipModel.fromEntity(Membership e) => MembershipModel(
        id: e.id,
        traineeId: e.traineeId,
        startDate: e.startDate,
        endDate: e.endDate,
        status: e.status,
        recordedBy: e.recordedBy,
        createdAt: e.createdAt,
      );

  Membership toEntity() => Membership(
        id: id,
        traineeId: traineeId,
        startDate: startDate,
        endDate: endDate,
        status: status,
        recordedBy: recordedBy,
        createdAt: createdAt,
      );
}
