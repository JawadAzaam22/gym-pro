import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/utils/day_of_week_helper.dart';
import '../../../../domain/entities/access_period.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/user_search_field.dart';
import '../../../admin/users/controllers/users_controller.dart';
import '../../../../data/providers.dart';
import '../controllers/halls_controller.dart';
import '../../../shared/widgets/app_toast.dart';

/// شاشة فترات قاعة واحدة.
///
/// أُعيد تصميمها بناءً على ملاحظة مباشرة: كانت مدة كل فترة قابلة للتغيير
/// يدويًا (ساعة / نصف ساعة / 45 دقيقة...) عبر نموذج إضافة هنا، وهذا يكسر
/// الالتزام بأن كل فترة = ساعة واحدة ثابتة، ويُنتج فترات غير متسقة.
/// الآن: الفترات تُولَّد تلقائيًا (ساعة واحدة فقط، لكل الأيام السبعة) من
/// ساعات عمل القاعة نفسها عند إنشائها أو تعديلها (من شاشة "تعديل قاعة")،
/// وهذه الشاشة تعرضها فقط — مع إمكانية تعيين/تغيير مدرب لكل فترة، أو حذفها.
/// لا يوجد هنا أي نموذج لإنشاء فترة بمدة مخصصة.
class AccessPeriodsScreen extends ConsumerWidget {
  final int hallId;
  final String? hallName;
  const AccessPeriodsScreen({super.key, this.hallId = 1, this.hallName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodsAsync = ref.watch(accessPeriodsProvider(hallId));
    final usersAsync = ref.watch(usersControllerProvider);
    final trainerNames = {
      for (final u in (usersAsync.value ?? [])
          .where((u) => u.role == UserRole.trainer))
        u.id: u.name,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('فترات ${hallName ?? 'القاعة'}')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.info),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الفترات تُولَّد تلقائيًا (ساعة واحدة) من ساعات عمل القاعة. لتغيير الأوقات عدّل القاعة من شاشة "القاعات".',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: periodsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => AsyncErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(accessPeriodsProvider(hallId))),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                      child: Text(
                          'لا توجد فترات بعد. تأكد أن للقاعة ساعات عمل صحيحة من شاشة "القاعات".',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted)));
                }
                final sorted = [...list]
                  ..sort((a, b) {
                    final d = a.dayOfWeek.compareTo(b.dayOfWeek);
                    return d != 0 ? d : a.startTime.compareTo(b.startTime);
                  });
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final p = sorted[i];
                    return AppCard(
                      padding: const EdgeInsets.all(12),
                      onTap: () => _assignTrainer(context, ref, p),
                      child: Row(children: [
                        Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8)),
                            child: Center(
                                child: Text(DayOfWeekHelper.name(p.dayOfWeek),
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10)))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('${p.startTime.substring(0, 5)} - ${p.endTime.substring(0, 5)}',
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                  p.trainerId != null
                                      ? (trainerNames[p.trainerId] ?? 'مدرب')
                                      : 'اضغط لتعيين مدرب',
                                  style: TextStyle(
                                      color: p.trainerId != null
                                          ? AppColors.primary
                                          : AppColors.textMuted,
                                      fontSize: 11,
                                      fontWeight: p.trainerId != null
                                          ? FontWeight.w600
                                          : FontWeight.normal)),
                            ])),
                        StatusBadge(
                            label: p.isActive ? 'نشط' : 'موقوف',
                            variant: p.isActive
                                ? BadgeVariant.active
                                : BadgeVariant.danger),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.error, size: 20),
                          onPressed: () => _confirmDelete(context, ref, p),
                        ),
                      ]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _assignTrainer(BuildContext context, WidgetRef ref, AccessPeriod p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        String? selected = p.trainerId;
        return StatefulBuilder(builder: (ctx, setD) {
          final usersAsync = ref.watch(usersControllerProvider);
          final trainers = (usersAsync.value ?? [])
              .where((u) => u.role == UserRole.trainer && u.isActive)
              .toList();
          return Padding(
            padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${DayOfWeekHelper.name(p.dayOfWeek)} • ${p.startTime.substring(0, 5)} - ${p.endTime.substring(0, 5)}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(height: 14),
                UserSearchField(
                  users: trainers,
                  labelText: 'المدرب المسؤول',
                  prefixIcon: Icons.fitness_center,
                  selectedId: selected,
                  onSelected: (u) => setD(() => selected = u?.id),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  if (p.trainerId != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _saveTrainer(context, ref, p, null);
                        },
                        child: const Text('إزالة المدرب'),
                      ),
                    ),
                  if (p.trainerId != null) const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _saveTrainer(context, ref, p, selected);
                      },
                      child: const Text('حفظ'),
                    ),
                  ),
                ]),
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> _saveTrainer(BuildContext context, WidgetRef ref,
      AccessPeriod p, String? trainerId) async {
    final updated = AccessPeriod(
      id: p.id,
      hallId: p.hallId,
      dayOfWeek: p.dayOfWeek,
      startTime: p.startTime,
      endTime: p.endTime,
      accessType: p.accessType,
      trainerId: trainerId,
      titleOrReason: p.titleOrReason,
      isActive: p.isActive,
    );
    final res =
        await ref.read(hallRepositoryProvider).updateAccessPeriod(updated);
    if (!context.mounted) return;
    res.fold(
      (l) => AppToast.error(context, l.message),
      (_) {
        ref.invalidate(accessPeriodsProvider(hallId));
        AppToast.success(context, 'تم التحديث');
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AccessPeriod p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('حذف الفترة؟'),
        content: Text(
            '${DayOfWeekHelper.name(p.dayOfWeek)} • ${p.startTime.substring(0, 5)} - ${p.endTime.substring(0, 5)}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await ref
                  .read(hallRepositoryProvider)
                  .deleteAccessPeriod(p.id);
              if (!context.mounted) return;
              res.fold(
                (l) => AppToast.error(context, l.message),
                (_) {
                  ref.invalidate(accessPeriodsProvider(hallId));
                  AppToast.success(context, 'تم الحذف');
                },
              );
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
