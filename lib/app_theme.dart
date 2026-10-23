import 'package:flutter/material.dart';

/// Sistema de design moderno do UNEX PLAY.
/// Tema escuro premium com acento ciano, dourado para qualidade,
/// foco de TV com escala + brilho, e cantos arredondados.
class AppTheme {
  // Cores base
  static const Color background = Color(0xFF0A0E17);
  static const Color surface = Color(0xFF151B26);
  static const Color surfaceHighlight = Color(0xFF1E2633);
  static const Color accent = Color(0xFF00E5FF);
  static const Color accentDim = Color(0xFF0088A3);
  static const Color gold = Color(0xFFFFD54F);
  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFF8A94A6);
  static const Color textMuted = Color(0xFF5A6478);
  static const Color danger = Color(0xFFFF4D6D);
  static const Color success = Color(0xFF2ED573);
  static const Color skeleton = Color(0xFF1A202C);
  static const Color skeletonShimmer = Color(0xFF262E3D);

  // Gradientes
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF0099CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xDD0A0E17)],
    stops: [0.4, 1.0],
  );

  // Raios de borda
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  // Área segura para TV (overscan)
  static const double overscan = 24;

  // Estilos de texto
  static const TextStyle titleH1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: textPrimary,
    letterSpacing: -0.3,
  );
  static const TextStyle titleH2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.2,
  );
  static const TextStyle body = TextStyle(fontSize: 14, color: textPrimary);
  static const TextStyle caption = TextStyle(fontSize: 12, color: textSecondary);
  static const TextStyle badge = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.6,
  );

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: gold,
        surface: surface,
        error: danger,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textPrimary),
        labelLarge: TextStyle(color: textPrimary),
      ),
      focusColor: accent,
      highlightColor: accent.withValues(alpha: 0.2),
      splashColor: accent.withValues(alpha: 0.15),
      dividerColor: Colors.white10,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textPrimary,
      ),
    );
  }

  /// Badge de qualidade (HD/FHD/4K) com cor apropriada.
  static Widget qualityBadge(String? quality) {
    final q = (quality ?? "").toUpperCase();
    Color color = textSecondary;
    if (q.contains("4K") || q.contains("UHD")) {
      color = gold;
    } else if (q.contains("FHD") || q.contains("1080")) {
      color = accent;
    } else if (q.contains("HD") || q.contains("720")) {
      color = success;
    } else if (q.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(q, style: badge.copyWith(color: color)),
    );
  }
}
