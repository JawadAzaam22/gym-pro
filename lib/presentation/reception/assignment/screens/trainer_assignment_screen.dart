import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/user_search_field.dart';
import '../../../admin/users/controllers/users_controller.dart';
import '../../../shared/auth/controllers/auth_controller.dart';
import '../../../../domain/entities/user.dart';
import '../controllers/trainer_assignment_controller.dart';
import '../../../shared/widgets/app_toast.dart';

class TrainerAssignmentScreen extends ConsumerStatefulWidget {
  const TrainerAssignmentScreen({super.key});

  @override
  ConsumerState<TrainerAssignmentScreen> createState() =>
      _TrainerAssignmentScreenState();
}

class _TrainerAssignmentScreenState
    extends ConsumerState<TrainerAssignmentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedTraineeIdProvider.notifier).state = null;
      ref.read(selectedTrainerIdProvider.notifier).state = null;
      ref.read(trainerAssignmentControllerProvider.notifier).clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersControllerProvider);
    final selectedTrainee = ref.watch(selectedTraineeIdProvider);
    final selectedTrainer = ref.watch(selectedTrainerIdProvider);
    final assignState = ref.watch(trainerAssignmentControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('اختيار المتدرب',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                usersAsync.when(
                  loading: () => const LoadingIndicator(
                      message: 'جاري تحميل الأعضاء والمدربين...'),
                  error: (e, _) => AsyncErrorView(
                      error: e,
                      onRetry: () =>
                          ref.invalidate(usersControllerProvider)),
                  data: (users) {
                    final trainees = users
                        .where((u) => u.role.name == 'trainee')
                        .toList();
                    return UserSearchField(
                      users: trainees,
                      labelText: 'المتدرب',
                      prefixIcon: Icons.person_search,
                      selectedId: selectedTrainee,
                      onSelected: (user) {
                        ref.read(selectedTraineeIdProvider.notifier).state =
                            user?.id;
                        ref.read(selectedTrainerIdProvider.notifier).state =
                            null;
                        ref.read(
                            trainerAssignmentControllerProvider.notifier)
                            .clear();
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (selectedTrainee != null) ...[
            _CurrentTrainerCard(traineeId: selectedTrainee),
            const SizedBox(height: 16),
          ],
          if (selectedTrainee != null)
            _AssignTrainerSection(
              traineeId: selectedTrainee,
              selectedTrainerId: selectedTrainer,
              usersAsync: usersAsync,
              assignState: assignState,
            ),
          if (assignState.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.error.withOpacity(0.25))),
              child: Text(assignState.error!,
                  style: const TextStyle(
                      color: AppColors.error, fontSize: 12)),
            ),
          if (assignState.success != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.success.withOpacity(0.25))),
              child: Text(assignState.success!,
                  style: const TextStyle(
                      color: AppColors.success, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _AssignTrainerSection extends ConsumerWidget {
  final String traineeId;
  final String? selectedTrainerId;
  final AsyncValue<List<User>> usersAsync;
  final TrainerAssignmentState assignState;

  const _AssignTrainerSection({
    required this.traineeId,
    required this.selectedTrainerId,
    required this.usersAsync,
    required this.assignState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAsync =
        ref.watch(traineeCurrentTrainerProvider(traineeId));
    final hasCurrentTrainer = currentAsync.whenOrNull(
          data: (t) => t != null,
        ) ??
        false;

    if (hasCurrentTrainer) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تعيين مدرب جديد',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text('هذا المتدرب ليس لديه مدرب بعد',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12)),
          const SizedBox(height: 12),
          usersAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (users) {
              final trainers = users
                  .where((u) =>
                      u.role.name == 'trainer' && u.isActive)
                  .toList();
              return UserSearchField(
                users: trainers,
                labelText: 'المدرب',
                prefixIcon: Icons.fitness_center,
                selectedId: selectedTrainerId,
                onSelected: (user) {
                  ref.read(selectedTrainerIdProvider.notifier).state =
                      user?.id;
                  ref.read(
                      trainerAssignmentControllerProvider.notifier)
                      .clear();
                },
              );
            },
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'تعيين المدرب',
            icon: Icons.person_add,
            isLoading: assignState.isLoading,
            onPressed: (selectedTrainerId == null)
                ? null
                : () async {
                    final assignedBy = ref
                            .read(authControllerProvider)
                            .value
                            ?.id ??
                        '';
                    final ok = await ref
                        .read(trainerAssignmentControllerProvider.notifier)
                        .assign(
                          trainerId: selectedTrainerId!,
                          traineeId: traineeId,
                          assignedBy: assignedBy,
                        );
                    if (!context.mounted) return;
                    if (ok) {
                      AppToast.success(context, 'تم تعيين المدرب بنجاح');
                    } else {
                      final err = ref
                              .read(trainerAssignmentControllerProvider)
                              .error ??
                          'فشل التعيين';
                      AppToast.error(context, err.toString());
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class _CurrentTrainerCard extends ConsumerWidget {
  final String traineeId;
  const _CurrentTrainerCard({required this.traineeId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAsync =
        ref.watch(traineeCurrentTrainerProvider(traineeId));
    final assignmentIdAsync =
        ref.watch(traineeAssignmentIdProvider(traineeId));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('المدرب الحالي',
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            currentAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (trainer) {
                if (trainer == null) return const SizedBox.shrink();
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          _showChangeDialog(context, ref, assignmentIdAsync),
                      icon: const Icon(Icons.swap_horiz, size: 14),
                      label: const Text('تغيير',
                          style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, size: 18, color: AppColors.error),
                      onPressed: () => _confirmDeleteAssignment(context, ref, assignmentIdAsync),
                      tooltip: 'إلغاء التعيين',
                    ),
                  ],
                );
              },
            ),
          ]),
          const SizedBox(height: 8),
          currentAsync.when(
            loading: () => const LoadingIndicator(
                message: 'جاري تحميل المدرب الحالي...'),
            error: (e, _) => AsyncErrorView(
                error: e,
                onRetry: () => ref.invalidate(
                    traineeCurrentTrainerProvider(traineeId))),
            data: (trainer) {
              if (trainer == null) {
                return const Text(
                    'لا يوجد مدرب معيّن لهذا المتدرب بعد',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 13));
              }
              return Row(children: [
                CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.surfaceLow,
                    child: Text(
                        trainer.name.characters.first,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800))),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(trainer.name,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700)),
                      Text(trainer.phone,
                          style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11)),
                    ])),
                const StatusBadge(
                    label: 'معيّن', variant: BadgeVariant.active),
              ]);
            },
          ),
        ],
      ),
    );
  }

  void _showChangeDialog(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<int?> assignmentIdAsync,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _ChangeTrainerDialog(
        traineeId: traineeId,
        assignmentIdAsync: assignmentIdAsync,
      ),
    );
  }

  Future<void> _confirmDeleteAssignment(BuildContext context, WidgetRef ref, AsyncValue<int?> assignmentIdAsync) async {
    final assignmentId = assignmentIdAsync.valueOrNull;
    if (assignmentId == null) {
      AppToast.error(context, 'لا يوجد تعيين نشط');
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('إلغاء تعيين المدرب؟', style: TextStyle(color: AppColors.error)),
        content: const Text('سيتم إلغاء العلاقة بين المدرب والمتدرب.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('إلغاء التعيين'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final ok = await ref.read(trainerAssignmentControllerProvider.notifier).deleteAssignment(assignmentId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'تم الإلغاء' : 'فشل'), backgroundColor: ok ? AppColors.success : AppColors.error));
    }
  }
}

class _ChangeTrainerDialog extends ConsumerStatefulWidget {
  final String traineeId;
  final AsyncValue<int?> assignmentIdAsync;

  const _ChangeTrainerDialog({
    required this.traineeId,
    required this.assignmentIdAsync,
  });

  @override
  ConsumerState<_ChangeTrainerDialog> createState() =>
      _ChangeTrainerDialogState();
}

class _ChangeTrainerDialogState
    extends ConsumerState<_ChangeTrainerDialog> {
  String? _newTrainerId;
  bool _submitting = false;

  Future<void> _submit() async {
    if (_newTrainerId == null || _submitting) return;
    setState(() => _submitting = true);

    final assignmentId = widget.assignmentIdAsync.valueOrNull;
    if (assignmentId == null) {
      final fetchedId = await ref.read(
          traineeAssignmentIdProvider(widget.traineeId).future);
      if (fetchedId == null) {
        if (mounted) {
          setState(() => _submitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('لا يوجد تعيين نشط لهذا المتدرب'),
                backgroundColor: AppColors.error),
          );
          Navigator.pop(context);
        }
        return;
      }
      final ok = await ref
          .read(trainerAssignmentControllerProvider.notifier)
          .changeAssignment(
            assignmentId: fetchedId,
            newTrainerId: _newTrainerId!,
            traineeId: widget.traineeId,
          );
      if (mounted) {
        setState(() => _submitting = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(ok ? 'تم التغيير بنجاح' : 'فشل التغيير'),
              backgroundColor:
                  ok ? AppColors.success : AppColors.error),
        );
      }
    } else {
      final ok = await ref
          .read(trainerAssignmentControllerProvider.notifier)
          .changeAssignment(
            assignmentId: assignmentId,
            newTrainerId: _newTrainerId!,
            traineeId: widget.traineeId,
          );
      if (mounted) {
        setState(() => _submitting = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(ok ? 'تم التغيير بنجاح' : 'فشل التغيير'),
              backgroundColor:
                  ok ? AppColors.success : AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersControllerProvider);

    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      title: const Text('تغيير المدرب',
          style: TextStyle(color: AppColors.textPrimary)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('اختر المدرب الجديد:',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            usersAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator()),
              error: (e, _) => Text('خطأ: $e',
                  style: const TextStyle(color: AppColors.error)),
              data: (users) {
                final trainers = users
                    .where((u) =>
                        u.role.name == 'trainer' && u.isActive)
                    .toList();
                return UserSearchField(
                  users: trainers,
                  labelText: 'المدرب الجديد',
                  prefixIcon: Icons.fitness_center,
                  selectedId: _newTrainerId,
                  onSelected: (user) =>
                      setState(() => _newTrainerId = user?.id),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed:
                _submitting ? null : () => Navigator.pop(context),
            child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: (_newTrainerId == null || _submitting)
              ? null
              : _submit,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white),
          child: _submitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('تأكيد التغيير'),
        ),
      ],
    );
  }
}
