import 'package:flutter/material.dart';

/// Shared colors and theme for every screen (customer and courier).
class AppColors {
  static const backgroundTop = Color(0xFF2A1650);
  static const backgroundBottom = Color(0xFF120A24);
  static const accent = Color(0xFF8B6CF0);
  static const accentSoft = Color(0xFFB8A4FF);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFCFC4EE);
  static const textMuted = Color(0xFF8E83AE);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: AppColors.accent,
    scaffoldBackgroundColor: AppColors.backgroundBottom,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: TextStyle(color: AppColors.textSecondary),
      bodySmall: TextStyle(color: AppColors.textMuted),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF3A2470),
      contentTextStyle: const TextStyle(color: AppColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
