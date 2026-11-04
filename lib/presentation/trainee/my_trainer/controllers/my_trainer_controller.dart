import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/user.dart';
import '../../../shared/auth/controllers/auth_controller.dart';

final myTrainerProvider = FutureProvider<User?>((ref) async {
  final currentUser = ref.read(authControllerProvider).value;
  final traineeId = currentUser?.id ?? '';
  final relations = await ref.read(getTrainerTraineesProvider).call(
        traineeId: traineeId,
      );
  final rels = relations.fold((l) => throw Exception(l.message), (r) => r);
  if (rels.isEmpty) return null;
  final trainerId = rels.first.trainerId;
  final userRes = await ref.read(userUseCasesProvider).getUserById(trainerId);
  return userRes.fold((l) => throw Exception(l.message), (r) => r);
});
