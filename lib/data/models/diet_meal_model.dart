import "../../domain/entities/diet_meal.dart";

class DietMealModel extends DietMeal {
  const DietMealModel({required super.id, required super.dayId, required super.mealType, required super.description, super.calories, required super.orderIndex});

  factory DietMealModel.fromJson(Map<String, dynamic> json) => DietMealModel(
        id: json['id'] as int,
        dayId: json['day_id'] as int,
        mealType: json['meal_type'] as String,
        description: json['description'] as String,
        calories: json['calories'] as int?,
        orderIndex: json['order_index'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {'id': id, 'day_id': dayId, 'meal_type': mealType, 'description': description, 'calories': calories, 'order_index': orderIndex};
  Map<String, dynamic> toInsertJson() {
    final j = toJson();
    j.remove('id');
    return j;
  }

  factory DietMealModel.fromEntity(DietMeal e) => DietMealModel(id: e.id, dayId: e.dayId, mealType: e.mealType, description: e.description, calories: e.calories, orderIndex: e.orderIndex);
  DietMeal toEntity() => DietMeal(id: id, dayId: dayId, mealType: mealType, description: description, calories: calories, orderIndex: orderIndex);
}
