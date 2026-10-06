import "package:equatable/equatable.dart";

class DietMeal extends Equatable {
  final int id;
  final int dayId;
  final String mealType;
  final String description;
  final int? calories;
  final int orderIndex;

  const DietMeal({
    required this.id,
    required this.dayId,
    required this.mealType,
    required this.description,
    this.calories,
    required this.orderIndex,
  });

  @override
  List<Object?> get props => [id, dayId, mealType, description, calories, orderIndex];
}
