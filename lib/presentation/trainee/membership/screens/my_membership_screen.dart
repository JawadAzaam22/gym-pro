import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/enums.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/status_badge.dart';
import '../controllers/my_membership_controller.dart';

class MyMembershipScreen extends ConsumerWidget {
  const MyMembershipScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myMembershipProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('اشتراكي')),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => AsyncErrorView(
            error: e, onRetry: () => ref.invalidate(myMembershipProvider)),
        data: (m) {
          if (m == null) {
            return const Center(
                child: Text('لا يوجد اشتراك نشط',
                    style: TextStyle(color: AppColors.textMuted)));
          }
          final daysLeft = m.endDate.difference(DateTime.now()).inDays;
          final totalDays = m.endDate.difference(m.startDate).inDays;
          final elapsedDays = DateTime.now().difference(m.startDate).inDays;
          final isExpired = m.status == MembershipStatus.expired;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFFE64A19)],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft),
                      borderRadius: BorderRadius.circular(24)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Expanded(
                              child: Text('اشتراكك الحالي',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12))),
                          Flexible(
                              child: StatusBadge(
                                  label: m.status.name,
                                  variant: isExpired
                                      ? BadgeVariant.danger
                                      : BadgeVariant.active))
                        ]),
                        const SizedBox(height: 8),
                        Text(
                            '${m.startDate.toIso8601String().split('T').first} → ${m.endDate.toIso8601String().split('T').first}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                                value: totalDays <= 0
                                    ? 1
                                    : (elapsedDays / totalDays).clamp(0.0, 1.0),
                                backgroundColor: Colors.white24,
                                color: Colors.white,
                                minHeight: 6)),
                        const SizedBox(height: 8),
                        Text(
                            isExpired
                                ? 'انتهى الاشتراك في ${m.endDate.toIso8601String().split('T').first}'
                                : '$daysLeft يوم متبقي',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11))
                      ])),
              const SizedBox(height: 16),
              AppCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('تفاصيل الاشتراك',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _row('الحالة', m.status.name),
                    _row('البداية',
                        m.startDate.toIso8601String().split('T').first),
                    _row(
                        'النهاية', m.endDate.toIso8601String().split('T').first)
                  ])),
            ]),
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted)),
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600))
      ]));
}
