import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/training_program.dart';
import '../../../shared/auth/controllers/auth_controller.dart';

final myProgramProvider = FutureProvider<List<TrainingProgram>>((ref) async {
  final currentUser = ref.read(authControllerProvider).value;
  final traineeId = currentUser?.id ?? '';
  final res = await ref.read(programRepositoryProvider).getProgramsByTrainee(traineeId);
  return res.fold((l) => throw Exception(l.message), (r) => r);
});

