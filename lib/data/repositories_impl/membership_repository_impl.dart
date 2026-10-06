import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/membership.dart';
import '../../domain/repositories/i_membership_repository.dart';
import '../datasources/supabase_membership_datasource.dart';
import '../models/membership_model.dart';

class MembershipRepositoryImpl implements IMembershipRepository {
  final SupabaseMembershipDatasource datasource;
  MembershipRepositoryImpl(this.datasource);

  @override
  Future<Either<Failure, List<Membership>>> getAllMemberships() async {
    try {
      final list = await datasource.getAllMemberships();
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Membership>>> getMembershipsByTrainee(String traineeId) async {
    try {
      final list = await datasource.getMembershipsByTrainee(traineeId);
      return Right(list.map((e) => e.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Membership?>> getActiveMembership(String traineeId) async {
    try {
      final m = await datasource.getActiveMembership(traineeId);
      return Right(m?.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Membership?>> getLatestMembership(String traineeId) async {
    try {
      final m = await datasource.getLatestMembership(traineeId);
      return Right(m?.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Membership>> createMembership(Membership membership) async {
    try {
      final model = MembershipModel.fromEntity(membership);
      final created = await datasource.createMembership(model);
      return Right(created.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Membership>> renewMembership(String traineeId, DateTime newEndDate, String recordedBy) async {
    try {
      final renewed = await datasource.renewMembership(traineeId, newEndDate, recordedBy);
      return Right(renewed.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Membership>> checkStatus(String traineeId) async {
    try {
      final m = await datasource.checkStatus(traineeId);
      return Right(m.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMembership(int id) async {
    try {
      await datasource.deleteMembership(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
