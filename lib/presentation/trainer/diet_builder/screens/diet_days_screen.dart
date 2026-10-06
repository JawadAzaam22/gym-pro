import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/day_of_week_helper.dart';
import '../../../../domain/entities/diet.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../../data/providers.dart';
import '../../../../data/models/diet_day_model.dart';
import '../controllers/diet_builder_controller.dart';
import '../../../shared/widgets/app_toast.dart';

class DietDaysScreen extends ConsumerWidget {
  final int dietId;
  final Diet? diet;
  const DietDaysScreen({super.key, required this.dietId, this.diet});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(dietDaysProvider(dietId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(diet?.name ?? 'أيام الخطة #$dietId'),
        actions: [
          if (diet != null) ...[
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => context.push('/trainer/diets/new', extra: diet),
            ),
            IconButton(
              icon: Icon(diet!.isActive ? Icons.block : Icons.check_circle, size: 20),
              onPressed: () => _confirmDeactivate(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, size: 20, color: AppColors.error),
              onPressed: () => _confirmDeleteDiet(context, ref),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDay(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('يوم جديد', style: TextStyle(color: Colors.white)),
      ),
      body: daysAsync.when(
        loading: () => const LoadingIndicator(message: 'جاري تحميل الأيام...'),
        error: (e, _) => AsyncErrorView(error: e, onRetry: () => ref.invalidate(dietDaysProvider(dietId))),
        data: (days) {
          if (days.isEmpty) return const Center(child: Text('لا توجد أيام', style: TextStyle(color: AppColors.textMuted)));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final d = days[i];
              return InkWell(
                onTap: () => context.push(
                    '/trainer/diets/$dietId/days/${d.id}/meals'),
                borderRadius: BorderRadius.circular(16),
                child: AppCard(
                  child: Row(children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Center(child: Text('${d.orderIndex + 1}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)))),
                    const SizedBox(width: 12),
                    Expanded(child: Text(DayOfWeekHelper.name(d.dayOfWeek), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      onPressed: () => _confirmDeleteDay(context, ref, d.id),
                    ),
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

  void _confirmDeleteDiet(BuildContext context, WidgetRef ref) {
    if (diet == null) return;
    final d = diet!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('حذف الخطة الغذائية نهائياً؟', style: TextStyle(color: AppColors.error)),
        content: Text('سيتم حذف "${d.name}" وجميع أيامها ووجباتها. لا يمكن التراجع.', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref.read(dietBuilderProvider.notifier).delete(d.id);
              if (context.mounted) {
                if (ok) {
                  AppToast.success(context, 'تم الحذف');
                  Navigator.pop(context);
                } else {
                  AppToast.error(context, 'فشل الحذف');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDay(BuildContext context, WidgetRef ref, int dayId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('حذف اليوم؟', style: TextStyle(color: AppColors.error)),
        content: const Text('سيتم حذف هذا اليوم وجميع وجباته.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(dietDatasourceProvider).deleteDay(dayId);
                ref.invalidate(dietDaysProvider(dietId));
                if (context.mounted) AppToast.success(context, 'تم الحذف');
              } catch (e) {
                if (context.mounted) AppToast.error(context, 'فشل: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _addDay(BuildContext context, WidgetRef ref) {
    int dayOfWeek = 0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          title: const Text('يوم جديد', style: TextStyle(color: AppColors.textPrimary)),
          content: DropdownButtonFormField<int>(
            value: dayOfWeek,
            decoration: const InputDecoration(labelText: 'اليوم'),
            items: DayOfWeekHelper.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) => setState(() => dayOfWeek = v ?? 0),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(dietDatasourceProvider).addDay(DietDayModel(id: 0, dietId: dietId, dayOfWeek: dayOfWeek, orderIndex: 0));
                  ref.invalidate(dietDaysProvider(dietId));
                  if (context.mounted) AppToast.success(context, 'تمت الإضافة');
                } catch (e) {
                  if (context.mounted) AppToast.error(context, 'فشل: $e');
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeactivate(BuildContext context, WidgetRef ref) {
    if (diet == null) return;
    final d = diet!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text(d.isActive ? 'تعطيل الخطة؟' : 'تفعيل الخطة؟', style: const TextStyle(color: AppColors.textPrimary)),
        content: Text('هل أنت متأكد من ${d.isActive ? 'تعطيل' : 'تفعيل'} "${d.name}"؟', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref.read(dietBuilderProvider.notifier).deactivate(d.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'تم التحديث' : 'فشل'), backgroundColor: ok ? AppColors.success : AppColors.error));
                if (ok) Navigator.pop(context);
              }
            },
            child: Text(d.isActive ? 'تعطيل' : 'تفعيل'),
          ),
        ],
      ),
    );
  }
}
