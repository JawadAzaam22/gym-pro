import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/payment_cost.dart';
import '../../domain/repositories/i_payment_repository.dart';
import '../datasources/supabase_payment_datasource.dart';
import '../models/payment_cost_model.dart';

class PaymentRepositoryImpl implements IPaymentRepository {
  final SupabasePaymentDatasource datasource;
  PaymentRepositoryImpl(this.datasource);

  @override
  Future<Either<Failure, PaymentCost>> recordPayment(PaymentCost payment) async {
    try {
      final model = PaymentCostModel.fromEntity(payment);
      final created = await datasource.recordPayment(model);
      return Right(created.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PaymentCost>>> getPayments({String? userId, String? type, DateTime? from, DateTime? to}) async {
    try {
      final list = await datasource.getPayments(userId: userId, type: type, from: from, to: to);
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PaymentCost>>> getAll() async {
    try {
      final list = await datasource.getAll();
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalIncome(DateTime from, DateTime to) async {
    try {
      final total = await datasource.getTotalByType('income', from, to);
      return Right(total);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalExpense(DateTime from, DateTime to) async {
    try {
      final total = await datasource.getTotalByType('expense', from, to);
      return Right(total);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
