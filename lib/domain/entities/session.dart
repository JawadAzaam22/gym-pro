import "package:equatable/equatable.dart";
import "../../core/constants/enums.dart";

class Session extends Equatable {
  final int id;
  final String name;
  final String? description;
  final int hallId;
  final String? trainerId;
  final int? accessPeriodId;
  final DateTime startDate;
  final DateTime endDate;
  final int capacity;
  final SessionStatus status;
  final String? createdBy;
  final DateTime createdAt;

  const Session({
    required this.id,
    required this.name,
    this.description,
    required this.hallId,
    this.trainerId,
    this.accessPeriodId,
    required this.startDate,
    required this.endDate,
    required this.capacity,
    required this.status,
    this.createdBy,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, description, hallId, trainerId, accessPeriodId, startDate, endDate, capacity, status, createdBy, createdAt];
}
