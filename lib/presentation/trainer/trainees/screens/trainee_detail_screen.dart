import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/status_badge.dart';
import '../controllers/trainees_controller.dart';

class TraineeDetailScreen extends ConsumerStatefulWidget {
  final String traineeId;
  const TraineeDetailScreen({super.key, this.traineeId = ''});

  @override
  ConsumerState<TraineeDetailScreen> createState() =>
      _TraineeDetailScreenState();
}

class _TraineeDetailScreenState extends ConsumerState<TraineeDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(traineeDetailProvider(widget.traineeId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(traineeDetailProvider(widget.traineeId));
    final traineeName =
        detailAsync.whenOrNull(data: (detail) => detail.user.name) ??
            'بيانات المتدرب';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(traineeName)),
      body: detailAsync.when(
        loading: () =>
            const LoadingIndicator(message: 'جاري تحميل بيانات المتدرب...'),
        error: (e, _) => AsyncErrorView(
            error: e,
            onRetry: () =>
                ref.invalidate(traineeDetailProvider(widget.traineeId))),
        data: (d) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AppCard(
                child: Row(children: [
                  const CircleAvatar(
                      radius: 28,
                      backgroundImage:
                          AssetImage('assets/images/avatar_placeholder.png'),
                      backgroundColor: AppColors.surfaceLow),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.user.name,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700)),
                          Text('${d.user.email} • ${d.user.phone}',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                        ]),
                  ),
                  StatusBadge(
                      label: d.user.isActive ? 'نشط' : 'موقوف',
                      variant: d.user.isActive
                          ? BadgeVariant.active
                          : BadgeVariant.danger),
                ]),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('العضوية',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      StatusBadge(
                          label: d.latestMembership == null
                              ? 'لا توجد'
                              : d.latestMembership!.status.name,
                          variant: d.latestMembership?.isActive == true
                              ? BadgeVariant.active
                              : BadgeVariant.danger)
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      d.latestMembership == null
                          ? 'لا توجد عضوية مسجلة'
                          : 'تنتهي في ${d.latestMembership!.endDate.toIso8601String().split('T').first}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('البرامج',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      if (d.activeProgram != null)
                        TextButton.icon(
                          onPressed: () async {
                            await context.push(
                              '/trainer/programs/${d.activeProgram!.id}/days',
                              extra: d.activeProgram,
                            );
                            if (mounted) {
                              ref.invalidate(
                                  traineeDetailProvider(widget.traineeId));
                            }
                          },
                          icon: const Icon(Icons.manage_search,
                              size: 16, color: AppColors.primary),
                          label: const Text('إدارة البرنامج',
                              style: TextStyle(color: AppColors.primary)),
                        )
                      else
                        TextButton.icon(
                          onPressed: () async {
                            await context.push(
                              '/trainer/programs/new',
                              extra: {'initialTraineeId': widget.traineeId},
                            );
                            if (mounted) {
                              ref.invalidate(
                                  traineeDetailProvider(widget.traineeId));
                            }
                          },
                          icon: const Icon(Icons.add,
                              size: 16, color: AppColors.primary),
                          label: const Text('إنشاء برنامج تدريبي',
                              style: TextStyle(color: AppColors.primary)),
                        ),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                        d.activeProgram == null
                            ? 'لا يوجد برنامج نشط'
                            : '${d.activeProgram!.name} - نشط',
                        style:
                            const TextStyle(color: AppColors.textSecondary)),
                    if (d.programProgress != null) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                          value: d.programProgress,
                          backgroundColor: AppColors.surfaceLow,
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('الخطة الغذائية',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      if (d.activeDiet != null)
                        TextButton.icon(
                          onPressed: () async {
                            await context.push(
                              '/trainer/diets/${d.activeDiet!.id}/days',
                              extra: d.activeDiet,
                            );
                            if (mounted) {
                              ref.invalidate(
                                  traineeDetailProvider(widget.traineeId));
                            }
                          },
                          icon: const Icon(Icons.manage_search,
                              size: 16, color: AppColors.success),
                          label: const Text('إدارة الخطة',
                              style: TextStyle(color: AppColors.success)),
                        )
                      else
                        TextButton.icon(
                          onPressed: () async {
                            await context.push(
                              '/trainer/diets/new',
                              extra: {'initialTraineeId': widget.traineeId},
                            );
                            if (mounted) {
                              ref.invalidate(
                                  traineeDetailProvider(widget.traineeId));
                            }
                          },
                          icon: const Icon(Icons.add,
                              size: 16, color: AppColors.success),
                          label: const Text('إنشاء خطة غذائية',
                              style: TextStyle(color: AppColors.success)),
                        ),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                        d.activeDiet == null
                            ? 'لا توجد خطة نشطة'
                            : d.activeDiet!.name,
                        style:
                            const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
