import 'package:flutter/material.dart';

/// Athletic Pulse — Dark Modernism tokens من DESIGN.md
abstract class AppColors {
  // Brand
  static const primary = Color(0xFFFF5722); // Athletic Orange
  static const primaryHover = Color(0xFFE64A19);
  static const primaryGlow = Color(0x59FF5722); // 35% opacity glow

  // Surfaces (dark hierarchy L0-L3)
  static const background = Color(0xFF101319); // L0 background = surface
  static const surface = Color(0xFF1A1D23); // base floor
  static const surfaceLow = Color(0xFF1E222A); // L1
  static const surfaceCard = Color(0xFF232730); // L2
  static const surfaceOverlay = Color(0xFF2B303C); // L3
  static const surfaceVariant = Color(0xFF32353B);

  // Borders / outlines
  static const border = Color(0xFF2E3440);
  static const borderStrong = Color(0xFF3A4252);
  static const outline = Color(0xFFAB8980);
  static const outlineVariant = Color(0xFF5B4039);

  // Text tiers
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFD1D5DB);
  static const textMuted = Color(0xFF9CA3AF);
  static const textOnSurface = Color(0xFFE1E2EA);

  // Semantic
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  static const errorContainer = Color(0xFF93000A);

  // Legacy aliases للتوافق
  static const primaryDark = Color(0xFFB02F00);
  static const secondary = Color(0xFFC3C6D2);
  static const disabled = Color(0xFF6B7280);
}
