import "package:equatable/equatable.dart";

class DietDay extends Equatable {
  final int id;
  final int dietId;
  final int dayOfWeek;
  final int orderIndex;

  const DietDay({
    required this.id,
    required this.dietId,
    required this.dayOfWeek,
    required this.orderIndex,
  });

  @override
  List<Object?> get props => [id, dietId, dayOfWeek, orderIndex];
}
