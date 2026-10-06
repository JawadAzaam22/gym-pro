import "package:equatable/equatable.dart";

class ProgramExercise extends Equatable {
  final int id;
  final int dayId;
  final String exerciseName;
  final int? sets;
  final String? reps;
  final String? notes;
  final int orderIndex;

  const ProgramExercise({
    required this.id,
    required this.dayId,
    required this.exerciseName,
    this.sets,
    this.reps,
    this.notes,
    required this.orderIndex,
  });

  @override
  List<Object?> get props => [id, dayId, exerciseName, sets, reps, notes, orderIndex];
}
