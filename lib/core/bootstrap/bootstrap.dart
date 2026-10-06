import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../notifications/local_notifications_service.dart';

/// تهيئة Supabase + المتغيرات + أي خدمات أخرى قبل تشغيل التطبيق
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تحميل متغيرات البيئة
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    debugPrint('[bootstrap] .env not found, using fallback');
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  // يدعم كل من ANON_KEY (JWT) و PUBLISHABLE_KEY (sb_publishable_...) والاسم الجديد
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ??
      dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
      dotenv.env['SUPABASE_PUBLISHABLE'] ??
      '';

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      debugPrint('[bootstrap] Supabase initialized with ${supabaseAnonKey.startsWith('sb_publishable') ? 'publishable' : 'anon'} key');
    } catch (e) {
      debugPrint('[bootstrap] Supabase init failed: $e');
      debugPrint('[bootstrap] hint: إذا كان الخطأ 400/42501 شغّل supabase/fix_rls_400.sql');
    }
  } else {
    debugPrint('[bootstrap] Supabase credentials missing - running in offline/mock mode');
  }

  // تهيئة التنبيهات المحلية (مجانية 100% — بلا خادم).
  // كل ما بداخلها try/catch: منصة غير مدعومة أو بيئة اختبار بلا قنوات
  // منصّة لا تُسقط التطبيق.
  try {
    await LocalNotificationsService.instance.init();
    await LocalNotificationsService.instance.requestPermission();
    debugPrint(
        '[bootstrap] Local notifications ready: ${LocalNotificationsService.instance.isReady}');
  } catch (e) {
    debugPrint('[bootstrap] Local notifications init failed: $e');
  }

  // هنا يمكن إضافة Sentry أو FirebaseCrashlytics
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };
}
