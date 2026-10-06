import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../data/providers.dart';
import '../../../../../domain/entities/trainer_trainee.dart';
import '../../../../../domain/entities/private_training_schedule.dart';

/// All active trainer-trainee relations for selection in reception
final activeTrainerTraineesProvider = FutureProvider<List<TrainerTrainee>>((ref) async {
  final ds = ref.read(bookingDatasourceProvider);
  final all = await ds.getTrainerTrainees();
  return all.where((e) => e.status.name == 'active').toList();
});

/// Get a single trainer-trainee relation by ID with trainer/trainee names
final trainerTraineeByIdProvider = FutureProvider.family<TrainerTrainee?, int>((ref, id) async {
  final ds = ref.read(bookingDatasourceProvider);
  final all = await ds.getTrainerTrainees();
  try {
    final rel = all.firstWhere((e) => e.id == id);
    return rel;
  } catch (_) {
    return null;
  }
});

/// Private training schedule for a specific trainer-trainee relation
final privateScheduleForRelationProvider =
    FutureProvider.family<List<PrivateTrainingSchedule>, int>((ref, trainerTraineeId) async {
  final res = await ref.read(bookingRepositoryProvider).getScheduleForTrainerTrainee(trainerTraineeId);
  return res.fold((l) => throw Exception(l.message), (r) => r);
});

/// Private training schedule for a trainer (all his relations)
final privateScheduleForTrainerProvider =
    FutureProvider.family<List<PrivateTrainingSchedule>, String>((ref, trainerId) async {
  final res = await ref.read(bookingRepositoryProvider).getScheduleForTrainer(trainerId);
  return res.fold((l) => throw Exception(l.message), (r) => r);
});

/// Private training schedule for a trainee (all his relations)
final privateScheduleForTraineeProvider =
    FutureProvider.family<List<PrivateTrainingSchedule>, String>((ref, traineeId) async {
  final res = await ref.read(bookingRepositoryProvider).getScheduleForTrainee(traineeId);
  return res.fold((l) => throw Exception(l.message), (r) => r);
});

/// State for selected relation in reception screen
final selectedTrainerTraineeIdProvider = StateProvider<int?>((ref) => null);