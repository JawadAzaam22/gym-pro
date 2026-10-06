import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/exceptions.dart' as app_ex;
import '../models/user_model.dart';

/// مصدر Auth للسكيمة الجديدة:
/// - تسجيل الدخول عبر Supabase Auth الحقيقي فقط (signInWithPassword).
/// - جدول public.profiles حيث profiles.id == auth.users.id (uuid).
/// - الدور متاح في JWT عبر app_role claim وكذلك عمود profiles.role.
/// - لا يوجد عمود password في أي جدول عام، ولا جدول users بعد الآن.

class SupabaseAuthDatasource {
  final SupabaseClient client;
  SupabaseAuthDatasource(this.client);

  Future<UserModel> login(String email, String password) async {
    try {
      final res = await client.auth.signInWithPassword(email: email, password: password);
      final user = res.user;
      if (user == null) throw app_ex.AuthException('البريد أو كلمة المرور غير صحيحة');
      final profile = await client.from('profiles').select().eq('id', user.id).single();
      return UserModel.fromJson(profile);
    } on AuthException catch (e) {
      throw app_ex.AuthException(e.message);
    } catch (e) {
      if (e is app_ex.AuthException) rethrow;
      if (e.toString().contains('42501') || e.toString().contains('row-level security')) {
        throw app_ex.AuthException('فشل تسجيل الدخول بسبب RLS. تحقق من سياسات profiles. التفاصيل: $e');
      }
      throw app_ex.AuthException('فشل تسجيل الدخول: $e');
    }
  }

  Future<void> logout() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      throw app_ex.ServerException('فشل تسجيل الخروج: $e');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final session = client.auth.currentSession;
    if (session == null) return null;
    try {
      final data = await client.from('profiles').select().eq('id', session.user.id).maybeSingle();
      if (data == null) return null;
      return UserModel.fromJson(data);
    } catch (e) {
      throw app_ex.ServerException('فشل جلب المستخدم الحالي: $e');
    }
  }

  Stream<UserModel?> authStateChanges() {
    return client.auth.onAuthStateChange.asyncMap((event) async {
      final session = event.session;
      if (session == null) return null;
      final data = await client.from('profiles').select().eq('id', session.user.id).maybeSingle();
      if (data == null) return null;
      return UserModel.fromJson(data);
    });
  }

  /// بعد تغيير profiles.role لأي مستخدم، يجب على ذلك المستخدم استدعاء
  /// `client.auth.refreshSession()` (أو تسجيل خروج/دخول) حتى يتحدّث
  /// الـ JWT (app_role claim) بالدور الجديد.
  Future<void> refreshSession() async {
    try {
      await client.auth.refreshSession();
    } catch (e) {
      throw app_ex.ServerException('فشل تحديث الجلسة: $e');
    }
  }
}
