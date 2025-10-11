import 'package:flutter/material.dart';

/// Centralized theme configuration for GeoFront App
/// Single point of control for all colors and styling
/// Automatically adapts to system light/dark mode
class AppTheme {
  // Primary seed color - Cyan
  // Change this ONE color to change the entire app theme!
  static const Color seedColor = Colors.cyan; // Material Cyan

  // Semantic colors for problem difficulties (work in both themes)
  static const Color beginnerColor = Color(0xFFC8E6C9); // Light Green
  static const Color intermediateColor = Color(0xFFFFF9C4); // Light Yellow
  static const Color advancedColor = Color(0xFFFFE0B2); // Light Orange
  static const Color expertColor = Color(0xFFFFCDD2); // Light Red

  // Category color (adapts to theme)
  static Color getCategoryColor(Brightness brightness) {
    return brightness == Brightness.light
        ? const Color(0xFFBBDEFB) // Light Blue for light theme
        : const Color(0xFF1E88E5); // Darker Blue for dark theme
  }

  // Light theme - uses cyan seed color
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // Dark theme - uses cyan seed color with dark brightness
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        elevation: 4, // More elevation in dark theme
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // Helper method to get difficulty color
  static Color getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return beginnerColor;
      case 'intermediate':
        return intermediateColor;
      case 'advanced':
        return advancedColor;
      case 'expert':
        return expertColor;
      default:
        return beginnerColor;
    }
  }
}
