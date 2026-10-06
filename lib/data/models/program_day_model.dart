import "../../domain/entities/program_day.dart";

class ProgramDayModel extends ProgramDay {
  const ProgramDayModel({required super.id, required super.programId, required super.dayOfWeek, super.muscleGroup, required super.orderIndex});

  factory ProgramDayModel.fromJson(Map<String, dynamic> json) => ProgramDayModel(
        id: json['id'] as int,
        programId: json['program_id'] as int,
        dayOfWeek: (json['day_of_week'] as num).toInt(),
        muscleGroup: json['muscle_group'] as String?,
        orderIndex: json['order_index'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {'id': id, 'program_id': programId, 'day_of_week': dayOfWeek, 'muscle_group': muscleGroup, 'order_index': orderIndex};
  Map<String, dynamic> toInsertJson() {
    final j = toJson();
    j.remove('id');
    return j;
  }

  factory ProgramDayModel.fromEntity(ProgramDay e) => ProgramDayModel(id: e.id, programId: e.programId, dayOfWeek: e.dayOfWeek, muscleGroup: e.muscleGroup, orderIndex: e.orderIndex);
  ProgramDay toEntity() => ProgramDay(id: id, programId: programId, dayOfWeek: dayOfWeek, muscleGroup: muscleGroup, orderIndex: orderIndex);
}
