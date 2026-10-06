import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/user.dart';

class TrainerAssignmentState {
  final bool isLoading;
  final String? error;
  final String? success;
  const TrainerAssignmentState({this.isLoading = false, this.error, this.success});
}

class TrainerAssignmentController extends StateNotifier<TrainerAssignmentState> {
  final Ref ref;
  TrainerAssignmentController(this.ref) : super(const TrainerAssignmentState());

  /// يعيّن مدربًا لمتدرب عبر assignTrainer ويعيد نجاح/فشل الواجهة.
  Future<bool> assign({required String trainerId, required String traineeId, required String assignedBy}) async {
    state = const TrainerAssignmentState(isLoading: true);
    try {
      await ref.read(bookingDatasourceProvider).assignTrainer(trainerId, traineeId, assignedBy);
      // تحديث عرض المدرب الحالي للمتدرب.
      ref.invalidate(traineeCurrentTrainerProvider(traineeId));
      state = const TrainerAssignmentState(success: 'تم تعيين المدرب بنجاح');
      return true;
    } catch (e) {
      state = TrainerAssignmentState(error: 'فشل التعيين: $e');
      return false;
    }
  }

  Future<bool> changeAssignment({required int assignmentId, required String newTrainerId, required String traineeId}) async {
    state = const TrainerAssignmentState(isLoading: true);
    try {
      await ref.read(bookingDatasourceProvider).changeTrainerAssignment(assignmentId, newTrainerId);
      ref.invalidate(traineeCurrentTrainerProvider(traineeId));
      state = const TrainerAssignmentState(success: 'تم تغيير المدرب بنجاح');
      return true;
    } catch (e) {
      state = TrainerAssignmentState(error: 'فشل التغيير: $e');
      return false;
    }
  }

  Future<bool> deleteAssignment(int assignmentId) async {
    state = const TrainerAssignmentState(isLoading: true);
    try {
      await ref.read(bookingDatasourceProvider).deactivateTrainerAssignment(assignmentId);
      ref.invalidate(traineeCurrentTrainerProvider);
      ref.invalidate(traineeAssignmentIdProvider);
      state = const TrainerAssignmentState(success: 'تم إلغاء التعيين');
      return true;
    } catch (e) {
      state = TrainerAssignmentState(error: 'فشل الإلغاء: $e');
      return false;
    }
  }

  void clear() => state = const TrainerAssignmentState();
}

final trainerAssignmentControllerProvider = StateNotifierProvider<TrainerAssignmentController, TrainerAssignmentState>(
  (ref) => TrainerAssignmentController(ref),
);

/// المدرب الحالي لمتدرب معيّن (null عند غيابه).
final traineeCurrentTrainerProvider = FutureProvider.family<User?, String>((ref, traineeId) async {
  final rels = await ref.read(bookingDatasourceProvider).getTrainerTrainees(traineeId: traineeId);
  final active = rels.where((e) => e.status.name == 'active').toList();
  final rel = active.isEmpty ? (rels.isEmpty ? null : rels.first) : active.first;
  if (rel == null) return null;
  final userRes = await ref.read(userRepositoryProvider).getUserById(rel.trainerId);
  return userRes.fold((l) => throw Exception(l.message), (r) => r);
});

/// معرّف التعيين الحالي لمتدرب.
final traineeAssignmentIdProvider = FutureProvider.family<int?, String>((ref, traineeId) async {
  final rels = await ref.read(bookingDatasourceProvider).getTrainerTrainees(traineeId: traineeId);
  final active = rels.where((e) => e.status.name == 'active').toList();
  if (active.isEmpty) return null;
  return active.first.id;
});

/// الاختيارات الحالية في الشاشة.
final selectedTraineeIdProvider = StateProvider<String?>((ref) => null);
final selectedTrainerIdProvider = StateProvider<String?>((ref) => null);
