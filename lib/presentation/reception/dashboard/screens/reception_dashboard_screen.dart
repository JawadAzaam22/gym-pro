import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../controllers/reception_dashboard_controller.dart';

class ReceptionDashboardScreen extends ConsumerWidget {
  const ReceptionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(receptionStatsProvider);
    final recentAsync = ref.watch(recentCheckinsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('مرحباً بك 👋', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          Text('نظرة سريعة على نشاط الاستقبال اليوم', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          statsAsync.when(
            loading: () => const LoadingIndicator(message: 'جاري تحميل الإحصائيات...'),
            error: (e, _) => AsyncErrorView(error: e, onRetry: () => ref.invalidate(receptionStatsProvider)),
            data: (s) => LayoutBuilder(builder: (context, c) {
              final isWide = c.maxWidth > 900;
              return GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isWide ? 1.35 : 1.1,
                ),
                children: [
                  StatCard(label: 'حضور اليوم', value: '${s.todayCheckins}', delta: 'مباشر الآن', icon: Icons.how_to_reg, deltaColor: AppColors.primary),
                  StatCard(label: 'المتدربين', value: '${s.totalTrainees}', delta: 'إجمالي', icon: Icons.group_outlined, deltaColor: AppColors.info),
                  StatCard(label: 'اشتراكات نشطة', value: '${s.activeMemberships}', delta: 'حالياً', icon: Icons.card_membership, deltaColor: AppColors.success),
                  StatCard(label: 'مدفوعات معلقة', value: '${s.pendingPayments}', delta: 'بانتظار', icon: Icons.payments_outlined, deltaColor: AppColors.warning),
                ],
              );
            }),
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('آخر التسجيلات', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  TextButton(onPressed: () => context.push('/reception/checkin'), child: const Text('عرض الكل', style: TextStyle(color: AppColors.primary))),
                ]),
                const SizedBox(height: 12),
                recentAsync.when(
                  loading: () => const LoadingIndicator(),
                  error: (e, _) => AsyncErrorView(error: e, onRetry: () => ref.invalidate(recentCheckinsProvider)),
                  data: (list) {
                    if (list.isEmpty) return const Text('لا يوجد حضور اليوم بعد', style: TextStyle(color: AppColors.textMuted, fontSize: 12));
                    return Column(
                      children: list.map((c) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          const CircleAvatar(radius: 16, backgroundColor: AppColors.surfaceLow, child: Icon(Icons.person, size: 14, color: AppColors.textMuted)),
                          const SizedBox(width: 8),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c['name']!, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                            Text('${c['ago']} • ${c['method']}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          ])),
                          const StatusBadge(label: 'حاضر', variant: BadgeVariant.active),
                        ]),
                      )).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('إجراءات سريعة', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _quickAction(Icons.how_to_reg, 'تسجيل حضور', () => context.push('/reception/checkin')),
                    _quickAction(Icons.qr_code_scanner, 'مسح QR', () => context.push('/reception/checkin/qr')),
                    _quickAction(Icons.group_add, 'متدرب جديد', () => context.push('/reception/trainees/new')),
                    _quickAction(Icons.card_membership, 'العضويات', () => context.push('/reception/memberships')),
                    _quickAction(Icons.event, 'حجوزات جماعية', () => context.push('/reception/bookings/group')),
                    _quickAction(Icons.person_outline, 'جلسات خاصة', () => context.push('/reception/bookings/private')),
                    _quickAction(Icons.person_add, 'تعيين مدرب', () => context.push('/reception/trainer-assignment')),
                    _quickAction(Icons.payments, 'تسجيل دفعة', () => context.push('/reception/payments/record')),
                    _quickAction(Icons.calendar_month, 'الجدول اليومي', () => context.push('/reception/schedule')),
                  ],
                ),
              ],
            ),
          ),
        ],
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
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
