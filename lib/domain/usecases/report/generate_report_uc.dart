import "package:dartz/dartz.dart";
import "../../../core/errors/failures.dart";
import "../../entities/report.dart";
import "../../repositories/i_report_repository.dart";

class GenerateReportUc {
  final IReportRepository repository;
  GenerateReportUc(this.repository);
  Future<Either<Failure, Report>> call(String type, String title, String? description, String generatedBy) =>
      repository.generateReport(type, title, description, generatedBy);
}

