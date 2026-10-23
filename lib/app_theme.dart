import 'package:flutter/material.dart';

/// Sistema de design moderno do UNEX PLAY (2026).
/// Tema escuro premium com acento ciano, dourado para qualidade,
/// foco de TV com escala + brilho (glow), cantos arredondados generosos
/// e efeito "glass" seletivo (sem blur pesado — performance em TV boxes antigas).
class AppTheme {
  // Cores base
  static const Color background = Color(0xFF0A0E17);
  static const Color backgroundDeep = Color(0xFF060910);
  static const Color surface = Color(0xFF151B26);
  static const Color surfaceHighlight = Color(0xFF1E2633);
  static const Color accent = Color(0xFF00E5FF);
  static const Color accentDim = Color(0xFF0088A3);
  static const Color accentDeep = Color(0xFF003B46);
  static const Color gold = Color(0xFFFFD54F);
  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFF8A94A6);
  static const Color textMuted = Color(0xFF5A6478);
  static const Color danger = Color(0xFFFF4D6D);
  static const Color success = Color(0xFF2ED573);
  static const Color skeleton = Color(0xFF1A202C);
  static const Color skeletonShimmer = Color(0xFF262E3D);

  // Superfície "glass" (frosted) — semi-transparente com borda sutil.
  // Usada em sidebars e painéis flutuantes. Sem blur real para manter 60fps.
  static const Color glassSurface = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x1FFFFFFF);

  // Gradientes
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF0099CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradiente de fundo ambiental (usado no shell e telas de detalhe).
  static const RadialGradient ambientGradient = RadialGradient(
    center: Alignment.topRight,
    radius: 1.2,
    colors: [Color(0xFF12202E), background],
    stops: [0.0, 0.6],
  );

  // Gradiente sobreposto em pôsteres (legibilidade do título).
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xDD0A0E17)],
    stops: [0.4, 1.0],
  );

  // Gradiente de brilho para o estado de foco (borda animada).
  static const LinearGradient focusGlowGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF7DF9FF), Color(0xFF0099CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Raios de borda (generosos para visual moderna 2026)
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusPoster = 18;
  static const double radiusChannel = 14;

  // Área segura para TV (overscan)
  static const double overscan = 24;

  // Elevação / sombras
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> focusGlow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.45),
          blurRadius: 24,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.2),
          blurRadius: 48,
          spreadRadius: 6,
        ),
      ];

  // Estilos de texto (tipografia grande para 10-foot UI)
  static const TextStyle titleH1 = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w900,
    color: textPrimary,
    letterSpacing: -0.3,
    height: 1.1,
  );
  static const TextStyle titleH2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.2,
  );
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.1,
  );
  static const TextStyle body = TextStyle(fontSize: 14, color: textPrimary);
  static const TextStyle caption = TextStyle(fontSize: 12, color: textSecondary);

  // Nome de canal em lista (grande, sem cortar)
  static const TextStyle channelName = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.2,
  );
  static const TextStyle channelMeta = TextStyle(
    fontSize: 12,
    color: textSecondary,
  );

  // Título de pôster (filme/série)
  static const TextStyle posterTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    height: 1.15,
  );
  static const TextStyle posterMeta = TextStyle(
    fontSize: 11,
    color: Color(0xFFB8C0CC),
  );

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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(q, style: badge.copyWith(color: color, fontSize: 9)),
    );
  }

  /// Badge "AO VIVO" pulsante (ao lado do nome do canal).
  static Widget liveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: danger.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: danger.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: const [
        _LiveDot(),
        SizedBox(width: 4),
        Text("AO VIVO", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: danger, letterSpacing: 0.5)),
      ]),
    );
  }
}

/// Pontinho vermelho pulsante do badge "AO VIVO".
class _LiveDot extends StatefulWidget {
  const _LiveDot();
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.danger,
          boxShadow: [
            BoxShadow(
              color: AppTheme.danger.withValues(alpha: 0.3 + 0.7 * _ctrl.value),
              blurRadius: 6,
              spreadRadius: 1 + 2 * _ctrl.value,
            ),
          ],
        ),
      ),
    );
  }
}
