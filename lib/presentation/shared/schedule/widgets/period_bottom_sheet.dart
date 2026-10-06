import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/utils/day_of_week_helper.dart';
import '../../../../domain/entities/access_period.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/user_search_field.dart';
import '../../../admin/users/controllers/users_controller.dart';
import '../../../admin/halls/controllers/halls_controller.dart';
import '../schedule_data_provider.dart';
import '../../../../data/providers.dart';

class PeriodBottomSheet extends ConsumerStatefulWidget {
  final AccessPeriod period;
  const PeriodBottomSheet({super.key, required this.period});

  @override
  ConsumerState<PeriodBottomSheet> createState() => _PeriodBottomSheetState();
}

class _PeriodBottomSheetState extends ConsumerState<PeriodBottomSheet> {
  late AccessType _type;
  String? _trainerId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _type = widget.period.accessType;
    _trainerId = widget.period.trainerId;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.period;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 12,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'تعديل الفترة',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              '${DayOfWeekHelper.name(p.dayOfWeek)} • ${p.startTime.substring(0, 5)} - ${p.endTime.substring(0, 5)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AccessType>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'نوع الوصول',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              items: AccessType.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.nameAr)))
                  .toList(),
              onChanged: (v) => setState(() {
                _type = v!;
                if (_type == AccessType.maintenance) {
                  _trainerId = null;
                }
              }),
            ),
            const SizedBox(height: 12),
            if (_type != AccessType.maintenance)
              _TrainerDropdown(
                value: _trainerId,
                onChanged: (v) => setState(() => _trainerId = v),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'حذف الفترة',
                    icon: Icons.delete_outline,
                    showArrow: false,
                    variant: AppButtonVariant.secondary,
                    isLoading: _loading,
                    onPressed: _delete,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'حفظ',
                    icon: Icons.save,
                    showArrow: false,
                    isLoading: _loading,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final updated = AccessPeriod(
      id: widget.period.id,
      hallId: widget.period.hallId,
      dayOfWeek: widget.period.dayOfWeek,
      startTime: widget.period.startTime,
      endTime: widget.period.endTime,
      accessType: _type,
      trainerId: _trainerId,
      titleOrReason: widget.period.titleOrReason,
      isActive: widget.period.isActive,
    );
    final res =
        await ref.read(hallRepositoryProvider).updateAccessPeriod(updated);
    setState(() => _loading = false);
    if (!mounted) return;
    res.fold(
      (l) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.message), backgroundColor: AppColors.error),
      ),
      (_) {
        ref.invalidate(accessPeriodsProvider(widget.period.hallId));
        ref.invalidate(scheduleDataProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم التحديث'), backgroundColor: AppColors.success),
        );
      },
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('حذف الفترة؟',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
            'هل أنت متأكد من حذف هذه الفترة؟ لا يمكن التراجع.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    final res =
        await ref.read(hallRepositoryProvider).deleteAccessPeriod(widget.period.id);
    setState(() => _loading = false);
    if (!mounted) return;
    res.fold(
      (l) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.message), backgroundColor: AppColors.error),
      ),
      (_) {
        ref.invalidate(accessPeriodsProvider(widget.period.hallId));
        ref.invalidate(scheduleDataProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم الحذف'), backgroundColor: AppColors.success),
        );
      },
    );
  }
}

class _TrainerDropdown extends ConsumerWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _TrainerDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersControllerProvider);
    return usersAsync.when(
      loading: () => const InputDecorator(
        decoration: InputDecoration(
            labelText: 'المدرب المناوب (اختياري)',
            prefixIcon: Icon(Icons.fitness_center)),
        child: Text('جاري تحميل المدربين...'),
      ),
      error: (error, _) => InputDecorator(
        decoration: const InputDecoration(
            labelText: 'المدرب المناوب (اختياري)',
            prefixIcon: Icon(Icons.fitness_center)),
        child: Text('تعذر التحميل: $error'),
      ),
      data: (users) {
        final trainers = users
            .where((user) => user.role == UserRole.trainer && user.isActive)
            .toList();
        return UserSearchField(
          users: trainers,
          labelText: 'المدرب المناوب (اختياري)',
          prefixIcon: Icons.fitness_center,
          selectedId: value,
          onSelected: (user) => onChanged(user?.id),
        );
      },
    );
  }
}
