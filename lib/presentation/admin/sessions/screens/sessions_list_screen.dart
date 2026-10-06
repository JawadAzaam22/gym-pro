import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../controllers/sessions_controller.dart';
import '../../users/controllers/users_controller.dart';
import '../../halls/controllers/halls_controller.dart';

class SessionsListScreen extends ConsumerWidget {
  const SessionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sessionsControllerProvider);
    final usersAsync = ref.watch(usersControllerProvider);
    final hallsAsync = ref.watch(hallsControllerProvider);

    String trainerName(String? id) {
      if (id == null) return 'بدون مدرب';
      return usersAsync.whenOrNull(
            data: (users) {
              try {
                return users.firstWhere((u) => u.id == id).name;
              } catch (_) {
                return 'المدرب غير معروف';
              }
            },
          ) ??
          'المدرب غير معروف';
    }

    String hallName(int id) {
      return hallsAsync.whenOrNull(
            data: (halls) {
              try {
                return halls.firstWhere((h) => h.id == id).name;
              } catch (_) {
                return 'القاعة غير معروفة';
              }
            },
          ) ??
          'القاعة غير معروفة';
    }

    Future<void> _confirmDelete(int sessionId) async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          title: const Text('حذف الحصة نهائياً؟',
              style: TextStyle(color: AppColors.error)),
          content: const Text(
              'سيتم حذف الحصة وجميع ربطاتها بالفترات. لا يمكن التراجع.',
              style: TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('تراجع')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('حذف نهائي')),
          ],
        ),
      );
      if (confirm == true) {
        final ok = await ref.read(sessionsControllerProvider.notifier).delete(sessionId);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ok ? 'تم الحذف' : 'فشل الحذف'),
            backgroundColor: ok ? AppColors.success : AppColors.error));
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('الحصص الجماعية'), actions: [
        IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(sessionsControllerProvider)),
      ]),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/admin/sessions/new'),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label:
              const Text('حصة جديدة', style: TextStyle(color: Colors.white))),
      body: async.when(
        loading: () => const LoadingIndicator(message: 'جاري تحميل الحصص...'),
        error: (e, _) => AsyncErrorView(
            error: e,
            onRetry: () => ref.invalidate(sessionsControllerProvider)),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
                child: Text('لا توجد حصص بعد',
                    style: TextStyle(color: AppColors.textMuted)));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(sessionsControllerProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final s = list[i];
                return AppCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(s.name,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700))),
                          StatusBadge(
                              label: s.status.name,
                              variant: s.status.name == 'cancelled'
                                  ? BadgeVariant.danger
                                  : BadgeVariant.active),
                        ]),
                        Text(
                            '${hallName(s.hallId)} • ${trainerName(s.trainerId)} • سعة ${s.capacity}',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                              child: OutlinedButton.icon(
                                  onPressed: () => context
                                      .push('/admin/sessions/new', extra: s),
                                  icon: const Icon(Icons.edit, size: 14),
                                  label: const Text('تعديل',
                                      style: TextStyle(fontSize: 12)))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: OutlinedButton(
                                  onPressed: () => ref
                                      .read(sessionsControllerProvider.notifier)
                                      .cancel(s.id),
                                  child: const Text('إلغاء',
                                      style: TextStyle(
                                          color: AppColors.error,
                                          fontSize: 12)))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: OutlinedButton.icon(
                                  onPressed: () => _confirmDelete(s.id),
                                  icon: const Icon(Icons.delete_forever, size: 14, color: AppColors.error),
                                  label: const Text('حذف',
                                      style: TextStyle(fontSize: 12, color: AppColors.error)))),
                        ]),
                      ]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
