import "package:dartz/dartz.dart";
import "../../../core/errors/failures.dart";
import "../../repositories/i_booking_repository.dart";

class CancelBookingUc {
  final IBookingRepository repository;
  CancelBookingUc(this.repository);
  Future<Either<Failure, void>> call(int bookingId) =>
      repository.cancelBooking(bookingId);
}

