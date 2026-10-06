import "../../domain/entities/program_exercise.dart";

class ProgramExerciseModel extends ProgramExercise {
  const ProgramExerciseModel({required super.id, required super.dayId, required super.exerciseName, super.sets, super.reps, super.notes, required super.orderIndex});

  factory ProgramExerciseModel.fromJson(Map<String, dynamic> json) => ProgramExerciseModel(
        id: json['id'] as int,
        dayId: json['day_id'] as int,
        exerciseName: json['exercise_name'] as String,
        sets: json['sets'] as int?,
        reps: json['reps'] as String?,
        notes: json['notes'] as String?,
        orderIndex: json['order_index'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {'id': id, 'day_id': dayId, 'exercise_name': exerciseName, 'sets': sets, 'reps': reps, 'notes': notes, 'order_index': orderIndex};
  Map<String, dynamic> toInsertJson() {
    final j = toJson();
    j.remove('id');
    return j;
  }

  factory ProgramExerciseModel.fromEntity(ProgramExercise e) => ProgramExerciseModel(id: e.id, dayId: e.dayId, exerciseName: e.exerciseName, sets: e.sets, reps: e.reps, notes: e.notes, orderIndex: e.orderIndex);
  ProgramExercise toEntity() => ProgramExercise(id: id, dayId: dayId, exerciseName: exerciseName, sets: sets, reps: reps, notes: notes, orderIndex: orderIndex);
}
