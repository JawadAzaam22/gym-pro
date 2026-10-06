import "package:equatable/equatable.dart";

class Diet extends Equatable {
  final int id;
  final String trainerId;
  final String traineeId;
  final String name;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;

  const Diet({
    required this.id,
    required this.trainerId,
    required this.traineeId,
    required this.name,
    this.description,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.createdAt,
  });

  Diet copyWith({
    int? id,
    String? trainerId,
    String? traineeId,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Diet(
      id: id ?? this.id,
      trainerId: trainerId ?? this.trainerId,
      traineeId: traineeId ?? this.traineeId,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, trainerId, traineeId, name, description, startDate, endDate, isActive, createdAt];
}
