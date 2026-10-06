import "package:dartz/dartz.dart";
import "../../core/errors/failures.dart";
import "../entities/payment_cost.dart";

abstract class IPaymentRepository {
  Future<Either<Failure, PaymentCost>> recordPayment(PaymentCost payment);
  Future<Either<Failure, List<PaymentCost>>> getPayments({String? userId, String? type, DateTime? from, DateTime? to});
  Future<Either<Failure, double>> getTotalIncome(DateTime from, DateTime to);
  Future<Either<Failure, double>> getTotalExpense(DateTime from, DateTime to);
  Future<Either<Failure, List<PaymentCost>>> getAll();
}
