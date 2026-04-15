import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette - Teal/Emerald medical theme
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryLight = Color(0xFF5EEAD4);
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color primarySurface = Color(0xFFE6FAF7);

  // Secondary palette
  static const Color secondary = Color(0xFF6366F1);
  static const Color secondaryLight = Color(0xFFA5B4FC);
  static const Color secondaryDark = Color(0xFF4338CA);

  // Accent
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFDE68A);

  // Status colors
  static const Color pending = Color(0xFFF59E0B);
  static const Color underReview = Color(0xFF3B82F6);
  static const Color approved = Color(0xFF10B981);
  static const Color rejected = Color(0xFFEF4444);
  static const Color paid = Color(0xFF8B5CF6);

  // Neutral palette
  static const Color background = Color(0xFFF8FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Dark theme
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D9488), Color(0xFF06B6D4)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF06B6D4)],
  );
}
