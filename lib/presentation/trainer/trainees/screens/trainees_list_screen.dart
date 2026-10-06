import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../controllers/trainees_controller.dart';

class TraineesListScreen extends ConsumerWidget {
  const TraineesListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(traineesControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('متدربيني')),
      body: async.when(
        loading: () => const LoadingIndicator(message: 'جاري تحميل المتدربين...'),
        error: (e, _) => AsyncErrorView(error: e, onRetry: () => ref.invalidate(traineesControllerProvider)),
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('لا يوجد متدربون مسندون إليك بعد', style: TextStyle(color: AppColors.textMuted)));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final u = list[i];
              return AppCard(
                child: InkWell(
                  onTap: () => context.push('/trainer/trainees/${u.id}', extra: u),
                  child: Row(children: [
                    CircleAvatar(radius: 22, backgroundColor: AppColors.surfaceLow, child: Text(u.name.characters.first, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(u.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)), Text(u.phone, style: const TextStyle(color: AppColors.textMuted, fontSize: 11))])),
                    StatusBadge(label: u.isActive ? 'نشط' : 'موقوف', variant: u.isActive ? BadgeVariant.active : BadgeVariant.danger),
                    const Icon(Icons.arrow_back_ios, size: 12, color: AppColors.textMuted),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
