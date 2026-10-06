import 'package:flutter/material.dart';
import 'app_theme.dart';
import '../constants/app_colors.dart';

/// ثيم الويب - نفس Athletic Pulse مع حاوية أوسع وشريط جانبي ثابت 280px
class WebTheme {
  static ThemeData get theme {
    final base = AppTheme.darkTheme;
    return base.copyWith(scaffoldBackgroundColor: AppColors.background);
  }
}
