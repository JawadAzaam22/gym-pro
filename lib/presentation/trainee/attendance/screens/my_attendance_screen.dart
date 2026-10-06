import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/auth/controllers/auth_controller.dart';

final myAttendanceProvider = FutureProvider((ref) async {
  final userId = ref.read(authControllerProvider).value?.id ?? '';
  final res = await ref.read(attendanceRepositoryProvider).getAttendanceByTrainee(userId);
  return res.fold((l) => throw Exception(l.message), (r) => r);
});

class MyAttendanceScreen extends ConsumerWidget {
  const MyAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(myAttendanceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('سجل حضوري')),
      body: attendanceAsync.when(
        loading: () => const LoadingIndicator(message: 'جاري تحميل سجل الحضور...'),
        error: (e, _) => AsyncErrorView(error: e, onRetry: () => ref.invalidate(myAttendanceProvider)),
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('لا يوجد سجل حضور بعد', style: TextStyle(color: AppColors.textMuted)));
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myAttendanceProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final a = list[i];
                final date = a.checkInTime;
                final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                return AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dateStr, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(timeStr, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          a.method.name == 'qr' ? 'QR' : 'يدوي',
                          style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
