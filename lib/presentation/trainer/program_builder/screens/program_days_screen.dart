import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/day_of_week_helper.dart';
import '../../../../domain/entities/training_program.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../../data/providers.dart';
import '../../../../data/models/program_day_model.dart';
import '../controllers/program_builder_controller.dart';
import '../../../shared/widgets/app_toast.dart';

class ProgramDaysScreen extends ConsumerWidget {
  final int programId;
  final TrainingProgram? program;
  const ProgramDaysScreen({super.key, required this.programId, this.program});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(programDaysProvider(programId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(program?.name ?? 'أيام البرنامج #$programId'),
        actions: [
          if (program != null) ...[
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => context.push('/trainer/programs/new', extra: program),
            ),
            IconButton(
              icon: Icon(program!.isActive ? Icons.block : Icons.check_circle, size: 20),
              onPressed: () => _confirmDeactivate(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, size: 20, color: AppColors.error),
              onPressed: () => _confirmDeleteProgram(context, ref),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _addDay(context, ref), backgroundColor: AppColors.primary, icon: const Icon(Icons.add, color: Colors.white), label: const Text('يوم جديد', style: TextStyle(color: Colors.white))),
      body: daysAsync.when(
        loading: () => const LoadingIndicator(message: 'جاري تحميل الأيام...'),
        error: (e, _) => AsyncErrorView(error: e, onRetry: () => ref.invalidate(programDaysProvider(programId))),
        data: (days) {
          if (days.isEmpty) return const Center(child: Text('لا توجد أيام بعد', style: TextStyle(color: AppColors.textMuted)));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final d = days[i];
              return InkWell(
                onTap: () => context.push(
                    '/trainer/programs/$programId/days/${d.id}/exercises'),
                borderRadius: BorderRadius.circular(16),
                child: AppCard(
                  child: Row(children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Center(child: Text('${d.orderIndex + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(DayOfWeekHelper.name(d.dayOfWeek), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)), Text(d.muscleGroup ?? '', style: const TextStyle(color: AppColors.textMuted, fontSize: 11))])),
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

  void _confirmDeleteProgram(BuildContext context, WidgetRef ref) {
    if (program == null) return;
    final p = program!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('حذف البرنامج نهائياً؟', style: TextStyle(color: AppColors.error)),
        content: Text('سيتم حذف "${p.name}" وجميع أيامه وتمارينه. لا يمكن التراجع.', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref.read(programBuilderProvider.notifier).delete(p.id);
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
        content: const Text('سيتم حذف هذا اليوم وجميع تمارينه.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(programDatasourceProvider).deleteDay(dayId);
                ref.invalidate(programDaysProvider(programId));
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
    final muscleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          title: const Text('يوم جديد', style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: dayOfWeek,
                decoration: const InputDecoration(labelText: 'اليوم'),
                items: DayOfWeekHelper.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setState(() => dayOfWeek = v ?? 0),
              ),
              TextField(controller: muscleCtrl, decoration: const InputDecoration(labelText: 'المجموعة العضلية')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(programDatasourceProvider).addDay(ProgramDayModel(id: 0, programId: programId, dayOfWeek: dayOfWeek, muscleGroup: muscleCtrl.text.isEmpty ? null : muscleCtrl.text, orderIndex: 0));
                  ref.invalidate(programDaysProvider(programId));
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
    if (program == null) return;
    final p = program!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text(p.isActive ? 'تعطيل البرنامج؟' : 'تفعيل البرنامج؟', style: const TextStyle(color: AppColors.textPrimary)),
        content: Text('هل أنت متأكد من ${p.isActive ? 'تعطيل' : 'تفعيل'} "${p.name}"؟', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref.read(programBuilderProvider.notifier).deactivate(p.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'تم التحديث' : 'فشل'), backgroundColor: ok ? AppColors.success : AppColors.error));
                if (ok) Navigator.pop(context);
              }
            },
            child: Text(p.isActive ? 'تعطيل' : 'تفعيل'),
          ),
        ],
      ),
    );
  }
}
