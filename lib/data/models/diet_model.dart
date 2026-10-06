import "../../domain/entities/diet.dart";

class DietModel extends Diet {
  const DietModel({required super.id, required super.trainerId, required super.traineeId, required super.name, super.description, required super.startDate, super.endDate, required super.isActive, required super.createdAt});

  factory DietModel.fromJson(Map<String, dynamic> json) => DietModel(
        id: json['id'] as int,
        trainerId: json['trainer_id'] as String,
        traineeId: json['trainee_id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: json['end_date'] == null ? null : DateTime.parse(json['end_date'] as String),
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {'id': id, 'trainer_id': trainerId, 'trainee_id': traineeId, 'name': name, 'description': description, 'start_date': startDate.toIso8601String().split('T').first, 'end_date': endDate?.toIso8601String().split('T').first, 'is_active': isActive, 'created_at': createdAt.toIso8601String()};
  Map<String, dynamic> toInsertJson() {
    final j = toJson();
    j.remove('id');
    j.remove('created_at');
    return j;
  }

  factory DietModel.fromEntity(Diet e) => DietModel(id: e.id, trainerId: e.trainerId, traineeId: e.traineeId, name: e.name, description: e.description, startDate: e.startDate, endDate: e.endDate, isActive: e.isActive, createdAt: e.createdAt);
  Diet toEntity() => Diet(id: id, trainerId: trainerId, traineeId: traineeId, name: name, description: description, startDate: startDate, endDate: endDate, isActive: isActive, createdAt: createdAt);
}
