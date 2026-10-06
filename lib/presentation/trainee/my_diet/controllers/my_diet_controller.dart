import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/diet.dart';
import '../../../shared/auth/controllers/auth_controller.dart';

final myDietProvider = FutureProvider<List<Diet>>((ref) async {
  final currentUser = ref.read(authControllerProvider).value;
  final traineeId = currentUser?.id ?? '';
  final res = await ref.read(dietRepositoryProvider).getDietsByTrainee(traineeId);
  return res.fold((l) => throw Exception(l.message), (r) => r);
});

