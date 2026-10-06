import 'package:supabase_flutter/supabase_flutter.dart';

/// نتيجة فحص الجلسة/الدور من الخادم.
class SessionRoleInfo {
  final String? role;
  final bool? isActive;
  const SessionRoleInfo({this.role, this.isActive});
}

/// تخزين مؤقت قصير (TTL 60 ثانية) لمعلومات الدور/الحالة حتى لا نضرب
/// الخادم بطلب profiles مع كل تنقّل في `redirect` الخاص بـ GoRouter.
/// يُستخدم من كل الراوترات (admin / reception / mobile).
class SessionRoleCache {
  static const ttl = Duration(seconds: 60);
  static String? _userId;
  static String? _role;
  static bool? _isActive;
  static DateTime? _fetchedAt;
  // يمنع "cache stampede": عدة نداءات متزامنة لـ resolve() (شائعة جدًا لأن
  // GoRouter قد يستدعي redirect() أكثر من مرة خلال نفس عملية التنقل) كانت
  // كلها تفوّت الكاش معًا قبل أن يكتمل أول طلب ويحدّث _fetchedAt، فتُطلق
  // عدة طلبات شبكة متطابقة لنفس المستخدم خلال ثوانٍ (لاحظنا هذا فعليًا في
  // سجلات Supabase: 4 طلبات لنفس uid خلال 4 ثوانٍ). الآن أي نداء يصل أثناء
  // وجود طلب قيد التنفيذ ينتظر نفس الـ Future بدل إطلاق طلب جديد.
  static Future<SessionRoleInfo>? _inFlight;

  /// يجلب role و is_active للمستخدم الحالي (مع cache قصير).
  /// يعيد nulls عند غياب الجلسة أو فشل الشبكة (ويترك قرار redirect
  /// للمنطق الآمن: البقاء حيث نحن بدل الطرد الخاطئ).
  static Future<SessionRoleInfo> resolve() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    if (session == null) {
      invalidate();
      return const SessionRoleInfo();
    }
    final uid = session.user.id;
    final now = DateTime.now();
    if (_userId == uid && _fetchedAt != null && now.difference(_fetchedAt!) < ttl) {
      return SessionRoleInfo(role: _role, isActive: _isActive);
    }
    if (_inFlight != null) {
      return _inFlight!;
    }
    final future = _fetchFromServer(client, uid, now);
    _inFlight = future;
    try {
      return await future;
    } finally {
      _inFlight = null;
    }
  }

  static Future<SessionRoleInfo> _fetchFromServer(
      SupabaseClient client, String uid, DateTime now) async {
    try {
      final data = await client.from('profiles').select('role, is_active').eq('id', uid).maybeSingle();
      if (data == null) return const SessionRoleInfo();
      _userId = uid;
      _role = (data['role'] as String?)?.toLowerCase();
      _isActive = data['is_active'] as bool? ?? true;
      _fetchedAt = now;
      return SessionRoleInfo(role: _role, isActive: _isActive);
    } catch (_) {
      // فشل شبكة/قاعدة بيانات: لا نطرد المستخدم، نعيد آخر قيمة معروفة
      // (أو nulls في أول تحميل) حتى لا يُسجَّل خروج خاطئ.
      return SessionRoleInfo(role: _role, isActive: _isActive);
    }
  }

  static void invalidate() {
    _userId = null;
    _role = null;
    _isActive = null;
    _fetchedAt = null;
  }
}
