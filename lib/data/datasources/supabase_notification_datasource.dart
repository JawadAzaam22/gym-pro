import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/exceptions.dart' as app_ex;
import '../models/notification_model.dart';

/// مصدر بيانات الإشعارات الداخلية.
///
/// مجاني 100%: يعتمد على Supabase Realtime (مضمّن في الخطة المجانية).
/// كل استعلام مقيد بـ `user_id` الحالي — طبقة RLS في القاعدة تتولى الحماية
/// إضافة إلى هذا القيد الصريح.
class SupabaseNotificationDatasource {
  final SupabaseClient client;
  SupabaseNotificationDatasource(this.client);

  /// يقرأ المعرّف خارج كتلة try حتى لا يختلط استثناؤه باستثناءات الشبكة.
  String get _uid {
    final id = client.auth.currentUser?.id;
    if (id == null || id.isEmpty) {
      throw app_ex.AuthException('يجب تسجيل الدخول لعرض الإشعارات');
    }
    return id;
  }

  /// إشعارات المستخدم الحالي — أحدث أولاً، بحد أقصى 50 (ترقيم صريح).
  Future<List<NotificationModel>> getMyNotifications() async {
    final uid = _uid;
    try {
      final data = await client
          .from('notifications')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(50);
      return (data as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is app_ex.AuthException) rethrow;
      throw app_ex.ServerException('فشل جلب الإشعارات: $e');
    }
  }

  /// عدد الإشعارات غير المقروءة — استعلام واحد بمعدّد خادمي.
  Future<int> getUnreadCount() async {
    final uid = _uid;
    try {
      return await client
          .from('notifications')
          .count(CountOption.exact)
          .eq('user_id', uid)
          .eq('is_read', false);
    } catch (e) {
      if (e is app_ex.AuthException) rethrow;
      throw app_ex.ServerException('فشل جلب عدّاد الإشعارات: $e');
    }
  }

  /// بث لحظي (Supabase Realtime) لإشعارات المستخدم الحالي.
  ///
  /// يعمل طالما التطبيق مفتوح؛ يتوقف إذا كان التطبيق مغلقاً (تُعالج ذلك
  /// طبقة التنبيهات المحلية).
  Stream<List<NotificationModel>> watchMyNotifications() {
    final uid = client.auth.currentUser?.id;
    // نُصدر قائمة فارغة بدل Stream.empty(): الفارغ لا يُصدر قيمة إطلاقاً
    // فيبقى الـ StreamProvider عالقًا في حالة التحميل للأبد.
    if (uid == null || uid.isEmpty) return Stream.value(<NotificationModel>[]);
    return client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(50)
        .map((list) => list
            .map(NotificationModel.fromJson)
            .toList());
  }

  Future<void> markAsRead(int id) async {
    final uid = _uid;
    try {
      await client
          .from('notifications')
          .update({'is_read': true}).eq('id', id).eq('user_id', uid);
    } catch (e) {
      if (e is app_ex.AuthException) rethrow;
      throw app_ex.ServerException('فشل تعليم الإشعار كمقروء: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final uid = _uid;
    try {
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', uid)
          .eq('is_read', false);
    } catch (e) {
      if (e is app_ex.AuthException) rethrow;
      throw app_ex.ServerException('فشل تعليم كل الإشعارات كمقروءة: $e');
    }
  }

  Future<void> deleteNotification(int id) async {
    final uid = _uid;
    try {
      await client
          .from('notifications')
          .delete()
          .eq('id', id)
          .eq('user_id', uid);
    } catch (e) {
      if (e is app_ex.AuthException) rethrow;
      throw app_ex.ServerException('فشل حذف الإشعار: $e');
    }
  }

  Future<NotificationModel> createNotification({
    required String userId,
    required String title,
    String? body,
    String type = 'system',
    int? entityId,
  }) async {
    try {
      final data = await client
          .from('notifications')
          .insert(<String, dynamic>{
            'user_id': userId,
            'title': title,
            'body': body,
            'type': type,
            'entity_id': entityId,
          })
          .select()
          .single();
      return NotificationModel.fromJson(data);
    } catch (e) {
      if (e is app_ex.AuthException) rethrow;
      throw app_ex.ServerException('فشل إنشاء الإشعار: $e');
    }
  }
}
