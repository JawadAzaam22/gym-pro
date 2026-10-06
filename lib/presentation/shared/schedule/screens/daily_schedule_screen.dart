import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/utils/day_of_week_helper.dart';
import '../../../../core/utils/time_slot_generator.dart';
import '../../../../domain/entities/access_period.dart';
import '../../../../domain/entities/session.dart';
import '../schedule_data_provider.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/user_search_field.dart';
import '../../../admin/users/controllers/users_controller.dart';
import '../../../shared/auth/controllers/auth_controller.dart';
import '../widgets/period_bottom_sheet.dart';
import '../../../../data/providers.dart';

const _kSelectionMode = 'selectionMode';

class DailyScheduleScreen extends ConsumerStatefulWidget {
  const DailyScheduleScreen({super.key});

  @override
  ConsumerState<DailyScheduleScreen> createState() =>
      _DailyScheduleScreenState();
}

class _DailyScheduleScreenState extends ConsumerState<DailyScheduleScreen> {
  int _selectedDay = DateTime.now().weekday % 7;
  int? _selectedHallId;
  bool _showWeekly = false;
  final Set<int> _selectedPeriodIds = {};
  bool _isMultiSelectMode = false; // Independent multi-select mode for admin

  bool get _isSelectionMode {
    final extra = GoRouterState.of(context).extra;
    if (extra is Map && extra[_kSelectionMode] == true) return true;
    return _isMultiSelectMode;
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(scheduleDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // زر رجوع صريح عند وضع "تحديد متعدد" الداخلي فقط (الذي يفعّله
        // الأدمن بنفسه من القائمة، وليس وضع الاختيار القادم من راوتر آخر
        // الذي يملك سلوك رجوع طبيعيًا عبر الصفحة السابقة). بدونه لا توجد أي
        // طريقة للخروج من هذا الوضع إن لم يتم اختيار أي فترة بعد، لأن زر
        // "تبديل" نفسه يختفي أثناء وضع التحديد.
        leading: _isMultiSelectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'إلغاء التحديد المتعدد',
                onPressed: () => setState(() {
                  _isMultiSelectMode = false;
                  _selectedPeriodIds.clear();
                }),
              )
            : null,
        title: Text(_isSelectionMode
            ? 'اختر الفترات من الجدول (${_selectedPeriodIds.length})'
            : 'الجدول'),
        actions: [
          if (!_isSelectionMode)
            IconButton(
              icon: Icon(_showWeekly ? Icons.view_day : Icons.view_week),
              onPressed: () => setState(() => _showWeekly = !_showWeekly),
              tooltip: _showWeekly ? 'عرض يومي' : 'عرض أسبوعي',
            ),
          if (!_isSelectionMode)
            Consumer(
              builder: (context, ref, _) {
                final role = ref.watch(currentUserRoleProvider);
                if (role != UserRole.admin) return const SizedBox.shrink();
                return PopupMenuButton<String>(
                  icon: Icon(_isMultiSelectMode
                      ? Icons.checklist_rtl
                      : Icons.checklist),
                  tooltip: _isMultiSelectMode
                      ? 'خيارات التحديد المتعدد'
                      : 'تحديد متعدد (تعيين مدرب)',
                  onSelected: (value) {
                    if (value == 'toggle') {
                      setState(() => _isMultiSelectMode = !_isMultiSelectMode);
                    } else if (value == 'clear') {
                      setState(() => _selectedPeriodIds.clear());
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(_isMultiSelectMode
                              ? Icons.close
                              : Icons.checklist,
                          size: 18),
                          const SizedBox(width: 8),
                          Text(_isMultiSelectMode
                              ? 'إلغاء التحديد المتعدد'
                              : 'تحديد متعدد (تعيين مدرب)'),
                        ],
                      ),
                    ),
                    if (_isMultiSelectMode && _selectedPeriodIds.isNotEmpty)
                      const PopupMenuItem(
                        value: 'clear',
                        child: Row(
                          children: [
                            Icon(Icons.clear_all, size: 18),
                            SizedBox(width: 8),
                            Text('مسح التحديد'),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          if (_isSelectionMode) ...[
            IconButton(
              icon: Icon(
                _allSelectablePeriodsSelected()
                    ? Icons.deselect
                    : Icons.select_all,
              ),
              tooltip: _allSelectablePeriodsSelected()
                  ? 'إلغاء تحديد الكل'
                  : 'تحديد الكل',
              onPressed: () {
                final data = ref.read(scheduleDataProvider).value;
                if (data != null) _toggleSelectAll(data);
              },
            ),
            if (_selectedPeriodIds.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear_all),
                tooltip: 'مسح التحديد',
                onPressed: () => setState(() => _selectedPeriodIds.clear()),
              ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(scheduleDataProvider),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode && _selectedPeriodIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isMultiSelectMode
                  ? _showBulkActionBottomSheet
                  : _confirmMultiSelect,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.check, color: Colors.white),
              label: Text(
                'تم (${_selectedPeriodIds.length} فترات)',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
      body: dataAsync.when(
        loading: () => const LoadingIndicator(message: 'جاري تحميل الجدول...'),
        error: (e, _) => AsyncErrorView(
            error: e, onRetry: () => ref.invalidate(scheduleDataProvider)),
        data: (data) {
          if (_selectedHallId == null && data.hallMap.isNotEmpty) {
            _selectedHallId = data.hallMap.keys.first;
          }
          return _buildBody(data);
        },
      ),
    );
  }

  void _confirmMultiSelect() {
    if (_isMultiSelectMode) {
      _showBulkActionBottomSheet();
      return;
    }
    final data = ref.read(scheduleDataProvider).value;
    if (data == null) return;
    final selectedPeriods =
        data.periods.where((p) => _selectedPeriodIds.contains(p.id)).toList();
    context.pop(selectedPeriods);
  }

  void _showBulkActionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                'إجراء جماعي على ${_selectedPeriodIds.length} فترات',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Option 1: Assign Trainer
              _bulkActionTile(
                icon: Icons.fitness_center,
                title: 'تعيين مدرب',
                subtitle: 'عيّن مدربًا واحدًا لجميع الفترات المحددة',
                color: AppColors.info,
                onTap: () {
                  Navigator.pop(ctx);
                  _showAssignTrainerBottomSheet();
                },
              ),
              // Option 2: Change Access Type
              _bulkActionTile(
                icon: Icons.swap_horiz,
                title: 'تغيير نوع الوصول',
                subtitle: 'غيّر النوع (مختلط/سيدات/صيانة) لجميع الفترات',
                color: AppColors.warning,
                onTap: () {
                  Navigator.pop(ctx);
                  _showChangeAccessTypeBottomSheet();
                },
              ),
              // Option 3: Delete
              _bulkActionTile(
                icon: Icons.delete_forever,
                title: 'حذف الفترات',
                subtitle: 'احذف جميع الفترات المحددة نهائيًا (لا يمكن التراجع)',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirmBottomSheet();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignTrainerBottomSheet() {
    String? selectedTrainerId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final usersAsync = ref.watch(usersControllerProvider);
          final trainers = usersAsync.whenOrNull(
                data: (users) => users
                    .where((u) => u.role == UserRole.trainer && u.isActive)
                    .toList(),
              ) ??
              [];

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
                    'تعيين مدرب للفترات المحددة',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedPeriodIds.length} فترات سيتم تحديثها',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  UserSearchField(
                    users: trainers,
                    labelText: 'اختر المدرب',
                    prefixIcon: Icons.fitness_center,
                    selectedId: selectedTrainerId,
                    onSelected: (user) =>
                        setSheetState(() => selectedTrainerId = user?.id),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'إلغاء',
                          showArrow: false,
                          variant: AppButtonVariant.secondary,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'تعيين وتطبيق',
                          icon: Icons.check,
                          showArrow: false,
                          onPressed: () async {
                            if (selectedTrainerId == null) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                    content: Text('اختر مدرباً أولاً'),
                                    backgroundColor: AppColors.error),
                              );
                              return;
                            }
                            Navigator.pop(ctx);
                            await _assignTrainerToSelectedPeriods(selectedTrainerId!);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showChangeAccessTypeBottomSheet() {
    AccessType? selectedType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
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
                    'تغيير نوع الوصول للفترات المحددة',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedPeriodIds.length} فترات سيتم تحديثها',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<AccessType>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'نوع الوصول الجديد',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: AccessType.values
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.nameAr),
                            ))
                        .toList(),
                    onChanged: (v) => setSheetState(() => selectedType = v),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'إلغاء',
                          showArrow: false,
                          variant: AppButtonVariant.secondary,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'تطبيق',
                          icon: Icons.swap_horiz,
                          showArrow: false,
                          onPressed: () async {
                            if (selectedType == null) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                    content: Text('اختر نوع وصول أولاً'),
                                    backgroundColor: AppColors.error),
                              );
                              return;
                            }
                            Navigator.pop(ctx);
                            await _changeAccessTypeForSelectedPeriods(selectedType!);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmBottomSheet() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('حذف الفترات المحددة؟',
            style: TextStyle(color: AppColors.error)),
        content: Text(
          'سيتم حذف ${_selectedPeriodIds.length} فترة نهائيًا. لا يمكن التراجع عن هذا الإجراء.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء',
                  style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _deleteSelectedPeriods();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('حذف نهائي')),
        ],
      ),
    );
  }

  Future<void> _changeAccessTypeForSelectedPeriods(AccessType newType) async {
    final data = ref.read(scheduleDataProvider).value;
    if (data == null) return;

    final selectedPeriods =
        data.periods.where((p) => _selectedPeriodIds.contains(p.id)).toList();

    if (selectedPeriods.isEmpty) return;

    try {
      final repo = ref.read(hallRepositoryProvider);
      final futures = selectedPeriods.map((period) {
        final updated = AccessPeriod(
          id: period.id,
          hallId: period.hallId,
          dayOfWeek: period.dayOfWeek,
          startTime: period.startTime,
          endTime: period.endTime,
          accessType: newType,
          trainerId: period.trainerId,
          isActive: period.isActive,
          titleOrReason: period.titleOrReason,
        );
        return repo.updateAccessPeriod(updated);
      }).toList();

      await Future.wait(futures);

      if (!mounted) return;
      setState(() => _selectedPeriodIds.clear());
      ref.invalidate(scheduleDataProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تغيير النوع لـ ${selectedPeriods.length} فترة'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل التغيير: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteSelectedPeriods() async {
    final data = ref.read(scheduleDataProvider).value;
    if (data == null) return;

    final selectedPeriods =
        data.periods.where((p) => _selectedPeriodIds.contains(p.id)).toList();

    if (selectedPeriods.isEmpty) return;

    try {
      final repo = ref.read(hallRepositoryProvider);
      for (final period in selectedPeriods) {
        await repo.deleteAccessPeriod(period.id);
      }

      if (!mounted) return;
      setState(() => _selectedPeriodIds.clear());
      ref.invalidate(scheduleDataProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حذف ${selectedPeriods.length} فترة'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل الحذف: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Widget for bulk action options
  Widget _bulkActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: AppColors.textMuted),
            ],
          ),
        ),
      );

  Future<void> _assignTrainerToSelectedPeriods(String trainerId) async {
    final data = ref.read(scheduleDataProvider).value;
    if (data == null) return;

    final selectedPeriods =
        data.periods.where((p) => _selectedPeriodIds.contains(p.id)).toList();

    if (selectedPeriods.isEmpty) return;

    try {
      final repo = ref.read(hallRepositoryProvider);
      final futures = selectedPeriods.map((period) {
        final updated = AccessPeriod(
          id: period.id,
          hallId: period.hallId,
          dayOfWeek: period.dayOfWeek,
          startTime: period.startTime,
          endTime: period.endTime,
          accessType: period.accessType,
          trainerId: trainerId,
          isActive: period.isActive,
          titleOrReason: period.titleOrReason,
        );
        return repo.updateAccessPeriod(updated);
      }).toList();

      await Future.wait(futures);

      if (!mounted) return;
      setState(() => _selectedPeriodIds.clear());
      ref.invalidate(scheduleDataProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تعيين المدرب لـ ${selectedPeriods.length} فترة'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل التعيين: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  bool _allSelectablePeriodsSelected() {
    final data = ref.read(scheduleDataProvider).value;
    if (data == null) return false;
    final selectable = _selectablePeriodIds(data);
    return selectable.isNotEmpty &&
        selectable.every(_selectedPeriodIds.contains);
  }

  Set<int> _selectablePeriodIds(ScheduleData data) {
    final occupiedPeriodIds =
        data.sessionPeriods.values.expand((periodIds) => periodIds).toSet();
    return data.periods
        .where((period) =>
            period.hallId == _selectedHallId &&
            period.isActive &&
            !occupiedPeriodIds.contains(period.id))
        .map((period) => period.id)
        .toSet();
  }

  void _toggleSelectAll(ScheduleData data) {
    final selectable = _selectablePeriodIds(data);
    if (selectable.isEmpty) return;
    setState(() {
      if (selectable.every(_selectedPeriodIds.contains)) {
        _selectedPeriodIds.removeAll(selectable);
      } else {
        _selectedPeriodIds.addAll(selectable);
      }
    });
  }

  Widget _buildBody(ScheduleData data) {
    final halls = data.hallMap.entries.toList();
    final isWide = MediaQuery.of(context).size.width > 900;

    if (isWide && !_isSelectionMode) {
      return _buildWebLayout(data, halls);
    }
    return _buildMobileLayout(data, halls);
  }

  // ─── Web Layout ────────────────────────────────────────────────

  Widget _buildWebLayout(ScheduleData data, List<MapEntry<int, String>> halls) {
    return Column(
      children: [
        if (halls.length > 1)
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: halls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final hall = halls[i];
                final isSelected = hall.key == _selectedHallId;
                return ChoiceChip(
                  label: Text(hall.value),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceLow,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _selectedHallId = hall.key),
                );
              },
            ),
          ),
        Expanded(child: _buildWebGrid(data)),
      ],
    );
  }

  Widget _buildWebGrid(ScheduleData data) {
    final timeSlots = _buildTimeSlots(data);
    final role = ref.read(currentUserRoleProvider);
    final hall = data.halls.where((h) => h.id == _selectedHallId).firstOrNull;

    return Column(
      children: [
        if (role == UserRole.admin && hall != null)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('مدة الفراغ: ساعة واحدة',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
        if (timeSlots.isEmpty)
          const Expanded(
            child: Center(
              child: AppCard(
                child: Text('لا توجد فترات مسجلة',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            ),
          )
        else
          Expanded(child: _buildGridBody(timeSlots)),
      ],
    );
  }

  Widget _buildGridBody(List<_TimeSlot> timeSlots) {
    // عرض الجدول الأدنى: عمود الوقت (80) + 7 أيام × 140.
    const double kMinTableWidth = 7 * 140.0 + 80;
    // نستخدم LayoutBuilder لتحديد عرض "منتهٍ" (finite) صريح للجدول.
    // السبب: SingleChildScrollView الأفقي يمرّر عرضًا غير محدود (infinity)
    // لابنه، وConstrainedBox(minWidth) وحده لا يجعله محدودًا، فيحصل
    // ListView الرأسي بداخله على عرض لا نهائي فيفشل التخطيط ويظهر الجدول
    // فارغًا تمامًا (بلا رؤوس أيام ولا صفوف) — وهذا ما يظهر في الصورة.
    return LayoutBuilder(
      builder: (context, box) {
        final double tableWidth =
            box.maxWidth.isFinite && box.maxWidth > kMinTableWidth
                ? box.maxWidth
                : kMinTableWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            height: box.maxHeight.isFinite ? box.maxHeight : null,
            child: _buildGridColumn(timeSlots),
          ),
        );
      },
    );
  }

  Widget _buildGridColumn(List<_TimeSlot> timeSlots) {
    return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                  const SizedBox(
                      width: 80,
                      child: Center(
                          child: Text('الوقت',
                              style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)))),
                  for (int day = 0; day < 7; day++)
                    SizedBox(
                      width: 140,
                      child: Center(
                        child: Text(DayOfWeekHelper.name(day),
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView.builder(
                itemCount: timeSlots.length,
                itemBuilder: (_, rowIdx) {
                  final slot = timeSlots[rowIdx];
                  return Container(
                    constraints: const BoxConstraints(minHeight: 56),
                    decoration: BoxDecoration(
                      color: rowIdx.isEven
                          ? AppColors.surfaceLow.withOpacity(0.3)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Center(
                            child: Text(
                              '${slot.startTime.substring(0, 5)}\n${slot.endTime.substring(0, 5)}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        for (int day = 0; day < 7; day++)
                          _buildWebCell(slot.cellsByDay[day], day),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
  }

  Widget _buildWebCell(_ScheduleCell? cell, int day) {
    if (cell == null) {
      return const SizedBox(width: 140, height: 56);
    }

    // Unconfigured cell
    if (cell.isUnconfigured) {
      final role = ref.read(currentUserRoleProvider);
      return SizedBox(
        width: 140,
        height: 56,
        child: GestureDetector(
          onTap: role == UserRole.admin
              ? () => _showCreatePeriodSheet(
                    hallId: cell.period.hallId,
                    dayOfWeek: day,
                    startTime: cell.period.startTime,
                    endTime: cell.period.endTime,
                  )
              : null,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.surfaceOverlay.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: AppColors.border.withOpacity(0.5), width: 1),
            ),
            child: Center(
              child: Text(
                role == UserRole.admin ? 'إنشاء فترة' : 'غير مُهيَّأة',
                style: TextStyle(
                    color: role == UserRole.admin
                        ? AppColors.primary
                        : AppColors.textMuted,
                    fontSize: 9),
              ),
            ),
          ),
        ),
      );
    }

    final colors = _getCellColors(cell);
    final isOccupied = cell.session != null;

    return SizedBox(
      width: 140,
      height: 56,
      child: GestureDetector(
        onTap: () => _onCellTap(cell),
        child: Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: colors.$1.withOpacity(0.18),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: colors.$1.withOpacity(0.4), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getCellMainText(cell),
                style: TextStyle(
                    color: colors.$2,
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isOccupied)
                Text(
                  _getCellSubText(cell),
                  style:
                      TextStyle(color: colors.$2.withOpacity(0.7), fontSize: 8),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Mobile Layout ─────────────────────────────────────────────

  Widget _buildMobileLayout(
      ScheduleData data, List<MapEntry<int, String>> halls) {
    final role = ref.read(currentUserRoleProvider);
    final hall = data.halls.where((h) => h.id == _selectedHallId).firstOrNull;

    return Column(
      children: [
        if (halls.length > 1)
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: halls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final hall = halls[i];
                final isSelected = hall.key == _selectedHallId;
                return ChoiceChip(
                  label: Text(hall.value),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceLow,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _selectedHallId = hall.key),
                );
              },
            ),
          ),
        if (role == UserRole.admin && hall != null)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text('مدة الفراغ: ساعة واحدة',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
        _DaySelector(
            selectedDay: _selectedDay,
            onDaySelected: (d) => setState(() => _selectedDay = d)),
        Expanded(child: _buildMobileDayList(data)),
      ],
    );
  }

  Widget _buildMobileDayList(ScheduleData data) {
    final hall = data.halls.where((h) => h.id == _selectedHallId).firstOrNull;
    if (hall == null) {
      return const Center(
        child: AppCard(
          child:
              Text('اختر قاعة', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    const slotMinutes = 60;
    final generatedSlots = generateTimeSlots(
      openTime: hall.openTime,
      closeTime: hall.closeTime,
      slotMinutes: slotMinutes,
    );

    final matchedPeriods = data.periods
        .where((p) =>
            p.dayOfWeek == _selectedDay &&
            p.isActive &&
            p.hallId == _selectedHallId)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final periodMap = <String, AccessPeriod>{
      for (final p in matchedPeriods) '${p.startTime}-${p.endTime}': p,
    };

    final cells = <_ScheduleCell>[];
    for (final gen in generatedSlots) {
      final key = '${gen.start}-${gen.end}';
      final period = periodMap[key];
      if (period != null) {
        cells.add(_buildCellForPeriod(period, data));
      } else {
        cells.add(_ScheduleCell(
          period: AccessPeriod(
            id: 0,
            hallId: _selectedHallId!,
            dayOfWeek: _selectedDay,
            startTime: gen.start,
            endTime: gen.end,
            accessType: AccessType.mixed,
            isActive: true,
          ),
          isUnconfigured: true,
        ));
      }
    }

    if (cells.isEmpty) {
      return const Center(
        child: AppCard(
          child: Text('لا توجد فترات لهذا اليوم',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(scheduleDataProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: cells.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _buildMobileCell(cells[i], data),
      ),
    );
  }

  Widget _buildMobileCell(_ScheduleCell cell, ScheduleData data) {
    // Unconfigured cell
    if (cell.isUnconfigured) {
      final role = ref.read(currentUserRoleProvider);
      return AppCard(
        padding: const EdgeInsets.all(12),
        onTap: role == UserRole.admin
            ? () => _showCreatePeriodSheet(
                  hallId: cell.period.hallId,
                  dayOfWeek: cell.period.dayOfWeek,
                  startTime: cell.period.startTime,
                  endTime: cell.period.endTime,
                )
            : null,
        child: Row(children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cell.period.startTime.substring(0, 5)} - ${cell.period.endTime.substring(0, 5)}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  role == UserRole.admin ? 'انقر لإنشاء فترة' : 'غير مُهيَّأة',
                  style: TextStyle(
                      color: role == UserRole.admin
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontSize: 11),
                ),
              ],
            ),
          ),
          if (role == UserRole.admin)
            const Icon(Icons.add_circle_outline,
                color: AppColors.primary, size: 20),
        ]),
      );
    }

    final colors = _getCellColors(cell);
    final isOccupied = cell.session != null;
    final isMaintenance = cell.period.accessType == AccessType.maintenance;
    final isSelected =
        _isSelectionMode && _selectedPeriodIds.contains(cell.period.id);

    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () => _onCellTap(cell),
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary, width: 2),
              )
            : null,
        padding: isSelected ? const EdgeInsets.all(8) : EdgeInsets.zero,
        child: Row(children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : colors.$1,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${cell.period.startTime.substring(0, 5)} - ${cell.period.endTime.substring(0, 5)}',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.$1.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getCellMainText(cell),
                        style: TextStyle(
                            color: colors.$2,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (isOccupied)
                  Text(
                    _getCellSubText(cell),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (cell.period.trainerId != null)
                  Text(
                    'المناوب: ${_resolveUserName(cell.period.trainerId!, data: data)}',
                    style: const TextStyle(color: AppColors.info, fontSize: 10),
                  ),
                if (isMaintenance && cell.period.titleOrReason != null)
                  Text(
                    cell.period.titleOrReason!,
                    style:
                        const TextStyle(color: AppColors.warning, fontSize: 10),
                  ),
              ],
            ),
          ),
          if (_isSelectionMode && !isOccupied)
            Icon(
              isSelected ? Icons.check_circle : Icons.add_circle_outline,
              color: isSelected ? AppColors.primary : AppColors.success,
              size: 20,
            )
          else if (isOccupied)
            Icon(
              cell.session != null ? Icons.groups : Icons.person,
              color: colors.$1.withOpacity(0.5),
              size: 18,
            ),
        ]),
      ),
    );
  }

  // ─── Cell Logic ────────────────────────────────────────────────

  _ScheduleCell _buildCellForPeriod(AccessPeriod period, ScheduleData data) {
    Session? matchedSession;
    for (final s in data.sessions) {
      // تحقق من العمود القديم (access_period_id المفرد)
      if (s.accessPeriodId == period.id &&
          s.status != SessionStatus.cancelled) {
        matchedSession = s;
        break;
      }
      // تحقق من جدول session_periods (فترة متعددة)
      final relatedPeriods = data.sessionPeriods[s.id];
      if (relatedPeriods != null &&
          relatedPeriods.contains(period.id) &&
          s.status != SessionStatus.cancelled) {
        matchedSession = s;
        break;
      }
    }

    return _ScheduleCell(
      period: period,
      session: matchedSession,
    );
  }

  (Color, Color) _getCellColors(_ScheduleCell cell) {
    final userId = ref.read(authControllerProvider).value?.id;
    final role = ref.read(currentUserRoleProvider);
    final data = ref.read(scheduleDataProvider).value;

    if (cell.period.accessType == AccessType.maintenance) {
      return (AppColors.warning, AppColors.warning);
    }
    if (cell.session != null) {
      final isMySession = userId != null &&
          data != null &&
          ((role == UserRole.trainer && cell.session!.trainerId == userId) ||
              (role == UserRole.trainee &&
                  data.myBookingSessionIds.contains(cell.session!.id)));
      if (isMySession) {
        return (AppColors.info, AppColors.info);
      }
      return (AppColors.success, AppColors.success);
    }
    if (cell.period.accessType == AccessType.women) {
      return (AppColors.primary, AppColors.primary);
    }
    if (cell.period.accessType == AccessType.courseReserved) {
      return (AppColors.warning, AppColors.warning);
    }
    return (AppColors.borderStrong, AppColors.textMuted);
  }

  String _getCellMainText(_ScheduleCell cell) {
    if (cell.period.accessType == AccessType.maintenance) return 'صيانة';
    if (cell.session != null) return cell.session!.name;
    if (cell.period.accessType == AccessType.women) return 'سيدات - شاغرة';
    if (cell.period.accessType == AccessType.courseReserved) {
      return 'محجوزة لدورة';
    }
    return 'شاغرة';
  }

  String _getCellSubText(_ScheduleCell cell) {
    if (cell.session != null) {
      final trainerName = _resolveUserName(cell.session!.trainerId, data: null);
      return '$trainerName • سعة ${cell.session!.capacity}';
    }
    return cell.period.accessType.nameAr;
  }

  // ─── Time Slots Builder ───────────────────────────────────────

  List<_TimeSlot> _buildTimeSlots(ScheduleData data) {
    final hall = data.halls.where((h) => h.id == _selectedHallId).firstOrNull;
    if (hall == null) return [];

    const slotMinutes = 60;
    final generatedSlots = generateTimeSlots(
      openTime: hall.openTime,
      closeTime: hall.closeTime,
      slotMinutes: slotMinutes,
    );

    final periodMap = <String, Map<int, AccessPeriod>>{};
    for (final p in data.periods) {
      if (!p.isActive) continue;
      if (_selectedHallId != null && p.hallId != _selectedHallId) continue;
      final key = '${p.startTime}-${p.endTime}';
      periodMap.putIfAbsent(key, () => {});
      periodMap[key]![p.dayOfWeek] = p;
    }

    final slots = <_TimeSlot>[];
    for (final gen in generatedSlots) {
      final key = '${gen.start}-${gen.end}';
      final cellsByDay = <int, _ScheduleCell>{};
      final matchedPeriods = periodMap[key] ?? {};

      for (int day = 0; day < 7; day++) {
        final period = matchedPeriods[day];
        if (period != null) {
          cellsByDay[day] = _buildCellForPeriod(period, data);
        } else {
          cellsByDay[day] = _ScheduleCell(
            period: AccessPeriod(
              id: 0,
              hallId: _selectedHallId ?? 0,
              dayOfWeek: day,
              startTime: gen.start,
              endTime: gen.end,
              accessType: AccessType.mixed,
              isActive: true,
            ),
            isUnconfigured: true,
          );
        }
      }

      slots.add(_TimeSlot(
        startTime: gen.start,
        endTime: gen.end,
        cellsByDay: cellsByDay,
      ));
    }

    return slots;
  }

  // ─── Cell Tap ─────────────────────────────────────────────────

  void _onCellTap(_ScheduleCell cell) {
    if (_isSelectionMode) {
      if (cell.isUnconfigured || cell.session != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('هذه الفترة مشغولة بالفعل'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
      setState(() {
        if (_selectedPeriodIds.contains(cell.period.id)) {
          _selectedPeriodIds.remove(cell.period.id);
        } else {
          _selectedPeriodIds.add(cell.period.id);
        }
      });
      return;
    }

    // Unconfigured cell: admin creates, others see nothing
    if (cell.isUnconfigured) {
      final role = ref.read(currentUserRoleProvider);
      if (role == UserRole.admin) {
        _showCreatePeriodSheet(
          hallId: cell.period.hallId,
          dayOfWeek: cell.period.dayOfWeek,
          startTime: cell.period.startTime,
          endTime: cell.period.endTime,
        );
      }
      return;
    }

    final role = ref.read(currentUserRoleProvider);

    // Admin: full edit bottom sheet
    if (role == UserRole.admin) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PeriodBottomSheet(period: cell.period),
      );
      return;
    }

    // Reception: empty cell → book private session; occupied → read-only
    if (role == UserRole.reception) {
      if (cell.session != null) {
        _showReadonlyDetails(cell);
      } else {
        _showReceptionBookingOption(cell);
      }
      return;
    }

    // Trainer / Trainee: always read-only
    _showReadonlyDetails(cell);
  }

  void _showReadonlyDetails(_ScheduleCell cell) {
    final p = cell.period;
    final data = ref.read(scheduleDataProvider).value;
    final trainerName = p.trainerId != null && data != null
        ? data.userMap[p.trainerId] ?? ''
        : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
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
                'تفاصيل الفترة',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                '${DayOfWeekHelper.name(p.dayOfWeek)} • ${p.startTime.substring(0, 5)} - ${p.endTime.substring(0, 5)}',
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _readonlyRow('نوع الوصول', p.accessType.nameAr),
              if (trainerName.isNotEmpty)
                _readonlyRow('المدرب المناوب', trainerName),
              if (cell.session != null) ...[
                const Divider(height: 24),
                _readonlyRow('الجلسة', cell.session!.name),
                _readonlyRow('السعة', '${cell.session!.capacity}'),
              ],
              const SizedBox(height: 16),
              AppButton(
                label: 'إغلاق',
                showArrow: false,
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showReceptionBookingOption(_ScheduleCell cell) {
    final p = cell.period;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
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
                'حجز جلسة خاصة',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                '${DayOfWeekHelper.name(p.dayOfWeek)} • ${p.startTime.substring(0, 5)} - ${p.endTime.substring(0, 5)}',
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Text(
                'هل تريد حجز جلسة خاصة في هذه الفترة؟',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'إلغاء',
                      showArrow: false,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'تأكيد الحجز',
                      icon: Icons.check,
                      showArrow: false,
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/reception/bookings/private');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreatePeriodSheet({
    required int hallId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) {
    AccessType type = AccessType.mixed;
    String? trainerId;
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
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
                  'إنشاء فترة جديدة',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DayOfWeekHelper.name(dayOfWeek)} • ${startTime.substring(0, 5)} - ${endTime.substring(0, 5)}',
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AccessType>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'نوع الوصول'),
                  items: AccessType.values
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e.nameAr)))
                      .toList(),
                  onChanged: (v) => setSheetState(() => type = v!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'إلغاء',
                        showArrow: false,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'إنشاء',
                        icon: Icons.add,
                        showArrow: false,
                        isLoading: loading,
                        onPressed: loading
                            ? null
                            : () async {
                                setSheetState(() => loading = true);
                                final repo = ref.read(hallRepositoryProvider);
                                final res = await repo.createAccessPeriod(
                                  AccessPeriod(
                                    id: 0,
                                    hallId: hallId,
                                    dayOfWeek: dayOfWeek,
                                    startTime: startTime,
                                    endTime: endTime,
                                    accessType: type,
                                    trainerId: trainerId,
                                    isActive: true,
                                  ),
                                );
                                setSheetState(() => loading = false);
                                if (!context.mounted) return;
                                res.fold(
                                  (l) => ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                          content: Text(l.message),
                                          backgroundColor: AppColors.error)),
                                  (_) {
                                    ref.invalidate(scheduleDataProvider);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('تم إنشاء الفترة'),
                                          backgroundColor: AppColors.success),
                                    );
                                  },
                                );
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _readonlyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────

  String _resolveUserName(String? userId, {required ScheduleData? data}) {
    if (userId == null || userId.isEmpty) return '';
    if (data != null) return data.userMap[userId] ?? '';
    final users = ref.read(usersControllerProvider).value ?? [];
    try {
      return users.firstWhere((u) => u.id == userId).name;
    } catch (_) {
      return '';
    }
  }
}

// ─── Internal Types ─────────────────────────────────────────────

class _ScheduleCell {
  final AccessPeriod period;
  final Session? session;
  final bool isUnconfigured;
  const _ScheduleCell({
    required this.period,
    this.session,
    this.isUnconfigured = false,
  });
}

class _TimeSlot {
  final String startTime;
  final String endTime;
  final Map<int, _ScheduleCell> cellsByDay;

  const _TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.cellsByDay,
  });
}

class _DaySelector extends StatelessWidget {
  final int selectedDay;
  final ValueChanged<int> onDaySelected;
  const _DaySelector({required this.selectedDay, required this.onDaySelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final isSelected = i == selectedDay;
          return GestureDetector(
            onTap: () => onDaySelected(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border),
              ),
              child: Text(DayOfWeekHelper.name(i),
                  style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ),
          );
        },
      ),
    );
  }
}
