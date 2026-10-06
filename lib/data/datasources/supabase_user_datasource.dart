import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../core/errors/exceptions.dart';
import '../models/user_model.dart';

/// إدارة المستخدمين على السكيمة الجديدة (جدول profiles + Edge Function).
/// - الإنشاء حصرًا عبر Edge Function `create-user` (ترسل: name,email,phone,password,role,gender).
/// - لا يُخزَّن أي password محليًا بعد الاستجابة.
/// - بعد تغيير profiles.role لمستخدم آخر، يحتاج ذلك المستخدم refreshSession()
///   (أو خروج/دخول) ليأخذ الـ JWT الجديد مفعوله.
class SupabaseUserDatasource {
  final SupabaseClient client;
  SupabaseUserDatasource(this.client);

  /// يجلب جميع المستخدمين النشطين فقط من جدول profiles.
  Future<List<UserModel>> getAllUsers({bool activeOnly = true}) async {
    try {
      var query = client.from('profiles').select();
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final data = await query.order('created_at');
      return (data as List).map((e) => UserModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      // تحليل أخطاء RLS بشكل أوضح
      if (e.code == '42501' || e.code == 'PGRST301') {
        throw ServerException(
            'خطأ صلاحيات (RLS): دورك الحالي لا يملك صلاحية قراءة بيانات المستخدمين. '
            'تأكد من سياسة Row Level Security على جدول profiles. '
            'رمز الخطأ: ${e.code}');
      }
      if (e.code == '42P01') {
        throw ServerException('جدول profiles غير موجود في قاعدة البيانات');
      }
      throw ServerException('فشل جلب المستخدمين [${e.code}]: ${e.message}');
    } catch (e) {
      throw ServerException('فشل جلب المستخدمين: $e');
    }
  }

  Future<UserModel> getUserById(String id) async {
    try {
      final data = await client.from('profiles').select().eq('id', id).single();
      return UserModel.fromJson(data);
    } catch (e) {
      throw ServerException('المستخدم غير موجود: $e');
    }
  }

  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final data = await client.from('profiles').select().eq('role', role).order('name');
      return (data as List).map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب المستخدمين حسب الدور: $e');
    }
  }

  Future<UserModel> createUser(UserModel user, String password) async {
    final payload = <String, dynamic>{
      'name': user.name,
      'email': user.email,
      'phone': user.phone,
      'password': password,
      'role': user.role.name,
      'gender': user.gender.name,
    };
    try {
      final res = await client.functions.invoke('create-user', body: payload);
      if (kDebugMode) debugPrint('[create-user] STATUS: ${res.status}, DATA: ${res.data}');
      final data = res.data;
      if (res.status != 200) {
        final msg = (data is Map && data['error'] != null) ? data['error'].toString() : data.toString();
        throw ServerException('فشل إنشاء المستخدم: $msg');
      }
      return UserModel.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (e, st) {
      // تشخيص مؤقت: طباعة كامل التفاصيل بدل رسالة عامة (وضع التصحيح فقط)
      if (kDebugMode) {
        debugPrint('[create-user] FUNCTION CALL ERROR: $e');
        debugPrint('[create-user] TYPE: ${e.runtimeType}');
        debugPrint('[create-user] STACK: $st');
      }
      if (e is ServerException) rethrow;
      throw ServerException('فشل إنشاء المستخدم: $e');
    }
  }

  Future<UserModel> updateUser(UserModel user) async {
    try {
      final map = user.toJson()..remove('id')..remove('created_at');
      final updated = await client.from('profiles').update(map).eq('id', user.id).select().single();
      return UserModel.fromJson(updated);
    } catch (e) {
      throw ServerException('فشل تحديث المستخدم: $e');
    }
  }

  Future<void> deactivateUser(String id) async {
    try {
      await client.from('profiles').update({'is_active': false}).eq('id', id);
    } catch (e) {
      throw ServerException('فشل تعطيل المستخدم: $e');
    }
  }

  Future<void> deleteUser(String id, {bool cascade = false}) async {
    try {
      // mode: "safe" (افتراضي) يرفض الحذف إن وُجدت سجلات مرتبطة (يحافظ على
      // التاريخ كاملاً). mode: "cascade" يؤرشف كل شيء في
      // deleted_users_archive أولاً ثم يحذف سجلاته الشخصية ويُفرغ إسناده في
      // السجلات المشتركة (تقارير/حصص/مدفوعات آخرين) بدل حذفها، ثم يحذف
      // الحساب نهائياً. الحل الصحيح للحذف نفسه: Edge Function مخصصة
      // (delete-user) تستخدم صلاحية service_role لحذف المستخدم من
      // auth.users عبر Admin API مباشرة، لأن حذف صف profiles وحده عبر
      // RLS من العميل غير ممكن أصلاً (لا توجد سياسة DELETE عليه)، وحتى لو
      // كانت موجودة فسيبقى الحساب في auth.users ويكسر تسجيل الدخول.
      final res = await client.functions.invoke('delete-user',
          body: {'id': id, 'mode': cascade ? 'cascade' : 'safe'});
      final data = res.data;
      if (res.status != 200 || (data is Map && data['error'] != null)) {
        final msg = (data is Map ? data['error'] : null) ?? 'فشل حذف المستخدم';
        throw ServerException(msg.toString());
      }
    } on FunctionException catch (e) {
      final details = e.details;
      final msg = (details is Map ? details['error'] : null) ?? e.toString();
      throw ServerException('فشل حذف المستخدم: $msg');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('فشل حذف المستخدم: $e');
    }
  }
}
