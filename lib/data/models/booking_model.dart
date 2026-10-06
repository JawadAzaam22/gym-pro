import "../../core/constants/enums.dart";
import "../../domain/entities/booking.dart";

class BookingModel extends Booking {
  const BookingModel({required super.id, required super.traineeId, required super.sessionId, required super.status, required super.createdAt});

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: json['id'] as int,
        traineeId: json['trainee_id'] as String,
        sessionId: json['session_id'] as int,
        status: json['status'] == 'cancelled' ? BookingStatus.cancelled : BookingStatus.confirmed,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {'id': id, 'trainee_id': traineeId, 'session_id': sessionId, 'status': status.name, 'created_at': createdAt.toIso8601String()};
  Map<String, dynamic> toInsertJson() {
    final j = toJson();
    j.remove('id');
    j.remove('created_at');
    return j;
  }

  factory BookingModel.fromEntity(Booking e) => BookingModel(id: e.id, traineeId: e.traineeId, sessionId: e.sessionId, status: e.status, createdAt: e.createdAt);
  Booking toEntity() => Booking(id: id, traineeId: traineeId, sessionId: sessionId, status: status, createdAt: createdAt);
}
