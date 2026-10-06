import 'exceptions.dart';

Never handleSupabaseError(dynamic e, String context) {
  final msg = e.toString();
  if (msg.contains('42501') || msg.contains('row-level security')) {
    throw ServerException(
      '$context: فشل بسبب سياسة الأمان (RLS). شغّل supabase/fix_rls_400.sql في Supabase SQL Editor لتعطيل RLS أو إضافة Policies. التفاصيل: $msg',
    );
  }
  if (msg.contains('23505')) {
    throw ServerException('$context: بيانات مكررة (مثل البريد أو الهاتف موجود مسبقاً). $msg');
  }
  throw ServerException('$context: $msg');
}
