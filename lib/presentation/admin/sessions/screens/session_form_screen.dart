import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/day_of_week_helper.dart';
import '../../../../domain/entities/session.dart';
import '../../../../domain/entities/access_period.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/user_search_field.dart';
import '../../../shared/auth/controllers/auth_controller.dart';
import '../../users/controllers/users_controller.dart';
import '../../halls/controllers/halls_controller.dart';
import '../controllers/sessions_controller.dart';
import '../../../../data/providers.dart';
import '../../../shared/widgets/app_toast.dart';

class SessionFormScreen extends ConsumerStatefulWidget {
  final Session? session;
  const SessionFormScreen({super.key, this.session});
  @override
  ConsumerState<SessionFormScreen> createState() => _SessionFormScreenState();
}

class _SessionFormScreenState extends ConsumerState<SessionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _capacity = TextEditingController(text: '20');
  String? _trainerId;
  int? _hallId;
  final List<AccessPeriod> _selectedPeriods = [];
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 30));
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.session != null) {
      final s = widget.session!;
      _name.text = s.name;
      _desc.text = s.description ?? '';
      _capacity.text = s.capacity.toString();
      _trainerId = s.trainerId;
      _hallId = s.hallId;
      _start = s.startDate;
      _end = s.endDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.session != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(isEdit ? 'تعديل الحصة' : 'حصة جماعية جديدة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AppCard(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                    label: 'اسم الحصة',
                    controller: _name,
                    prefixIcon: Icons.class_,
                    validator: (v) => Validators.required(v, 'الاسم')),
                const SizedBox(height: 12),
                AppTextField(
                    label: 'الوصف',
                    controller: _desc,
                    prefixIcon: Icons.description_outlined),
                const SizedBox(height: 12),
                _TrainerSearchField(
                    selectedId: _trainerId,
                    onChanged: (value) => setState(() => _trainerId = value)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: TextFormField(
                          controller: _capacity,
                          decoration: const InputDecoration(
                              labelText: 'السعة',
                              prefixIcon: Icon(Icons.people)),
                          keyboardType: TextInputType.number,
                          validator: Validators.capacity)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HallDropdown(
                      selectedId: _hallId,
                      locked: _selectedPeriods.isNotEmpty,
                      onChanged: (value) =>
                          setState(() => _hallId = value),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await context.push(
                      '/admin/schedule',
                      extra: {'selectionMode': true},
                    );
                    if (result is List<AccessPeriod> && result.isNotEmpty) {
                      // التحقق أن جميع الفترات لنفس القاعة
                      final firstHallId = result.first.hallId;
                      final allSameHall = result.every((p) => p.hallId == firstHallId);
                      if (!allSameHall) {
                        if (mounted) {
                          AppToast.error(context,
                              'جميع الفترات يجب أن تكون لنفس القاعة');
                        }
                        return;
                      }
                      setState(() {
                        _selectedPeriods.clear();
                        _selectedPeriods.addAll(result);
                        _hallId = firstHallId;
                      });
                    } else if (result is AccessPeriod) {
                      // توافق مع القديم: عنصر واحد
                      setState(() {
                        _selectedPeriods.clear();
                        _selectedPeriods.add(result);
                        _hallId = result.hallId;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_month, size: 14),
                  label: Text(
                    _selectedPeriods.isEmpty
                        ? 'اختيار المواعيد من الجدول'
                        : '${_selectedPeriods.length} فترات محددة',
                    style: TextStyle(
                      color: _selectedPeriods.isNotEmpty
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                if (_selectedPeriods.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 14, color: AppColors.info),
                            const SizedBox(width: 6),
                            const Text(
                              'الفترات المحددة:',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => setState(() {
                                _selectedPeriods.clear();
                                _hallId = null;
                              }),
                              child: const Text('مسح الكل',
                                  style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ..._selectedPeriods.map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.circle, size: 6, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${DayOfWeekHelper.name(p.dayOfWeek)} • ${p.startTime.substring(0, 5)} - ${p.endTime.substring(0, 5)}',
                                      style: const TextStyle(
                                          color: AppColors.textMuted, fontSize: 11),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() {
                                      _selectedPeriods.removeWhere((rp) => rp.id == p.id);
                                      if (_selectedPeriods.isEmpty) _hallId = null;
                                    }),
                                    child: const Icon(Icons.close, size: 14, color: AppColors.error),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: OutlinedButton.icon(
                          onPressed: () async {
                            final d = await showDatePicker(
                                context: context,
                                initialDate: _start,
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2027, 12, 31));
                            if (d != null) setState(() => _start = d);
                          },
                          icon: const Icon(Icons.calendar_today, size: 14),
                          label: Text(
                              'من: ${_start.toIso8601String().split('T').first}'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: OutlinedButton.icon(
                          onPressed: () async {
                            final d = await showDatePicker(
                                context: context,
                                initialDate: _end,
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2027, 12, 31));
                            if (d != null) setState(() => _end = d);
                          },
                          icon: const Icon(Icons.calendar_today, size: 14),
                          label: Text(
                              'إلى: ${_end.toIso8601String().split('T').first}'))),
                ]),
                const SizedBox(height: 16),
                AppButton(
                    label: isEdit ? 'حفظ التعديلات' : 'إنشاء الحصة',
                    icon: isEdit ? Icons.save : Icons.add,
                    isLoading: _loading,
                    onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final createdBy = ref.read(authControllerProvider).value?.id ?? '';
    final isEdit = widget.session != null;
    final trainerId = _trainerId;
    if (trainerId == null || trainerId.isEmpty || _hallId == null) {
      setState(() => _loading = false);
      AppToast.error(
          context, _hallId == null ? 'اختر القاعة أولاً' : 'اختر المدرب أولاً');
      return;
    }
    // استخدام أول فترة كـ accessPeriodId للتوافق القديم
    final firstPeriodId = _selectedPeriods.isNotEmpty ? _selectedPeriods.first.id : null;
    final s = Session(
      id: widget.session?.id ?? 0,
      name: _name.text.trim(),
      description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      hallId: _hallId!,
      trainerId: trainerId,
      accessPeriodId: firstPeriodId,
      startDate: _start,
      endDate: _end,
      capacity: int.parse(_capacity.text),
      status: widget.session?.status ?? SessionStatus.scheduled,
      createdBy: widget.session?.createdBy ?? createdBy,
      createdAt: widget.session?.createdAt ?? DateTime.now(),
    );
    final ok = isEdit
        ? await ref.read(sessionsControllerProvider.notifier).editSession(s)
        : await ref.read(sessionsControllerProvider.notifier).create(s);
    if (!ok) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('تعذّر حفظ الحصة، حاول مجددًا'),
            backgroundColor: AppColors.error));
      }
      return;
    }

    // بعد إنشاء/تعديل الكورس: ربط الفترات المتعددة في session_periods
    final sessionId = isEdit ? widget.session!.id : ref.read(sessionsControllerProvider).value?.last.id;
    if (sessionId != null && _selectedPeriods.isNotEmpty) {
      final periodIds = _selectedPeriods.map((p) => p.id).toList();
      await ref.read(sessionRepositoryProvider).createSessionPeriods(sessionId, periodIds);
    }

    // مزامنة مدرب الكورس لكل فترة محددة
    for (final period in _selectedPeriods) {
      final updated = AccessPeriod(
        id: period.id,
        hallId: period.hallId,
        dayOfWeek: period.dayOfWeek,
        startTime: period.startTime,
        endTime: period.endTime,
        accessType: period.accessType,
        trainerId: trainerId,
        titleOrReason: period.titleOrReason,
        isActive: period.isActive,
      );
      await ref.read(hallRepositoryProvider).updateAccessPeriod(updated);
    }

    setState(() => _loading = false);
    if (!mounted) return;
    AppToast.success(context, isEdit ? 'تم تحديث الحصة' : 'تم إنشاء الحصة');
    Navigator.pop(context);
  }
}

class _TrainerSearchField extends ConsumerWidget {
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _TrainerSearchField({required this.selectedId, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersControllerProvider);
    return usersAsync.when(
      loading: () => const InputDecorator(
        decoration: InputDecoration(
            labelText: 'المدرب', prefixIcon: Icon(Icons.person_outline)),
        child: Text('جاري تحميل المدربين...'),
      ),
      error: (error, _) => InputDecorator(
        decoration: const InputDecoration(
            labelText: 'المدرب', prefixIcon: Icon(Icons.person_outline)),
        child: Text('تعذر تحميل المدربين: $error'),
      ),
      data: (users) {
        final trainers = users
            .where((user) => user.role == UserRole.trainer && user.isActive)
            .toList();
        return UserSearchField(
          users: trainers,
          labelText: 'المدرب',
          prefixIcon: Icons.person_outline,
          selectedId: selectedId,
          onSelected: (user) => onChanged(user?.id),
          validator: (user) =>
              user == null ? 'اختر المدرب' : null,
        );
      },
    );
  }
}

class _HallDropdown extends ConsumerWidget {
  final int? selectedId;
  final bool locked;
  final ValueChanged<int?> onChanged;

  const _HallDropdown({
    required this.selectedId,
    required this.onChanged,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hallsAsync = ref.watch(hallsControllerProvider);
    return hallsAsync.when(
      loading: () => const InputDecorator(
        decoration: InputDecoration(labelText: 'القاعة'),
        child: Text('جاري تحميل القاعات...'),
      ),
      error: (error, _) => InputDecorator(
        decoration: const InputDecoration(labelText: 'القاعة'),
        child: Text('تعذر تحميل القاعات: $error'),
      ),
      data: (halls) {
        final activeHalls = halls
            .where((hall) => hall.isActive || hall.id == selectedId)
            .toList();
        final value = activeHalls.any((hall) => hall.id == selectedId)
            ? selectedId
            : null;
        return DropdownButtonFormField<int>(
          value: value,
          decoration: InputDecoration(
            labelText: locked ? 'القاعة (مقيّدة بالموعد)' : 'القاعة',
            prefixIcon: locked
                ? const Icon(Icons.lock_outline, size: 18)
                : null,
          ),
          hint: const Text('اختر القاعة'),
          items: activeHalls
              .map((hall) =>
                  DropdownMenuItem(value: hall.id, child: Text(hall.name)))
              .toList(),
          onChanged: locked ? null : onChanged,
          validator: (value) => value == null ? 'اختر القاعة' : null,
        );
      },
    );
  }
}
