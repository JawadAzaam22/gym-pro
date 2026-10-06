import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/enums.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/user_search_field.dart';
import '../../../shared/auth/controllers/auth_controller.dart';
import '../../../admin/users/controllers/users_controller.dart';
import '../../assignment/controllers/trainer_assignment_controller.dart';
import '../controllers/membership_controller.dart';
import '../../../../data/providers.dart';
import '../../../shared/widgets/app_toast.dart';

class MembershipScreen extends ConsumerStatefulWidget {
  const MembershipScreen({super.key});
  @override
  ConsumerState<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends ConsumerState<MembershipScreen> {
  String? _selectedTraineeId;
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 30));
  bool _loading = false;
  MembershipStatus? _currentStatus;
  DateTime? _currentEndDate;

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
    _end = DateTime.now().add(const Duration(days: 30));
  }

  Future<void> _onTraineeSelected(String? traineeId) async {
    setState(() => _selectedTraineeId = traineeId);
    _currentStatus = null;
    _currentEndDate = null;

    if (traineeId == null) return;

    final result = await ref
        .read(membershipRepositoryProvider)
        .getActiveMembership(traineeId);

    if (!mounted || _selectedTraineeId != traineeId) return;

    result.fold(
      (_) {},
      (membership) {
        if (membership != null) {
          final today = DateTime.now();
          final normalizedEnd = DateTime(
              membership.endDate.year, membership.endDate.month, membership.endDate.day);
          final normalizedToday = DateTime(today.year, today.month, today.day);
          
          setState(() {
            _currentStatus = membership.status;
            _currentEndDate = membership.endDate;
            _end = normalizedEnd.isAfter(normalizedToday)
                ? DateTime(normalizedEnd.year, normalizedEnd.month, normalizedEnd.day + 30)
                : DateTime(today.year, today.month, today.day + 30);
          });
        } else {
          setState(() {
            _currentStatus = null;
            _currentEndDate = null;
            _start = DateTime.now();
            _end = DateTime.now().add(const Duration(days: 30));
          });
        }
      },
    );
  }

  Future<void> _confirmAndSave() async {
    if (_selectedTraineeId == null) {
      AppToast.error(context, 'اختر المتدرب أولاً');
      return;
    }

    if (_currentStatus != null && _currentEndDate != null) {
      // Renewal mode - validate new end date is after current end date
      final normalizedNewEnd = DateTime(_end.year, _end.month, _end.day);
      final normalizedCurrentEnd = DateTime(
          _currentEndDate!.year, _currentEndDate!.month, _currentEndDate!.day);

      if (!normalizedNewEnd.isAfter(normalizedCurrentEnd)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('اختر تاريخ انتهاء بعد تاريخ العضوية الحالي'),
              backgroundColor: AppColors.error),
        );
        return;
      }
    } else {
      // New membership mode - validate dates
      final normalizedStart = DateTime(_start.year, _start.month, _start.day);
      final normalizedEnd = DateTime(_end.year, _end.month, _end.day);
      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);

      if (!normalizedStart.isBefore(normalizedEnd)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تاريخ البداية يجب أن يكون قبل تاريخ النهاية'),
              backgroundColor: AppColors.error),
        );
        return;
      }
      if (!normalizedEnd.isAfter(normalizedToday)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تاريخ النهاية يجب أن يكون في المستقبل'),
              backgroundColor: AppColors.error),
        );
        return;
      }
    }

    final usersAsync = ref.read(usersControllerProvider);
    final traineeName = usersAsync.whenOrNull(
          data: (users) => users
              .where((u) => u.id == _selectedTraineeId)
              .map((u) => u.name)
              .firstOrNull,
        ) ??
        '—';

    final isRenewal = _currentStatus != null && _currentEndDate != null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text(isRenewal ? 'تأكيد التجديد' : 'تأكيد الإنشاء',
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المتدرب: $traineeName',
                style: const TextStyle(color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            if (isRenewal) ...[
              Text(
                  'تاريخ الانتهاء الحالي: ${_currentEndDate!.toIso8601String().split('T').first}',
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
            ],
            Text(
                'التاريخ الجديد: ${_end.toIso8601String().split('T').first}',
                style: const TextStyle(color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            if (isRenewal) ...[
              Builder(
                builder: (_) {
                  final current = DateTime(_currentEndDate!.year,
                      _currentEndDate!.month, _currentEndDate!.day);
                  final selected = DateTime(_end.year, _end.month, _end.day);
                  final diff = selected.difference(current).inDays;
                  if (diff <= 0) {
                    return const Text(
                      '⚠ التاريخ الجديد قبل تاريخ الانتهاء الحالي',
                      style: TextStyle(
                          color: AppColors.error, fontWeight: FontWeight.w600),
                    );
                  }
                  return Text('المدة الإضافية: $diff يوم',
                      style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600));
                },
              ),
            ] else
              const Text('سيتم إنشاء اشتراك جديد',
                  style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    final recordedBy = ref.read(authControllerProvider).value?.id ?? '';

    if (isRenewal) {
      final result = await ref
          .read(membershipControllerProvider.notifier)
          .renew(_selectedTraineeId!, _end, recordedBy);
      if (!mounted) return;
      setState(() => _loading = false);
      result.fold(
        (failure) =>
            AppToast.error(context, 'فشل التجديد: ${failure.message}'),
        (_) {
          AppToast.success(context, 'تم التجديد');
          Navigator.pop(context);
        },
      );
    } else {
      final ok = await ref
          .read(membershipControllerProvider.notifier)
          .create(_selectedTraineeId!, _start, _end, recordedBy);
      if (!mounted) return;
      setState(() => _loading = false);
      if (ok) {
        AppToast.success(context, 'تم الإنشاء');
        Navigator.pop(context);
      } else {
        AppToast.error(context, 'فشل الإنشاء');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // watch لاستبقاء التحديثات في التبويبات الفرعية
    ref.watch(usersControllerProvider);

    final isRenewal = _currentStatus != null && _currentEndDate != null;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'العضويات', icon: Icon(Icons.list)),
              Tab(text: 'إنشاء/تجديد', icon: Icon(Icons.add_card)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: List memberships with delete
                _buildMembershipsList(context, ref),
                // Tab 2: Create/Renew form
                _buildCreateRenewForm(context, ref, isRenewal),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipsList(BuildContext context, WidgetRef ref) {
    final membershipsAsync = ref.watch(allMembershipsProvider);
    
    return membershipsAsync.when(
      loading: () => const LoadingIndicator(message: 'جاري تحميل العضويات...'),
      error: (e, _) => AsyncErrorView(
          error: e, onRetry: () => ref.invalidate(allMembershipsProvider)),
      data: (memberships) {
        if (memberships.isEmpty) {
          return const Center(child: Text('لا توجد عضويات', style: TextStyle(color: AppColors.textMuted)));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(allMembershipsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: memberships.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final m = memberships[i];
              // نعرض اسم المتدرب واسم المدرب المسؤول عنه بدل الـ id الخام.
              final users = ref.watch(usersControllerProvider).value ?? [];
              final traineeName = users
                      .where((u) => u.id == m.traineeId)
                      .firstOrNull
                      ?.name ??
                  'متدرب غير معروف';
              final trainerAsync =
                  ref.watch(traineeCurrentTrainerProvider(m.traineeId));
              final trainerName = trainerAsync.when(
                data: (t) => t?.name ?? 'بدون مدرب معيَّن',
                loading: () => '...',
                error: (_, __) => 'بدون مدرب معيَّن',
              );
              return AppCard(
                child: ListTile(
                  title: Text(traineeName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      'المدرب: $trainerName\n'
                      '${m.startDate.toIso8601String().split('T').first} → ${m.endDate.toIso8601String().split('T').first} • ${m.status.name}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_forever, color: AppColors.error),
                    onPressed: () => _confirmDeleteMembership(context, ref, m.id),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteMembership(BuildContext context, WidgetRef ref, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('حذف العضوية نهائياً؟', style: TextStyle(color: AppColors.error)),
        content: const Text('سيتم حذف الاشتراك. لا يمكن التراجع.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final ok = await ref.read(membershipRepositoryProvider).deleteMembership(id);
      if (!context.mounted) return;
      ok.fold(
        (l) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل: ${l.message}'), backgroundColor: AppColors.error)),
        (_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف'), backgroundColor: AppColors.success)),
      );
    }
  }

  Widget _buildCreateRenewForm(BuildContext context, WidgetRef ref, bool isRenewal) {
    final usersAsync = ref.watch(usersControllerProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRenewal ? 'تجديد العضوية' : 'إنشاء عضوية جديدة',
              style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              isRenewal
                  ? (_currentStatus == MembershipStatus.active
                      ? 'العضوية الحالية نشطة، اختر تاريخ الانتهاء الجديد'
                      : 'انتهت العضوية الحالية، اختر تاريخ الانتهاء الجديد')
                  : 'لا توجد عضوية نشطة، أدخل بيانات العضوية الجديدة',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            usersAsync.when(
              loading: () => const LoadingIndicator(
                  message: 'جاري تحميل قائمة المتدربين...'),
              error: (e, _) => Text('خطأ: $e',
                  style: const TextStyle(color: AppColors.error)),
              data: (_) {
                final traineesList = usersAsync.whenOrNull(
                      data: (users) => users.where((u) => u.role.name == 'trainee').toList(),
                    ) ??
                    [];
                return UserSearchField(
                  users: traineesList,
                  labelText: 'المتدرب',
                  prefixIcon: Icons.person,
                  selectedId: _selectedTraineeId,
                  onSelected: (user) => _onTraineeSelected(user?.id),
                );
              },
            ),
            const SizedBox(height: 12),
            if (!isRenewal) ...[
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _start,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime(2028),
                      );
                      if (d != null) setState(() => _start = d);
                    },
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: Text(
                        'من: ${_start.toIso8601String().split('T').first}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _end,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2028),
                      );
                      if (d != null) setState(() => _end = d);
                    },
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: Text(
                        'إلى: ${_end.toIso8601String().split('T').first}'),
                  ),
                ),
              ]),
            ] else ...[
              Row(children: [
                Text(
                    'تاريخ الانتهاء الجديد: ${_end.toIso8601String().split('T').first}',
                    style: const TextStyle(color: AppColors.textSecondary)),
                const Spacer(),
                OutlinedButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _end,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (d != null) setState(() => _end = d);
                  },
                  child: const Text('اختيار'),
                ),
              ]),
            ],
            const SizedBox(height: 16),
            AppButton(
              label: isRenewal ? 'تجديد' : 'إنشاء الاشتراك',
              icon: isRenewal ? Icons.refresh : Icons.card_membership,
              isLoading: _loading,
              onPressed: _loading ? null : _confirmAndSave,
            ),
          ],
        ),
      ),
    );
  }
}