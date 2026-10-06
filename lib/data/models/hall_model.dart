import "../../domain/entities/hall.dart";

class HallModel extends Hall {
  const HallModel({
    required super.id,
    required super.name,
    required super.capacity,
    required super.isActive,
    super.openTime,
    super.closeTime,
    super.defaultSlotMinutes,
  });

  factory HallModel.fromJson(Map<String, dynamic> json) => HallModel(
        id: json['id'] as int,
        name: json['name'] as String,
        capacity: json['capacity'] as int,
        isActive: json['is_active'] as bool? ?? true,
        openTime: json['open_time'] as String? ?? '08:00:00',
        closeTime: json['close_time'] as String? ?? '22:00:00',
        defaultSlotMinutes: json['default_slot_minutes'] as int? ?? 60,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'capacity': capacity,
        'is_active': isActive,
        'open_time': openTime,
        'close_time': closeTime,
        'default_slot_minutes': defaultSlotMinutes,
      };

  Map<String, dynamic> toInsertJson() {
    final j = toJson();
    j.remove('id');
    return j;
  }

  factory HallModel.fromEntity(Hall e) => HallModel(
        id: e.id,
        name: e.name,
        capacity: e.capacity,
        isActive: e.isActive,
        openTime: e.openTime,
        closeTime: e.closeTime,
        defaultSlotMinutes: e.defaultSlotMinutes,
      );

  Hall toEntity() => Hall(
        id: id,
        name: name,
        capacity: capacity,
        isActive: isActive,
        openTime: openTime,
        closeTime: closeTime,
        defaultSlotMinutes: defaultSlotMinutes,
      );
}
