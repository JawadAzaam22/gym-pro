import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../controllers/my_trainer_controller.dart';

class MyTrainerScreen extends ConsumerWidget {
  const MyTrainerScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myTrainerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('مدربي')),
      body: async.when(
        loading: () => const LoadingIndicator(message: 'جاري التحميل...'),
        error: (e, _) => AsyncErrorView(error: e, onRetry: () => ref.invalidate(myTrainerProvider)),
        data: (u) {
          if (u == null) return const Center(child: Text('لم يتم تعيين مدرب لك بعد', style: TextStyle(color: AppColors.textMuted)));
          return Center(
            child: AppCard(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircleAvatar(radius: 32, backgroundColor: AppColors.surfaceLow, child: Text(u.name.characters.first, style: const TextStyle(color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.w800))),
                const SizedBox(height: 12),
                Text(u.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                Text(u.email, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(u.phone, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ]),
            ),
          );
        },
      ),
    );
  }
}
