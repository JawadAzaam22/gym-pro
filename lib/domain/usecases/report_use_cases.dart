import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/report.dart';
import '../repositories/i_report_repository.dart';

class ReportUseCases {
  final IReportRepository repository;
  const ReportUseCases(this.repository);

  Future<Either<Failure, Report>> generateReport(
    String type,
    String title,
    String? description,
    String generatedBy, [
    Map<String, dynamic>? data,
  ]) =>
      repository.generateReport(type, title, description, generatedBy, data);
  Future<Either<Failure, List<Report>>> getReports() => repository.getReports();
  Future<Either<Failure, void>> deleteReport(int id) =>
      repository.deleteReport(id);
  Future<Either<Failure, void>> deleteAllReports() =>
      repository.deleteAllReports();
  Future<Either<Failure, Map<String, dynamic>>> getFinancialSummary(
          DateTime from, DateTime to) =>
      repository.getFinancialSummary(from, to);
  Future<Either<Failure, Map<String, dynamic>>> getAttendanceSummary(
          DateTime from, DateTime to) =>
      repository.getAttendanceSummary(from, to);
  Future<Either<Failure, Map<String, dynamic>>> getOperationalSummary(
          DateTime from, DateTime to) =>
      repository.getOperationalSummary(from, to);
}
