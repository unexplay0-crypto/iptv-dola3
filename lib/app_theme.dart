import 'dart:ui';
import 'package:flutter/material.dart';

/// Sistema de design "Liquid Glass" do UNEX PLAY (2026).
///
/// Inspirado nas referências de mercado: tvOS / visionOS (Apple), MIUI Glass
/// (Xiaomi), One UI (Samsung), Material Design 3 e Windows 11 Mica.
/// Princípios do documento de diretrizes:
///  - Fundo profundo quase-preto com blobs de cor ambiente suaves (profundidade).
///  - Superfícies de vidro fosco: blur real (BackdropFilter) + preenchimento
///    translúcido + borda clara de 1px + brilho especular no topo.
///  - Blur aplicado SELETIVAMENTE (sidebar, painéis, OSD, diálogos) — nunca em
///    cards que rolam, para manter 60fps em TV boxes antigos. RepaintBoundary
///    em cada painel de vidro isola o custo de repaint.
///  - Cantos arredondados generosos, sombras suaves, foco de TV com escala +
///    borda luminosa + glow.
///  - Tipografia grande e contrastante (leitura a 3–5m).
class AppTheme {
  // ===== Cores base =====
  static const Color background = Color(0xFF05070D); // preto profundo
  static const Color backgroundDeep = Color(0xFF020308);
  static const Color surface = Color(0xFF121826);
  static const Color surfaceHighlight = Color(0xFF1B2333);
  static const Color accent = Color(0xFF00E5FF);
  static const Color accentDim = Color(0xFF0088A3);
  static const Color accentDeep = Color(0xFF003B46);
  static const Color gold = Color(0xFFFFD54F);
  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFF9AA5B8);
  static const Color textMuted = Color(0xFF5F6B80);
  static const Color danger = Color(0xFFFF4D6D);
  static const Color success = Color(0xFF2ED573);
  static const Color skeleton = Color(0xFF141A26);
  static const Color skeletonShimmer = Color(0xFF222B3D);

  // ===== Superfície de vidro (frosted / liquid glass) =====
  static const Color glassSurface = Color(0x22FFFFFF); // 13% de opacidade
  static const Color glassSurfaceStrong = Color(0x33FFFFFF); // 20%
  static const Color glassBorder = Color(0x33FFFFFF); // borda 20%
  static const Color glassHighlight = Color(0x66FFFFFF); // brilho topo
  static const double glassBlur = 24.0; // sigma do blur (tvOS ~20-30)

  // ===== Gradientes =====
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF0099CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Brilho especular no topo de painéis de vidro (simula reflexo de luz).
  static const LinearGradient glassSpecular = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x33FFFFFF), Color(0x06FFFFFF), Color(0x00FFFFFF)],
    stops: [0.0, 0.25, 0.6],
  );

  // Refração de borda de vidro polido arredondado: luz mais forte no canto
  // superior-esquerdo, desaparece no meio, e um leve ciano (cor ambiente)
  // refrata no canto inferior-direito — como um bloco de vidro real sob luz.
  static const LinearGradient glassRefractionBorder = LinearGradient(
    begin: Alignment(-1.0, -1.0),
    end: Alignment(1.0, 1.0),
    colors: [
      Color(0x88FFFFFF), // brilho de borda topo-esquerda
      Color(0x1AFFFFFF),
      Color(0x00FFFFFF),
      Color(0x1400E5FF), // ciano ambiente refratado na base-direita
      Color(0x3D00E5FF),
    ],
    stops: [0.0, 0.18, 0.45, 0.8, 1.0],
  );

  // Refração INTERNA sutil (simula a distorção de luz através do vidro):
  // um gradiente radial claro no canto superior-esquerdo, sobreposto ao blur.
  static const RadialGradient glassInnerRefraction = RadialGradient(
    center: Alignment(-0.8, -0.9),
    radius: 1.1,
    colors: [Color(0x1FFFFFFF), Color(0x00FFFFFF)],
    stops: [0.0, 0.6],
  );

  // Sombra ambiente dos painéis de vidro: preta + leve halo ciano (refração).
  static const List<BoxShadow> glassShadowRefraction = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 30,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color(0x1400E5FF),
      blurRadius: 40,
      spreadRadius: -4,
      offset: Offset(0, 6),
    ),
  ];

  // Fundo ambiente: blob de cor suave (ciano-índigo) sobre preto, estilo visionOS.
  static const RadialGradient ambientGradient = RadialGradient(
    center: Alignment(0.8, -0.6),
    radius: 1.4,
    colors: [Color(0xFF16283D), Color(0xFF0A1020), background],
    stops: [0.0, 0.45, 1.0],
  );

  // Segundo blob (canto inferior esquerdo, roxo suave) — sobreposto ao primeiro.
  static const RadialGradient ambientGradient2 = RadialGradient(
    center: Alignment(-0.9, 0.9),
    radius: 1.2,
    colors: [Color(0xFF1A1430), Color(0x0005070D)],
    stops: [0.0, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xE005070D)],
    stops: [0.35, 1.0],
  );

  static const LinearGradient focusGlowGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF7DF9FF), Color(0xFF0099CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===== Raios de borda =====
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 28;
  static const double radiusPoster = 18;
  static const double radiusChannel = 14;

  static const double overscan = 24;

  // ===== Sombras =====
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static List<BoxShadow> focusGlow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.45),
          blurRadius: 24,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: color.withOpacity(0.18),
          blurRadius: 56,
          spreadRadius: 8,
        ),
      ];

  static const List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Color(0x55000000),
      blurRadius: 30,
      offset: Offset(0, 12),
    ),
  ];

  // ===== Tipografia (10-foot UI) =====
  static const TextStyle titleH1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: textPrimary,
    letterSpacing: -0.3,
    height: 1.1,
  );
  static const TextStyle titleH2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.2,
  );
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.1,
  );
  static const TextStyle body = TextStyle(fontSize: 14, color: textPrimary);
  static const TextStyle caption =
      TextStyle(fontSize: 12, color: textSecondary);
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
        titleLarge:
            TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textPrimary),
        labelLarge: TextStyle(color: textPrimary),
      ),
      focusColor: accent,
      highlightColor: accent.withOpacity(0.2),
      splashColor: accent.withOpacity(0.15),
      dividerColor: Colors.white10,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textPrimary,
      ),
    );
  }

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
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.55), width: 1),
      ),
      child: Text(q, style: badge.copyWith(color: color, fontSize: 9)),
    );
  }

  static Widget liveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: danger.withOpacity(0.2),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: danger.withOpacity(0.6), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: const [
        _LiveDot(),
        SizedBox(width: 4),
        Text("AO VIVO",
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: danger,
                letterSpacing: 0.5)),
      ]),
    );
  }
}

/// Fundo ambiente com dois blobs de cor suaves (estilo visionOS / Apple TV).
class AmbientBackground extends StatelessWidget {
  final Widget child;
  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppTheme.background),
      child: Stack(
        children: [
          const Positioned.fill(
              child: DecoratedBox(
                  decoration: BoxDecoration(gradient: AppTheme.ambientGradient))),
          const Positioned.fill(
              child: DecoratedBox(
                  decoration:
                      BoxDecoration(gradient: AppTheme.ambientGradient2))),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// Painel de vidro fosco (liquid glass) com blur real.
///
/// Performance: envolto em RepaintBoundary para isolar o custo do blur.
/// Usar apenas em painéis fixos (sidebar, topbar, diálogos, OSD) — NÃO em
/// itens de lista que rolam.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final double opacity; // 0..1 de branco
  final bool showSpecular;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = AppTheme.radiusLg,
    this.blur = AppTheme.glassBlur,
    this.opacity = 0.10,
    this.showSpecular = true,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(borderRadius);
    // Borda interna ligeiramente menor para a borda de refração (1.5px).
    final innerR = BorderRadius.circular(borderRadius - 1.5);
    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        margin: margin,
        // Camada 0 (mais externa): sombra + borda de refração de vidro polido.
        // O gradiente na decoração simula luz refratada nas bordas
        // arredondadas (brilho topo-esquerda, ciano ambiente base-direita).
        decoration: BoxDecoration(
          borderRadius: r,
          gradient: border == null ? AppTheme.glassRefractionBorder : null,
          boxShadow: boxShadow ?? AppTheme.glassShadowRefraction,
        ),
        padding: border == null ? const EdgeInsets.all(1.5) : EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: border == null ? innerR : r,
          clipBehavior: Clip.antiAlias,
          // Camada 1: vidro FOSCO (blur real do fundo).
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(opacity),
                borderRadius: border == null ? innerR : r,
                border: border,
              ),
              child: Stack(
                children: [
                  // Camada 2: refração interna sutil (distorção de luz).
                  if (showSpecular)
                    const Positioned.fill(
                      child: DecoratedBox(
                          decoration:
                              BoxDecoration(gradient: AppTheme.glassInnerRefraction)),
                    ),
                  // Camada 3: brilho especular no topo (reflexo polido).
                  if (showSpecular)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: border == null ? innerR : r,
                          gradient: AppTheme.glassSpecular,
                        ),
                      ),
                    ),
                  // child NÃO posicionado: define o tamanho do Stack.
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
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
              color: AppTheme.danger.withOpacity(0.3 + 0.7 * _ctrl.value),
              blurRadius: 6,
              spreadRadius: 1 + 2 * _ctrl.value,
            ),
          ],
        ),
      ),
    );
  }
}
