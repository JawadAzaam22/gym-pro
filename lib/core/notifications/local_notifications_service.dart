import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// طبقة التنبيهات المحلية (إشعارات النظام) — تعمل والتطبيق مُغلق.
///
/// مجانية 100%: تعتمد على `flutter_local_notifications` بدون أي خادم أو خدمة
/// مدفوعة (لا FCM ولا OneSignal).
///
/// الاستخدام:
/// ```dart
/// final svc = LocalNotificationsService();
/// await svc.init();
/// await svc.requestPermission();
/// await svc.scheduleAt(id: 1, title: 'حصتك بعد ساعة', when: sessionStart);
/// ```
///
/// ملاحظات:
/// - كل استدعاء ملفوف بـ try/catch: تعذّر تشغيل الطبقة (منصة غير مدعومة،
///   بيئة اختبار بلا قنوات منصّة) لا يُسقط التطبيق أبداً.
/// - `scheduleAt` يتجاهل الأوقات الماضية عوضاً عن رمي خطأ.
class LocalNotificationsService {
  LocalNotificationsService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// نسخة مشتركة عبر التطبيق (تُهيَّأ مرة واحدة في `bootstrap()`).
  static final LocalNotificationsService instance =
      LocalNotificationsService();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  /// هل اكتملت التهيئة؟ الطرق الأخرى ترجع `false` بلا عمل إن لم تكتمل.
  bool get isReady => _ready;

  static const String channelId = 'gym_pro_alerts';
  static const String channelName = 'تنبيهات الصالة';
  static const String channelDescription =
      'تذكيرات مواعيد الحصص وانتهاء الاشتراكات';

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  /// تهيئة قاعدة المناطق الزمنية + المحطة (channel) + صلاحية العرض.
  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // نؤجّل طلب الصلاحيات إلى [requestPermission] ليكون الطلب صريحاً.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      await _createChannel();
      _ready = true;
    } catch (e) {
      debugPrint('[LocalNotifications] init failed: $e');
    }
  }

  Future<void> _createChannel() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.high,
      ),
    );
  }

  /// طلب صلاحية عرض الإشعارات (Android 13+ و iOS).
  ///
  /// يُستدعى مرة واحدة بعد [init]; التكرار آمن.
  Future<void> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) await android.requestNotificationsPermission();

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      debugPrint('[LocalNotifications] permission request failed: $e');
    }
  }

  /// عرض تنبيه فوري.
  Future<bool> showNow({
    required int id,
    required String title,
    String? body,
    String? payload,
  }) async {
    if (!_ready) return false;
    try {
      await _plugin.show(id, title, body, _details, payload: payload);
      return true;
    } catch (e) {
      debugPrint('[LocalNotifications] show failed: $e');
      return false;
    }
  }

  /// جدولة تنبيه في وقت معيّن.
  ///
  /// تُرجع `false` (دون رمي خطأ) إذا كان الموعد قد مضى أو تعذّر الجدولة.
  Future<bool> scheduleAt({
    required int id,
    required String title,
    String? body,
    required DateTime when,
    String? payload,
  }) async {
    if (!_ready) return false;
    if (!isSchedulable(when)) {
      debugPrint('[LocalNotifications] skipped past schedule: $when');
      return false;
    }
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        toTz(when),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
      return true;
    } catch (e) {
      debugPrint('[LocalNotifications] schedule failed: $e');
      return false;
    }
  }

  /// إلغاء تنبيه مجدول مسبقاً (مثلاً عند إلغاء الحصة).
  Future<void> cancel(int id) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('[LocalNotifications] cancel failed: $e');
    }
  }

  /// إلغاء كل التنبيهات المجدولة (عند تسجيل الخروج مثلاً).
  Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('[LocalNotifications] cancelAll failed: $e');
    }
  }

  // -------------------------------------------------------------------------
  // دوال نقية قابلة للاختبار بلا قنوات منصّة
  // -------------------------------------------------------------------------

  /// يحوّل لحظة إلى `TZDateTime` بنفس **اللحظة** (نقطة الزمن) في المنطقة
  /// الزمنية المحلية الحالية — هذا ما يعتمد عليه المنصّات لتشغيل التنبيه.
  static tz.TZDateTime toTz(DateTime when) =>
      tz.TZDateTime.from(when, tz.local);

  /// هل الموعد صالح للجدولة؟ أي: لم يمضِ بعد بالنسبة لـ [now].
  ///
  /// لا نفرض حداً أدنى للمستقبل: تنبيه مجدول بعد ثوانٍ يُسلَّم متأخراً قليلاً
  /// (الجدولة غير الدقيقة لا تسبق الموعد أبداً) وهو أفضل من عدم التنبيه إطلاقاً.
  static bool isSchedulable(DateTime when, [DateTime? now]) =>
      !when.isBefore(now ?? DateTime.now());

  /// مُعرّف تنبيه ثابت لمفتاح نصّي (يمنع التصادم بين التنبيهات).
  static int idFor(String key) => key.hashCode & 0x7fffffff;
}
