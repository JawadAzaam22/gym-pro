import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/enums.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/payment_cost.dart';
import '../../../shared/auth/controllers/auth_controller.dart';

class PaymentController extends AsyncNotifier<List<PaymentCost>> {
  @override
  Future<List<PaymentCost>> build() async => [];

  Future<bool> record({String? userId, required double amount, required PaymentType type, required PaymentCategory category, String? description}) async {
    final recordedBy = ref.read(authControllerProvider).value?.id ?? '';
    final p = PaymentCost(id: 0, userId: userId, type: type, category: category, amount: amount, paymentDate: DateTime.now(), description: description, recordedBy: recordedBy, createdAt: DateTime.now());
    final res = await ref.read(paymentRepositoryProvider).recordPayment(p);
    return res.fold((l) {
      state = AsyncValue.error(l.message, StackTrace.current);
      return false;
    }, (r) {
      state = AsyncValue.data([...state.value ?? [], r]);
      return true;
    });
  }
}

final paymentControllerProvider = AsyncNotifierProvider<PaymentController, List<PaymentCost>>(PaymentController.new);
