import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/payment_cost.dart';
import '../repositories/i_payment_repository.dart';

class PaymentUseCases {
  final IPaymentRepository repository;
  const PaymentUseCases(this.repository);

  Future<Either<Failure, PaymentCost>> recordPayment(PaymentCost payment) =>
      repository.recordPayment(payment);
  Future<Either<Failure, List<PaymentCost>>> getPayments(
          {String? userId, String? type, DateTime? from, DateTime? to}) =>
      repository.getPayments(userId: userId, type: type, from: from, to: to);
  Future<Either<Failure, double>> getTotalIncome(DateTime from, DateTime to) =>
      repository.getTotalIncome(from, to);
  Future<Either<Failure, double>> getTotalExpense(DateTime from, DateTime to) =>
      repository.getTotalExpense(from, to);
  Future<Either<Failure, List<PaymentCost>>> getAll() => repository.getAll();
}
