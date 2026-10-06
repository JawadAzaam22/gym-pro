import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/membership.dart';
import '../../../shared/auth/controllers/auth_controller.dart';

/// آخر عضوية للمتدرب (مهما كانت حالتها) — حتى تظهر حالة 'expired' للعرض.
final myMembershipProvider = FutureProvider<Membership?>((ref) async {
  final currentUser = ref.read(authControllerProvider).value;
  final traineeId = currentUser?.id ?? '';
  final res = await ref.read(membershipRepositoryProvider).getLatestMembership(traineeId);
  return res.fold((l) => throw Exception(l.message), (r) => r);
});

