import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/user.dart';
import '../../../shared/auth/controllers/auth_controller.dart';

final myTrainerProvider = FutureProvider<User?>((ref) async {
  final currentUser = ref.read(authControllerProvider).value;
  final traineeId = currentUser?.id ?? '';
  final rels = await ref.read(bookingDatasourceProvider).getTrainerTrainees(traineeId: traineeId);
  if (rels.isEmpty) return null;
  final trainerId = rels.first.trainerId;
  final userRes = await ref.read(userRepositoryProvider).getUserById(trainerId);
  return userRes.fold((l) => throw Exception(l.message), (r) => r);
});

