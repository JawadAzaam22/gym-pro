import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/day_of_week_helper.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../../data/models/private_training_schedule_model.dart';
import '../../../../data/providers.dart';
import '../../../shared/auth/controllers/auth_controller.dart';
import '../controllers/private_schedule_controller.dart';
import '../../../../domain/entities/trainer_trainee.dart';
import '../../../../domain/entities/private_training_schedule.dart';
import '../../../shared/widgets/app_toast.dart';

class PrivateSessionsScreen extends ConsumerStatefulWidget {
  const PrivateSessionsScreen({super.key});

  @override
  ConsumerState<PrivateSessionsScreen> createState() => _PrivateSessionsScreenState();
}

class _PrivateSessionsScreenState extends ConsumerState<PrivateSessionsScreen> {
  // حُذفت "الجلسات الفردية" (المواعيد لمرة واحدة) نهائيًا: كانت ميزة غير
  // مستخدمة فعليًا في العمل اليومي، والحل الذي استقر عليه صاحب المشروع هو
  // الاعتماد فقط على "المواعيد الثابتة" الأسبوعية المتكررة بين كل مدرب
  // ومتدربه. لا حاجة بعد الآن لتبويبات أو TabController.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // لا AppBar هنا: الـ shell الخارجي (ReceptionShellScreen) يعرض شريط
      // العنوان أصلًا.
      backgroundColor: AppColors.background,
      body: _FixedScheduleTab(),
    );
  }
}

class _FixedScheduleTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FixedScheduleTab> createState() => _FixedScheduleTabState();
}

class _FixedScheduleTabState extends ConsumerState<_FixedScheduleTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedTrainerTraineeIdProvider.notifier).state = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final relationsAsync = ref.watch(activeTrainerTraineesProvider);
    final selectedRelationId = ref.watch(selectedTrainerTraineeIdProvider);

    return Column(
      children: [
        // Relation Selector
        AppCard(
          margin: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'اختر علاقة مدرب-متدرب',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (selectedRelationId != null)
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('إضافة موعد'),
                      onPressed: () => _showAddScheduleDialog(context, ref, selectedRelationId),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              relationsAsync.when(
                loading: () => const LoadingIndicator(message: 'جاري تحميل العلاقات...'),
                error: (e, _) => AsyncErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(activeTrainerTraineesProvider),
                ),
                data: (relations) {
                  if (relations.isEmpty) {
                    return const Text(
                      'لا توجد علاقات نشطة',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    );
                  }
                  return _RelationSelector(
                    relations: relations,
                    selectedId: selectedRelationId,
                    onSelected: (id) {
                      ref.read(selectedTrainerTraineeIdProvider.notifier).state = id;
                    },
                  );
                },
              ),
            ],
          ),
        ),

        // Schedule Display
        if (selectedRelationId != null)
          Expanded(
            child: _ScheduleWeekView(relationId: selectedRelationId),
          )
        else
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 48, color: AppColors.textMuted),
                  SizedBox(height: 8),
                  Text(
                    'اختر علاقة لعرض مواعيدها الثابتة',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showAddScheduleDialog(
    BuildContext context,
    WidgetRef ref,
    int trainerTraineeId,
  ) {
    int selectedDay = DateTime.now().weekday % 7;
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: TimeOfDay.now().minute);
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          title: const Text('إضافة موعد ثابت',
              style: TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DaySelector(
                  selectedDay: selectedDay,
                  onChanged: (day) => setState(() => selectedDay = day),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: startTime,
                    );
                    if (picked != null) setState(() => startTime = picked);
                  },
                  icon: const Icon(Icons.access_time, size: 14),
                  label: Text(
                      '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: endTime,
                    );
                    if (picked != null) setState(() => endTime = picked);
                  },
                  icon: const Icon(Icons.access_time_filled, size: 14),
                  label: Text(
                      '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setState(() => isSubmitting = true);
                      final recordedBy =
                          ref.read(authControllerProvider).value?.id ?? '';
                      final slot = PrivateTrainingScheduleModel(
                        id: 0,
                        trainerTraineeId: trainerTraineeId,
                        dayOfWeek: selectedDay,
                        startTime:
                            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                        endTime:
                            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                        isActive: true,
                        createdBy: recordedBy,
                        createdAt: DateTime.now(),
                      );
                      final res = await ref
                          .read(bookingRepositoryProvider)
                          .addScheduleSlot(slot.toEntity());
                      String? errorMsg;
                      res.fold((f) => errorMsg = f.message, (_) {});
                      if (!ctx.mounted) return;
                      setState(() => isSubmitting = false);
                      if (errorMsg != null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text(errorMsg!),
                            backgroundColor: AppColors.error));
                        return;
                      }
                      Navigator.pop(ctx);
                      ref.invalidate(privateScheduleForRelationProvider(trainerTraineeId));
                      AppToast.success(context, 'تمت إضافة الموعد الثابت');
                    },
              child: isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

/// قائمة علاقات مدرب-متدرب للاختيار منها. كانت هذه Wrap من ChoiceChip تعرض
/// المعرّفات الخام (UUID) مباشرة ('${rel.trainerId} • ${rel.traineeId}')
/// بدل الأسماء — خطأ واضح للمستخدم. كما أن Wrap من رقائق تكبر بشكل غير
/// منظّم كلما زاد عدد العلاقات. استبدلناها بقائمة عمودية قابلة للتمرير
/// (بارتفاع محدود) من بطاقات واضحة تعرض "المدرب ← المتدرب".
class _RelationSelector extends StatelessWidget {
  final List<TrainerTrainee> relations;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  const _RelationSelector({
    required this.relations,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 260),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: relations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, i) {
          final rel = relations[i];
          final isSelected = selectedId == rel.id;
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onSelected(rel.id),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.12)
                    : AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.sports_gymnastics,
                      size: 16,
                      color:
                          isSelected ? AppColors.primary : AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${rel.trainerName ?? 'مدرب'} ← ${rel.traineeName ?? 'متدرب'}',
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle,
                        size: 18, color: AppColors.primary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  final int selectedDay;
  final ValueChanged<int> onChanged;

  const _DaySelector({required this.selectedDay, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('اليوم',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DayOfWeekHelper.entries.map((entry) {
            final isSelected = entry.key == selectedDay;
            return ChoiceChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (_) => onChanged(entry.key),
              selectedColor: AppColors.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ScheduleWeekView extends ConsumerWidget {
  final int relationId;

  const _ScheduleWeekView({required this.relationId});

  String _to12Hour(String time24) {
    try {
      final parts = time24.split(':');
      if (parts.length < 2) return time24;
      int hour = int.parse(parts[0]);
      final minute = parts[1].substring(0, 2);
      if (hour == 0) return '12:$minute ص';
      if (hour < 12) return '$hour:$minute ص';
      if (hour == 12) return '12:$minute م';
      return '${hour - 12}:$minute م';
    } catch (_) {
      return time24;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(privateScheduleForRelationProvider(relationId));
    final relationAsync = ref.watch(trainerTraineeByIdProvider(relationId));

    return scheduleAsync.when(
      loading: () => const LoadingIndicator(message: 'جاري تحميل المواعيد...'),
      error: (e, _) => AsyncErrorView(
        error: e,
        onRetry: () => ref.invalidate(privateScheduleForRelationProvider(relationId)),
      ),
      data: (schedule) {
        return relationAsync.when(
          loading: () => const LoadingIndicator(message: 'جاري تحميل بيانات العلاقة...'),
          error: (e, _) => AsyncErrorView(
            error: e,
            onRetry: () => ref.invalidate(trainerTraineeByIdProvider(relationId)),
          ),
          data: (relation) {
            if (relation == null) {
              return const Center(
                child: Text('العلاقة غير موجودة',
                    style: TextStyle(color: AppColors.error)),
              );
            }

            // Group by day
            final byDay = <int, List<PrivateTrainingSchedule>>{};
            for (final s in schedule) {
              byDay.putIfAbsent(s.dayOfWeek, () => []).add(s);
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: DayOfWeekHelper.entries.map((entry) {
                final day = entry.key;
                final dayName = entry.value;
                final slots = byDay[day] ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            dayName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${relation.trainerName} • ${relation.traineeName}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (slots.isEmpty)
                      AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'لا توجد مواعيد',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ),
                        ),
                      )
                    else
                      ...slots.map((slot) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AppCard(
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.info.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.schedule, color: AppColors.info),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_to12Hour(slot.startTime)} - ${_to12Hour(slot.endTime)}',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '${relation.trainerName} / ${relation.traineeName}',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'حذف',
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18, color: AppColors.error),
                                    onPressed: () => _confirmDelete(context, ref, slot.id),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.surfaceLow,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                    const SizedBox(height: 12),
                  ],
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, int scheduleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('حذف الموعد الثابت؟',
            style: TextStyle(color: AppColors.error)),
        content: const Text(
            'هل أنت متأكد من حذف هذا الموعد الثابت؟ لا يمكن التراجع.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      try {
        await ref.read(bookingDatasourceProvider).deleteScheduleSlot(scheduleId);
        ref.invalidate(privateScheduleForRelationProvider(relationId));
        AppToast.success(context, 'تم الحذف');
      } catch (e) {
        AppToast.error(context, 'فشل الحذف: $e');
      }
    }
  }
}