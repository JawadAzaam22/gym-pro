import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Listenable يعيد بناء GoRouter عند تغيّر حالة المصادقة
/// (تسجيل دخول/خروج أو انتهاء الجلسة) حتى تعمل `redirect` guards لحظيًا.
/// يُنشأ بعد bootstrap حصرًا (داخل دوال بناء الـ Router وليس كمتغير علوي).
class AuthRefreshListenable extends ChangeNotifier {
  StreamSubscription<AuthState>? _sub;

  AuthRefreshListenable() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
