import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/status_badge.dart';
import '../controllers/my_bookings_controller.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myBookingsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('حجوزاتي'),
        actions: [
          IconButton(
            tooltip: 'الحصص المتاحة',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push('/trainee/bookings/group'),
          ),
        ],
      ),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [
            Icon(Icons.info_outline, size: 16, color: AppColors.info),
            SizedBox(width: 8),
            Expanded(
                child: Text(
                    'عرض فقط — الحجز والإلغاء يتمّان عبر موظف الاستقبال',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11))),
          ]),
        ),
        Expanded(
          child: async.when(
            loading: () =>
                const LoadingIndicator(message: 'جاري تحميل حجوزاتك...'),
            error: (e, _) => AsyncErrorView(
                error: e, onRetry: () => ref.invalidate(myBookingsProvider)),
            data: (d) {
              if (d.bookings.isEmpty) {
                return const Center(
                    child: Text('لا توجد حجوزات بعد',
                        style: TextStyle(color: AppColors.textMuted)));
              }
              final sessionsById = {for (final s in d.sessions) s.id: s};
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: d.bookings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final b = d.bookings[i];
                  final s = sessionsById[b.sessionId];
                  final isCancelled = b.status.name == 'cancelled';
                  return AppCard(
                    child: Row(children: [
                      Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12)),
                          child:
                              const Icon(Icons.event, color: AppColors.primary)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(s?.name ?? 'حصة #${b.sessionId}',
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                            Text(b.createdAt.toIso8601String().split('T').first,
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 11)),
                          ])),
                      StatusBadge(
                          label: isCancelled ? 'ملغي' : 'مؤكد',
                          variant: isCancelled
                              ? BadgeVariant.danger
                              : BadgeVariant.active),
                    ]),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
