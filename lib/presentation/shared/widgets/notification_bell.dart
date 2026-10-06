import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../notifications/controllers/notifications_controller.dart';

/// زر جرس الإشعارات مع شارة العدّاد غير المقروء.
///
/// يعتمد على `unreadNotificationsCountProvider` المُشتق من بث Supabase
/// Realtime، فلا يُجري أي طلب شبكة إضافي. عند حدوث خطأ (مثل عدم تشغيل
/// migration بعد) يعرض 0 ولا يتعطل.
///
/// الاستخدام في الشريط العلوي:
/// ```dart
/// NotificationBell(route: '/admin/notifications'),
/// ```
class NotificationBell extends ConsumerWidget {
  final String route;

  const NotificationBell({super.key, required this.route});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsCountProvider);
    return IconButton(
      onPressed: () => context.push(route),
      tooltip: unread > 0 ? 'الإشعارات ($unread غير مقروء)' : 'الإشعارات',
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        backgroundColor: AppColors.primary,
        textColor: Colors.white,
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
