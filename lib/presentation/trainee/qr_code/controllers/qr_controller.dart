import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers.dart';

/// رمز قصير الصلاحية صادر من Supabase؛ لا يحتوي على UUID المتدرب.
final traineeQrProvider = FutureProvider<String>((ref) async {
  ref.watch(qrRefreshProvider);
  final result = await ref.read(issueTraineeQrCodeProvider).call();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (token) => token,
  );
});

final qrRefreshProvider = StateProvider<int>((ref) => 0);
