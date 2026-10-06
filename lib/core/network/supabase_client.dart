import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider مركزي للوصول إلى SupabaseClient في كل الطبقات
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider للوصول إلى Supabase auth
final supabaseAuthProvider = Provider<GoTrueClient>((ref) {
  return Supabase.instance.client.auth;
});

/// Helper للتحقق من تسجيل الدخول
final isLoggedInProvider = Provider<bool>((ref) {
  final auth = ref.watch(supabaseAuthProvider);
  return auth.currentSession != null;
});
