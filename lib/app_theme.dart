import 'package:flutter/material.dart';

/// Tokens de tema: área segura (overscan), cores, foco para TV.
class AppTheme {
  static const Color background = Color(0xFF0E1116);
  static const Color surface = Color(0xFF1A1F26);
  static const Color accent = Color(0xFF3DDC84);
  static const Color accentDim = Color(0xFF1E8C54);
  static const Color textPrimary = Color(0xFFF0F2F5);
  static const Color textSecondary = Color(0xFF9AA3AF);
  static const Color skeleton = Color(0xFF1A1A1A);
  static const Color skeletonShimmer = Color(0xFF262626);
  static const Color danger = Color(0xFFE5484D);

  // Área segura para TV (overscan)
  static const double overscan = 24;

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: surface,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textPrimary),
        labelLarge: TextStyle(color: textPrimary),
      ),
      focusColor: accent,
      highlightColor: accent.withOpacity(0.2),
    );
  }
}
