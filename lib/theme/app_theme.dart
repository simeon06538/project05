import 'package:flutter/material.dart';

/// Shared colors and theme for every screen (customer and courier).
class AppColors {
  static const backgroundTop = Color(0xFF2A1650);
  static const backgroundBottom = Color(0xFF120A24);
  static const accent = Color(0xFF8B6CF0);
  static const accentSoft = Color(0xFFB8A4FF);

  /// K-30: filled buttons with white text use this deeper purple, which
  /// passes WCAG AA contrast (about 5.6:1); [accent] alone is only 3.8:1.
  static const accentStrong = Color(0xFF6D4ED8);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFCFC4EE);
  // Light enough for small text to keep 4.5:1 contrast even over the
  // purple glows in the background (K-30/K-31).
  static const textMuted = Color(0xFFA99FC9);
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
    // K-15: shared defaults so every screen - courier and customer - gets
    // the same purple glass look without restyling each widget.
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accent,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.accentSoft),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accentStrong,
        foregroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.accentSoft),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    // Frosted input fields like the request form in the team mockup.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x14FFFFFF),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.accentSoft, width: 1.5),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF3A2470),
      contentTextStyle: const TextStyle(color: AppColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
