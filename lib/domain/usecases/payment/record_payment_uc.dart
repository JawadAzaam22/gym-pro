import "package:dartz/dartz.dart";
import "../../../core/errors/failures.dart";
import "../../entities/payment_cost.dart";
import "../../repositories/i_payment_repository.dart";

class RecordPaymentUc {
  final IPaymentRepository repository;
  RecordPaymentUc(this.repository);
  Future<Either<Failure, PaymentCost>> call(PaymentCost p) =>
      repository.recordPayment(p);
}

