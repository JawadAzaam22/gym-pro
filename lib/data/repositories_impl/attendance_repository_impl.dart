import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/repositories/i_attendance_repository.dart';
import '../datasources/supabase_attendance_datasource.dart';

class AttendanceRepositoryImpl implements IAttendanceRepository {
  final SupabaseAttendanceDatasource datasource;
  AttendanceRepositoryImpl(this.datasource);

  @override
  Future<Either<Failure, Attendance>> recordAttendance(String traineeId, String method, {int? sessionId}) async {
    try {
      final a = await datasource.recordAttendance(traineeId, method, sessionId: sessionId);
      return Right(a.toEntity());
    } on MembershipExpiredException catch (e) {
      return Left(MembershipExpiredFailure(e.message, e.endDate));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Attendance>>> getAttendanceByTrainee(String traineeId) async {
    try {
      final list = await datasource.getAttendanceByTrainee(traineeId);
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Attendance>>> getAllAttendance({DateTime? from, DateTime? to}) async {
    try {
      final list = await datasource.getAllAttendance(from: from, to: to);
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<Attendance>> watchAttendance() => datasource.watchAttendance().map((list) => list.map((e) => e.toEntity()).toList());
}
