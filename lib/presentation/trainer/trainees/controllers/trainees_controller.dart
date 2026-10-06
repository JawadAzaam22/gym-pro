import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/diet.dart';
import '../../../../domain/entities/membership.dart';
import '../../../../domain/entities/training_program.dart';
import '../../../../domain/entities/user.dart';
import '../../../shared/auth/controllers/auth_controller.dart';

class TraineesController extends AsyncNotifier<List<User>> {
  @override
  Future<List<User>> build() async {
    // Wait for auth to be fully loaded to avoid silent empty trainerId
    final currentUser = await ref.watch(authControllerProvider.future);
    if (currentUser == null) {
      throw Exception('المستخدم غير مسجل الدخول');
    }
    final trainerId = currentUser.id;
    
    // Debug print for diagnosis
    log('[TraineesController] trainerId: $trainerId');
    
    // استخدام Repository بدلاً من Datasource مباشر (يحافظ على Either)
    final repo = ref.read(userRepositoryProvider);
    // جلب العلاقات عبر datasource (لا يوجد repository لها بعد)
    final rels = await ref.read(bookingDatasourceProvider).getTrainerTrainees(trainerId: trainerId);
    
    // Debug print for diagnosis
    log('[TraineesController] rels.length: ${rels.length}');
    for (final rel in rels) {
      log('[TraineesController] trainee_id: ${rel.traineeId}');
    }
    
    final ids = rels.map((e) => e.traineeId).toList();
    final usersRes = await repo.getAllUsers();
    return usersRes.fold(
      (l) => throw Exception(l.message),
      (users) => users.where((u) => ids.contains(u.id)).toList(),
    );
  }
}

final traineesControllerProvider = AsyncNotifierProvider<TraineesController, List<User>>(TraineesController.new);

/// تفاصيل متدرب واحد: المستخدم + آخر عضوية + آخر برنامج نشط + آخر خطة نشطة.
/// نسبة التقدم مشتقة من تواريخ البرنامج (null عند غياب endDate).
class TraineeDetailData {
  final User user;
  final Membership? latestMembership;
  final TrainingProgram? activeProgram;
  final double? programProgress;
  final Diet? activeDiet;
  const TraineeDetailData({required this.user, this.latestMembership, this.activeProgram, this.programProgress, this.activeDiet});
}

final traineeDetailProvider = FutureProvider.family<TraineeDetailData, String>((ref, traineeId) async {
  final userRes = await ref.read(userRepositoryProvider).getUserById(traineeId);
  final membershipsRes = await ref.read(membershipRepositoryProvider).getMembershipsByTrainee(traineeId);
  final programsRes = await ref.read(programRepositoryProvider).getProgramsByTrainee(traineeId);
  final dietsRes = await ref.read(dietRepositoryProvider).getDietsByTrainee(traineeId);

  final failure = userRes.fold((l) => l.message, (_) => null) ??
      membershipsRes.fold((l) => l.message, (_) => null) ??
      programsRes.fold((l) => l.message, (_) => null) ??
      dietsRes.fold((l) => l.message, (_) => null);
  if (failure != null) throw Exception(failure);

  final user = userRes.getOrElse(() => throw Exception('المتدرب غير موجود'));
  final memberships = membershipsRes.getOrElse(() => []);
  final programs = programsRes.getOrElse(() => []);
  final diets = dietsRes.getOrElse(() => []);

  final latestMembership = memberships.isEmpty ? null : memberships.first;
  final activePrograms = programs.where((p) => p.isActive).toList();
  final activeProgram = activePrograms.isEmpty ? null : activePrograms.first;
  double? progress;
  if (activeProgram?.endDate != null) {
    final total = activeProgram!.endDate!.difference(activeProgram.startDate).inDays;
    final elapsed = DateTime.now().difference(activeProgram.startDate).inDays;
    progress = total <= 0 ? 1.0 : (elapsed / total).clamp(0.0, 1.0);
  }
  final activeDiets = diets.where((d) => d.isActive).toList();
  return TraineeDetailData(
    user: user,
    latestMembership: latestMembership,
    activeProgram: activeProgram,
    programProgress: progress,
    activeDiet: activeDiets.isEmpty ? null : activeDiets.first,
  );
});

