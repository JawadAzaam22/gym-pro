import "../../domain/entities/diet_day.dart";

class DietDayModel extends DietDay {
  const DietDayModel({required super.id, required super.dietId, required super.dayOfWeek, required super.orderIndex});

  factory DietDayModel.fromJson(Map<String, dynamic> json) => DietDayModel(
        id: json['id'] as int,
        dietId: json['diet_id'] as int,
        dayOfWeek: (json['day_of_week'] as num).toInt(),
        orderIndex: json['order_index'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {'id': id, 'diet_id': dietId, 'day_of_week': dayOfWeek, 'order_index': orderIndex};
  Map<String, dynamic> toInsertJson() {
    final j = toJson();
    j.remove('id');
    return j;
  }

  factory DietDayModel.fromEntity(DietDay e) => DietDayModel(id: e.id, dietId: e.dietId, dayOfWeek: e.dayOfWeek, orderIndex: e.orderIndex);
  DietDay toEntity() => DietDay(id: id, dietId: dietId, dayOfWeek: dayOfWeek, orderIndex: orderIndex);
}
