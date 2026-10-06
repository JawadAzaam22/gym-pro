import "package:equatable/equatable.dart";

class ProgramDay extends Equatable {
  final int id;
  final int programId;
  final int dayOfWeek;
  final String? muscleGroup;
  final int orderIndex;

  const ProgramDay({
    required this.id,
    required this.programId,
    required this.dayOfWeek,
    this.muscleGroup,
    required this.orderIndex,
  });

  @override
  List<Object?> get props => [id, programId, dayOfWeek, muscleGroup, orderIndex];
}
