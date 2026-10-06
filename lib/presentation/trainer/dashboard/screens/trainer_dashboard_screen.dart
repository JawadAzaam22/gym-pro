import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../controllers/trainer_dashboard_controller.dart';

class TrainerDashboardScreen extends ConsumerWidget {
  const TrainerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(trainerDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar:
          AppBar(title: const Text('لوحة المدرب'), actions: const [
        NotificationBell(route: '/mobile/notifications'),
        Padding(
            padding: EdgeInsets.only(left: 12),
            child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child:
                    Icon(Icons.fitness_center, size: 14, color: Colors.white)))
      ]),
      body: dashAsync.when(
        loading: () => const LoadingIndicator(message: 'جاري تحميل بياناتك...'),
        error: (e, _) => AsyncErrorView(
            error: e, onRetry: () => ref.invalidate(trainerDashboardProvider)),
        data: (d) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('أهلاً كوتش 💪',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontSize: 22)),
              Text(
                  'لديك ${d.traineesCount} متدرب نشط و ${d.todaySessions} جلسات اليوم',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: GestureDetector(
                        onTap: () => context.push('/trainer/trainees'),
                        child: StatCard(
                            label: 'متدربيني',
                            value: '${d.traineesCount}',
                            delta: 'إجمالي المتدربين',
                            icon: Icons.group))),
                const SizedBox(width: 12),
                Expanded(
                    child: GestureDetector(
                        onTap: () => context.push('/trainer/schedule'),
                        child: StatCard(
                            label: 'جلسات اليوم',
                            value: '${d.todaySessions}',
                            delta: 'خاصة وجماعية',
                            icon: Icons.event)))
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: GestureDetector(
                        onTap: () => context.push('/trainer/trainees'),
                        child: StatCard(
                            label: 'برامج نشطة',
                            value: '${d.programsCount}',
                            delta: 'محدثة',
                            icon: Icons.assignment,
                            deltaColor: AppColors.info))),
                const SizedBox(width: 12),
                Expanded(
                    child: GestureDetector(
                        onTap: () => context.push('/trainer/trainees'),
                        child: StatCard(
                            label: 'خطط غذائية',
                            value: '${d.dietsCount}',
                            delta: 'قيد المتابعة',
                            icon: Icons.restaurant)))
              ]),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('جدولي اليوم',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      StatusBadge(
                          label: '${d.todaySessions} جلسات',
                          variant: BadgeVariant.info)
                    ]),
                    const SizedBox(height: 12),
                    if (d.todayPrivateSessions.isEmpty)
                      const Text('لا توجد جلسات خاصة مجدولة اليوم',
                          style: TextStyle(color: AppColors.textMuted)),
                    ...d.todayPrivateSessions.map((session) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: AppColors.surfaceLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border)),
                          child: Row(children: [
                            Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  const Text('جلسة خاصة',
                                      style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  Text(
                                      '${session.hour.toString().padLeft(2, '0')}:${session.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11))
                                ])),
                            const StatusBadge(
                                label: 'خاصة',
                                variant: BadgeVariant.active,
                                withDot: false)
                          ]),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('إجراءات سريعة',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _actionChip(context, Icons.people, 'عرض المتدربين',
                          '/trainer/trainees'),
                      _actionChip(context, Icons.how_to_reg, 'الحضور',
                          '/trainer/attendance')
                    ])
                  ])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionChip(
          BuildContext context, IconData icon, String label, String path) =>
      ActionChip(
          avatar: Icon(icon, size: 14, color: AppColors.primary),
          label: Text(label),
          backgroundColor: AppColors.surfaceLow,
          side: const BorderSide(color: AppColors.border),
          onPressed: () => context.push(path));
}
