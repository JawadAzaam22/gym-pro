import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/notification_item.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/async_error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../controllers/notifications_controller.dart';

/// أيقونة الإشعار حسب نوعه.
IconData notificationIcon(NotificationType type) => switch (type) {
      NotificationType.membershipExpiry => Icons.card_membership,
      NotificationType.sessionReminder => Icons.event,
      NotificationType.booking => Icons.calendar_month,
      NotificationType.payment => Icons.payments,
      NotificationType.attendance => Icons.how_to_reg,
      NotificationType.system => Icons.notifications,
    };

/// شاشة الإشعارات الداخلية — تُفتح من زر الجرس في الشريط العلوي.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _markingAll = false;

  void _invalidate() {
    // البث اللحظي سيحدّث القائمة تلقائياً؛ هذه خطوة تأكيد إضافية
    // في حال تأخرت رسالة Realtime أو تعذّر اتصالها.
    ref.invalidate(notificationsProvider);
  }

  Future<void> _markAsRead(AppNotification n) async {
    if (n.isRead) return;
    final res =
        await ref.read(notificationRepositoryProvider).markAsRead(n.id);
    if (!mounted) return;
    res.fold(
      (f) => AppToast.error(context, f.message),
      (_) => _invalidate(),
    );
  }

  Future<void> _markAllAsRead() async {
    if (_markingAll) return;
    setState(() => _markingAll = true);
    final res =
        await ref.read(notificationRepositoryProvider).markAllAsRead();
    if (!mounted) return;
    setState(() => _markingAll = false);
    res.fold(
      (f) => AppToast.error(context, f.message),
      (_) {
        AppToast.success(context, 'تم تعليم كل الإشعارات كمقروءة');
        _invalidate();
      },
    );
  }

  Future<void> _delete(AppNotification n) async {
    final res =
        await ref.read(notificationRepositoryProvider).deleteNotification(n.id);
    if (!mounted) return;
    res.fold(
      (f) => AppToast.error(context, f.message),
      (_) => _invalidate(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationsProvider);
    // valueOrNull بدل value: الأخيرة ترمي استثناءً عند خطأ البث
    // (AsyncError.value) وستُسقط الشاشة بدل عرض واجهة الخطأ.
    final items = async.valueOrNull ?? const <AppNotification>[];
    final hasUnread = items.any((n) => !n.isRead);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          TextButton(
            onPressed: hasUnread && !_markingAll ? _markAllAsRead : null,
            child: const Text(
              'تعليم الكل كمقروء',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: async.when(
        loading: () => const LoadingIndicator(message: 'جاري تحميل الإشعارات...'),
        error: (e, _) => AsyncErrorView(
          error: e,
          message: 'تعذّر تحميل الإشعارات',
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (_) => items.isEmpty
            ? const EmptyState(
                message: 'لا توجد إشعارات بعد',
                icon: Icons.notifications_none,
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(notificationsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _tile(context, items[i]),
                ),
              ),
      ),
    );
  }

  Widget _tile(BuildContext context, AppNotification n) {
    final color = n.isRead ? AppColors.textMuted : AppColors.primary;
    return Dismissible(
      key: ValueKey('notification-${n.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      onDismissed: (_) => _delete(n),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _markAsRead(n),
          onLongPress: () => _confirmDelete(n),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: n.isRead ? AppColors.border : AppColors.primary,
                width: n.isRead ? 1 : 1.4,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(notificationIcon(n.type), color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight:
                                    n.isRead ? FontWeight.w600 : FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              n.type.nameAr,
                              style: TextStyle(
                                fontSize: 9,
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (n.body != null && n.body!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          n.body!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        Formatters.timeAgo(n.createdAt),
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (!n.isRead)
                  Container(
                    margin: const EdgeInsetsDirectional.only(start: 8, top: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(AppNotification n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('حذف الإشعار',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('هل تريد حذف هذا الإشعار؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) await _delete(n);
  }
}
