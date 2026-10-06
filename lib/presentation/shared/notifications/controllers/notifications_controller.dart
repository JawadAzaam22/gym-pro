import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/notification_item.dart';

/// بث لحظي لإشعارات المستخدم الحالي عبر Supabase Realtime
/// (مضمّن مجاناً في خطة Supabase المجانية).
///
/// يستبدل الاستعلام الأولي ثم يستقبل أي إشعار جديد فور إنشائه في القاعدة،
/// فلا حاجة لاستدعاء يدوي للتحديث.
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  return ref.watch(notificationRepositoryProvider).watchMyNotifications();
});

/// عدد الإشعارات غير المقروءة — مُشتقة من البث نفسه،
/// أي بلا أي طلب شبكة إضافي فوق ما يفعله `notificationsProvider` بالفعل.
///
/// تُعاد 0 عند حدوث خطأ (مثل عدم تشغيل migration بعد) حتى لا يتعطل
/// زر الجرس في الشريط العلوي.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  // valueOrNull بدل value: الأخيرة ترمي استثناءً عند خطأ البث وستُسقط
  // زر الجرس في الشريط العلوي بدل إخفاء الشارة.
  final items = ref.watch(notificationsProvider).valueOrNull;
  if (items == null) return 0;
  return items.where((n) => !n.isRead).length;
});
