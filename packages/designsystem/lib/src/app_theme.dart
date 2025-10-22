import 'package:flutter/material.dart';

import 'app_palette.dart';

class AppTheme {
  const AppTheme._();

  static const Color beginnerColor = AppPalette.beginner;
  static const Color intermediateColor = AppPalette.intermediate;
  static const Color advancedColor = AppPalette.advanced;
  static const Color expertColor = AppPalette.expert;

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.secondary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppPalette.primary,
      secondary: AppPalette.secondary,
      tertiary: AppPalette.accent,
      surface: AppPalette.neutralLight,
      surfaceContainerHighest: Colors.white,
      onSurface: AppPalette.neutralDark,
      onPrimary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppPalette.neutralLight,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppPalette.neutralDark,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.accent,
          foregroundColor: AppPalette.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.secondary,
          side: const BorderSide(color: AppPalette.secondary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selectedColor: AppPalette.secondary.withOpacity(0.1),
        side: BorderSide(color: AppPalette.secondary.withOpacity(0.2)),
        labelStyle: const TextStyle(color: AppPalette.neutralDark),
        secondaryLabelStyle: const TextStyle(color: AppPalette.neutralDark),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.secondary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppPalette.secondary,
      secondary: AppPalette.accent,
      surface: const Color(0xFF111827),
      surfaceContainerHighest: const Color(0xFF1F2937),
      onSurface: Colors.white.withOpacity(0.9),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0B1627),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.accent,
          foregroundColor: AppPalette.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.accent,
          side:
              BorderSide(color: AppPalette.accent.withOpacity(0.6), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selectedColor: AppPalette.accent.withOpacity(0.18),
        side: BorderSide(color: AppPalette.accent.withOpacity(0.25)),
        labelStyle: const TextStyle(color: Colors.white),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  static Color getCategoryColor(Brightness brightness) {
    return brightness == Brightness.light
        ? AppPalette.secondary.withOpacity(0.12)
        : AppPalette.accent.withOpacity(0.18);
  }

  static Color getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return AppPalette.beginner;
      case 'intermediate':
        return AppPalette.intermediate;
      case 'advanced':
        return AppPalette.advanced;
      case 'expert':
        return AppPalette.expert;
      default:
        return AppPalette.beginner;
    }
  }
}
