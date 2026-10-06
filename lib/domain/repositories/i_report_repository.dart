import "package:dartz/dartz.dart";
import "../../core/errors/failures.dart";
import "../entities/report.dart";

abstract class IReportRepository {
  Future<Either<Failure, Report>> generateReport(
    String type,
    String title,
    String? description,
    String generatedBy, [
    Map<String, dynamic>? data,
  ]);
  Future<Either<Failure, List<Report>>> getReports();
  Future<Either<Failure, void>> deleteReport(int id);
  Future<Either<Failure, void>> deleteAllReports();
  Future<Either<Failure, Map<String, dynamic>>> getFinancialSummary(
      DateTime from, DateTime to);
  Future<Either<Failure, Map<String, dynamic>>> getAttendanceSummary(
      DateTime from, DateTime to);
  Future<Either<Failure, Map<String, dynamic>>> getOperationalSummary(
      DateTime from, DateTime to);
}
