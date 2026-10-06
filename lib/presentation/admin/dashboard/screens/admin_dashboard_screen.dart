import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/finance_charts.dart';
import '../../finance/controllers/finance_controller.dart';
import '../controllers/dashboard_controller.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final weeklyAsync = ref.watch(weeklyAttendanceProvider);
    final recentAsync = ref.watch(recentCheckinsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مرحباً، أدمن 👋',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 22)),
            const SizedBox(height: 4),
            Text('نظرة شاملة على أداء الصالة اليوم',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            statsAsync.when(
              loading: () =>
                  const LoadingIndicator(message: 'جاري تحميل الإحصائيات...'),
              error: (e, _) => AsyncErrorView(
                  error: e, onRetry: () => ref.invalidate(adminStatsProvider)),
              data: (s) => LayoutBuilder(builder: (context, c) {
                final isWide = c.maxWidth > 900;
                return GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 4 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: isWide ? 1.35 : 1.1),
                  children: [
                    StatCard(
                        label: 'إجمالي الأعضاء',
                        value: '${s.totalUsers}',
                        delta: '+14% هذا الشهر',
                        icon: Icons.group_outlined,
                        deltaColor: AppColors.success),
                    StatCard(
                        label: 'القاعات النشطة',
                        value: '${s.totalHalls}',
                        delta: '3 قاعات',
                        icon: Icons.meeting_room_outlined,
                        deltaColor: AppColors.info),
                    StatCard(
                        label: 'الاشتراكات النشطة',
                        value: '${s.activeMemberships}',
                        delta: '+7% هذا الأسبوع',
                        icon: Icons.card_membership,
                        deltaColor: AppColors.success),
                    StatCard(
                        label: 'حضور اليوم',
                        value: '${s.todayCheckins}',
                        delta: 'مباشر الآن',
                        icon: Icons.how_to_reg,
                        deltaColor: AppColors.primary),
                  ],
                );
              }),
            ),
            const SizedBox(height: 20),
            statsAsync.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => AsyncErrorView(
                  error: e, onRetry: () => ref.invalidate(adminStatsProvider)),
              data: (s) => Row(
                children: [
                  Expanded(
                      child: AppCard(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                        Text('المالية (30 يوم)',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                              child: Column(children: [
                            Text('الإيرادات',
                                style: Theme.of(context).textTheme.bodySmall),
                            Text('\$${s.income.toStringAsFixed(0)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                        color: AppColors.success, fontSize: 18))
                          ])),
                          Container(
                              width: 1, height: 40, color: AppColors.border),
                          Expanded(
                              child: Column(children: [
                            Text('المصروفات',
                                style: Theme.of(context).textTheme.bodySmall),
                            Text('\$${s.expense.toStringAsFixed(0)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                        color: AppColors.error, fontSize: 18))
                          ]))
                        ]),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                            value: (s.income + s.expense) == 0
                                ? 0
                                : s.income / (s.income + s.expense),
                            backgroundColor: AppColors.surfaceLow,
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8))
                      ]))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('الحضور المباشر',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            recentAsync.when(
                              loading: () => const LoadingIndicator(),
                              error: (e, _) => AsyncErrorView(
                                  error: e,
                                  onRetry: () =>
                                      ref.invalidate(recentCheckinsProvider)),
                              data: (list) {
                                if (list.isEmpty) {
                                  return const Text('لا يوجد حضور اليوم بعد',
                                      style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12));
                                }
                                return Column(
                                    children: list
                                        .map((c) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 6),
                                            child: Row(children: [
                                              const CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor:
                                                      AppColors.surfaceLow,
                                                  child: Icon(Icons.person,
                                                      size: 14,
                                                      color:
                                                          AppColors.textMuted)),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                  child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                    Text(c['name']!,
                                                        style: const TextStyle(
                                                            color: AppColors
                                                                .textPrimary,
                                                            fontSize: 13)),
                                                    Text(
                                                        '${c['ago']} • ${c['method']}',
                                                        style: const TextStyle(
                                                            color: AppColors
                                                                .textMuted,
                                                            fontSize: 11))
                                                  ])),
                                              const StatusBadge(
                                                  label: 'حاضر',
                                                  variant: BadgeVariant.active)
                                            ])))
                                        .toList());
                              },
                            ),
                          ]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            weeklyAsync.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => AsyncErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(weeklyAttendanceProvider)),
              data: (counts) => WeeklyAttendanceChart(counts: counts),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('التنقل السريع',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    TextButton(
                        onPressed: () {},
                        child: const Text('عرض الكل',
                            style: TextStyle(color: AppColors.primary)))
                  ]),
                  const SizedBox(height: 12),
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    _quickAction(Icons.group_add, 'إدارة الأعضاء',
                        () => context.go('/admin/users')),
                    _quickAction(Icons.meeting_room, 'القاعات والفترات',
                        () => context.go('/admin/halls')),
                    _quickAction(Icons.class_, 'الحصص الجماعية',
                        () => context.go('/admin/sessions')),
                    _quickAction(Icons.payments, 'المالية والتقارير',
                        () => context.go('/admin/finance/reports')),
                    _quickAction(Icons.calendar_month, 'الجدول الأسبوعي',
                        () => context.go('/admin/schedule')),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border)),
        child: Column(children: [
          Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.primary, size: 20)),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600))
        ]),
      ),
    );
  }
}
