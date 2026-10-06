import "package:dartz/dartz.dart";
import "../../../core/errors/failures.dart";
import "../../entities/booking.dart";
import "../../repositories/i_booking_repository.dart";

class BookSessionUc {
  final IBookingRepository repository;
  BookSessionUc(this.repository);
  Future<Either<Failure, Booking>> call(String traineeId, int sessionId) =>
      repository.bookSession(traineeId, sessionId);
}

