import "package:equatable/equatable.dart";
import "../../core/constants/enums.dart";

class Booking extends Equatable {
  final int id;
  final String traineeId;
  final int sessionId;
  final BookingStatus status;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.traineeId,
    required this.sessionId,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, traineeId, sessionId, status, createdAt];
}
