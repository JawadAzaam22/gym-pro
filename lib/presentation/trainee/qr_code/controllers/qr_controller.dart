import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/auth/controllers/auth_controller.dart';

/// معرّف المستخدم الحالي — يُشتق من حالة المصادقة بلا دورة اعتمادية.
/// (مزوّد منفصل كي يستطيع AuthController إبطال مزوّد QR عند تسجيل
/// الخروج دون CircularDependencyError — يراقب authController مباشرة.)
final currentUserIdProvider = Provider<String>(
    (ref) => ref.watch(authControllerProvider).valueOrNull?.id ?? '');

/// QR يحمل profiles.id (uuid) مباشرة — يُمسح في شاشة الاستقبال ويسجَّل حضور.
/// الصيغة ثابتة trainee_<uuid> حتى لا يتعطل مسح الاستقبال.
/// qrRefreshProvider: عدّاد يُحدَّث من زر "تحديث الكود" لإعادة توليد الكود.
final traineeQrProvider = Provider<String>((ref) {
  ref.watch(qrRefreshProvider);
  final id = ref.watch(currentUserIdProvider);
  if (id.isEmpty) return 'trainee_pending';
  return 'trainee_$id';
});

/// عدّاد تحديث كود الدخول — يزيد عند الضغط على زر "تحديث الكود".
final qrRefreshProvider = StateProvider<int>((ref) => 0);
