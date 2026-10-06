import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../qr_code/controllers/qr_controller.dart';
import '../../../shared/auth/controllers/auth_controller.dart';
import '../controllers/trainee_dashboard_controller.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/notification_bell.dart';

class TraineeDashboardScreen extends ConsumerWidget {
  const TraineeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(traineeDashboardProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('مرحباً يا بطل'),
        actions: const [
          NotificationBell(route: '/mobile/notifications'),
          Padding(
              padding: EdgeInsets.only(left: 12),
              child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.surfaceCard,
                  child: Icon(Icons.person,
                      size: 16, color: AppColors.textMuted))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Membership card - hero (بيانات حقيقية من traineeDashboardProvider)
            dashAsync.when(
              loading: () =>
                  const LoadingIndicator(message: 'جاري تحميل اشتراكك...'),
              error: (e, _) => AsyncErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(traineeDashboardProvider)),
              data: (d) => GestureDetector(
                onTap: () => context.push('/trainee/membership'),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFF5722), Color(0xFFE64A19)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                          color: AppColors.primaryGlow,
                          blurRadius: 24,
                          offset: Offset(0, 8))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('اشتراكك الحالي',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                                SizedBox(height: 4),
                                Text('عضويتك',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999)),
                            child: Text(
                              d.membershipDaysLeft > 0 ? 'نشط' : 'منتهي',
                              style: TextStyle(
                                  color: d.membershipDaysLeft > 0
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                              value:
                                  (d.membershipDaysLeft / 30).clamp(0.0, 1.0),
                              backgroundColor: Colors.white24,
                              color: Colors.white,
                              minHeight: 6)),
                      const SizedBox(height: 8),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${d.membershipDaysLeft} يوم متبقي',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11)),
                            const Text('',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 11))
                          ]),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            dashAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (d) => Row(
                children: [
                  Expanded(
                      child: GestureDetector(
                          onTap: () => context.push('/trainee/attendance'),
                          child: const StatCard(
                              label: 'حضور الشهر',
                              value: '-',
                              delta: 'عرض السجل',
                              icon: Icons.how_to_reg))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: GestureDetector(
                          onTap: () => context.push('/trainee/bookings'),
                          child: StatCard(
                              label: 'حصص محجوزة',
                              value: '${d.bookingsCount}',
                              delta: 'قادمة',
                              icon: Icons.event,
                              deltaColor: AppColors.info))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // QR Card
            AppCard(
              child: Column(
                children: [
                  Row(children: [
                    Text('كود الدخول الخاص بك',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    const StatusBadge(
                        label: 'جاهز للمسح', variant: BadgeVariant.active)
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16)),
                    child: QrImageView(
                        key: ValueKey(ref.watch(qrRefreshProvider)),
                        data: ref.watch(traineeQrProvider),
                        version: QrVersions.auto,
                        size: 160,
                        backgroundColor: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text('اعرض هذا الكود على موظف الاستقبال عند الدخول',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 11)),
                  const SizedBox(height: 8),
                  SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                          onPressed: () {
                            // إذا لم يكن الكود جاهزاً بعد (لا يوجد مستخدم محدَّد)
                            // نعيد جلب بيانات الدخول ثم نولّد الكود من جديد.
                            if (ref.read(traineeQrProvider) ==
                                'trainee_pending') {
                              ref.invalidate(authControllerProvider);
                            }
                            ref.read(qrRefreshProvider.notifier).state++;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('تم تحديث كود الدخول'),
                                  backgroundColor: AppColors.success),
                            );
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('تحديث الكود'))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
