import "package:dartz/dartz.dart";
import "../../../core/errors/failures.dart";
import "../../entities/payment_cost.dart";
import "../../repositories/i_payment_repository.dart";

class GetPaymentsUc {
  final IPaymentRepository repository;
  GetPaymentsUc(this.repository);
  Future<Either<Failure, List<PaymentCost>>> call({String? userId, String? type, DateTime? from, DateTime? to}) =>
      repository.getPayments(userId: userId, type: type, from: from, to: to);
}

