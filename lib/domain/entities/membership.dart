import "package:equatable/equatable.dart";
import "../../core/constants/enums.dart";

class Membership extends Equatable {
  final int id;
  final String traineeId;
  final DateTime startDate;
  final DateTime endDate;
  final MembershipStatus status;
  final String? recordedBy;
  final DateTime createdAt;

  const Membership({
    required this.id,
    required this.traineeId,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.recordedBy,
    required this.createdAt,
  });

  bool get isActive => status == MembershipStatus.active && endDate.isAfter(DateTime.now());
  bool get isExpired => status == MembershipStatus.expired || endDate.isBefore(DateTime.now());

  @override
  List<Object?> get props => [id, traineeId, startDate, endDate, status, recordedBy, createdAt];
}
