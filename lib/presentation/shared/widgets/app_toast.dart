import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// رسائل نجاح/خطأ/تنبيه موحّدة الشكل في كل التطبيق.
///
/// كانت الرسائل مبعثرة عبر 23 ملفًا تقريبًا، كل واحد يبني
/// `ScaffoldMessenger.showSnackBar(SnackBar(...))` يدويًا بأسلوبه الخاص
/// (بعضها بلا أيقونة، بعضها بدون حواف دائرية، ألوان غير متسقة أحيانًا).
/// هذا الملف نقطة واحدة موحّدة: أيقونة مطابقة للنوع، حواف دائرية، هامش عن
/// الحواف (floating) حتى لا يلتصق بشريط التنقل السفلي، ومدة عرض أطول
/// تلقائيًا لرسائل الخطأ (تحتاج وقتًا أطول للقراءة) من رسائل النجاح.
///
/// الاستخدام:
/// ```dart
/// AppToast.success(context, 'تم الحفظ');
/// AppToast.error(context, 'فشل الحفظ: ...');
/// AppToast.info(context, 'جاري المعالجة...');
/// AppToast.warning(context, 'تنبيه...');
/// ```
/// أو مباشرة من نتيجة Either:
/// ```dart
/// res.fold(
///   (f) => AppToast.error(context, f.message),
///   (_) => AppToast.success(context, 'تم الحفظ'),
/// );
/// ```
class AppToast {
  AppToast._();

  static void success(BuildContext context, String message) =>
      _show(context, message, icon: Icons.check_circle_rounded, color: AppColors.success);

  static void error(BuildContext context, String message) => _show(
      context, message,
      icon: Icons.error_rounded, color: AppColors.error, duration: const Duration(seconds: 4));

  static void info(BuildContext context, String message) =>
      _show(context, message, icon: Icons.info_rounded, color: AppColors.info);

  static void warning(BuildContext context, String message) => _show(
      context, message,
      icon: Icons.warning_rounded, color: AppColors.warning, duration: const Duration(seconds: 3));

  static void _show(
    BuildContext context,
    String message, {
    required IconData icon,
    required Color color,
    Duration duration = const Duration(seconds: 2, milliseconds: 500),
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceCard,
          duration: duration,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withOpacity(0.4)),
          ),
          elevation: 4,
          content: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
