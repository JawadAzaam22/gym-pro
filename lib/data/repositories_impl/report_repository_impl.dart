import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/report.dart';
import '../../domain/repositories/i_report_repository.dart';
import '../datasources/supabase_report_datasource.dart';

class ReportRepositoryImpl implements IReportRepository {
  final SupabaseReportDatasource datasource;
  ReportRepositoryImpl(this.datasource);

  @override
  Future<Either<Failure, Report>> generateReport(
    String type,
    String title,
    String? description,
    String generatedBy, [
    Map<String, dynamic>? data,
  ]) async {
    try {
      final report =
          await datasource.generateReport(type, title, description, generatedBy, data);
      return Right(report.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Report>>> getReports() async {
    try {
      final list = await datasource.getReports();
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReport(int id) async {
    try {
      await datasource.deleteReport(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAllReports() async {
    try {
      await datasource.deleteAllReports();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getFinancialSummary(
      DateTime from, DateTime to) async {
    try {
      final data = await datasource.getFinancialSummary(from, to);
      return Right(data);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getAttendanceSummary(
      DateTime from, DateTime to) async {
    try {
      final data = await datasource.getAttendanceSummary(from, to);
      return Right(data);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getOperationalSummary(
      DateTime from, DateTime to) async {
    try {
      final data = await datasource.getOperationalSummary(from, to);
      return Right(data);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
