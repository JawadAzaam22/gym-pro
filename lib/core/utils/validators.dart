abstract class Validators {
  static String? required(String? value, [String field = 'هذا الحقل']) {
    if (value == null || value.trim().isEmpty) {
      return '$field مطلوب';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'البريد الإلكتروني مطلوب';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'البريد الإلكتروني غير صالح';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'كلمة المرور مطلوبة';
    if (value.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'رقم الهاتف مطلوب';
    final regex = RegExp(r'^01[0-2,5]{1}[0-9]{8}$');
    if (!regex.hasMatch(value)) return 'رقم الهاتف غير صالح (مثال: 01012345678)';
    return null;
  }

  static String? notEmpty(String? value) => required(value);

  static String? positiveNumber(String? value, String field) {
    if (value == null || value.isEmpty) return '$field مطلوب';
    final n = double.tryParse(value);
    if (n == null || n <= 0) return '$field يجب أن يكون رقمًا موجبًا';
    return null;
  }

  static String? capacity(String? value) {
    if (value == null || value.isEmpty) return 'السعة مطلوبة';
    final n = int.tryParse(value);
    if (n == null || n <= 0) return 'السعة يجب أن تكون رقمًا موجبًا';
    return null;
  }
}
