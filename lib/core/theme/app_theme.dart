import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    final cairo = GoogleFonts.cairoTextTheme();
    const colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF541200),
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      onSurface: AppColors.textOnSurface,
      surfaceContainer: AppColors.surfaceCard,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.outline,
      outlineVariant: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: colorScheme,
      textTheme: cairo.copyWith(
        displayLarge: cairo.displayLarge?.copyWith(fontFamily: 'Cairo', fontSize: 44, fontWeight: FontWeight.w800, height: 56 / 44, color: AppColors.textPrimary),
        headlineLarge: cairo.headlineLarge?.copyWith(fontFamily: 'Cairo', fontSize: 32, fontWeight: FontWeight.w700, height: 44 / 32, color: AppColors.textPrimary),
        headlineMedium: cairo.headlineMedium?.copyWith(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.w700, height: 34 / 24, color: AppColors.textPrimary),
        titleMedium: cairo.titleMedium?.copyWith(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w600, height: 30 / 20, color: AppColors.textPrimary),
        bodyLarge: cairo.bodyLarge?.copyWith(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w500, height: 28 / 18, color: AppColors.textSecondary),
        bodyMedium: cairo.bodyMedium?.copyWith(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w400, height: 26 / 16, color: AppColors.textSecondary),
        bodySmall: cairo.bodySmall?.copyWith(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w400, height: 22 / 14, color: AppColors.textMuted),
        labelLarge: cairo.labelLarge?.copyWith(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        labelMedium: cairo.labelMedium?.copyWith(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardTheme(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: AppColors.primaryGlow,
          minimumSize: const Size.fromHeight(52),
          textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLow,
        hintStyle: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 14),
        labelStyle: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLow,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
      ),
    );
  }

  // لتوافق الكود القديم — يعيد الداكن افتراضياً
  static ThemeData get lightTheme => darkTheme;

  // TextStyles السريعة لاستخدام StatCounter
  static TextStyle get statCounter => GoogleFonts.cairo(fontSize: 36, fontWeight: FontWeight.w800, height: 44 / 36, letterSpacing: -0.5, color: AppColors.textPrimary);
}
