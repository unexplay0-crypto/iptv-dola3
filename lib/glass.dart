import 'dart:ui';
import 'package:flutter/material.dart';

// =============================================================================
//  GLASS VISION — Liquid Glass Design System
//  Inspirado no Liquid Glass da Apple (WWDC25), glassmorphism e efeitos de
//  refracao em tempo real. Superficies translucidas com blur de fundo,
//  bordas especulares, brilho interno e profundidade em camadas.
// =============================================================================

class GlassColors {
  static const Color accentCyan = Color(0xFF4DE8FF);
  static const Color accentViolet = Color(0xFFB388FF);
  static const Color accentRose = Color(0xFFFF8FB1);
  static const Color accentAmber = Color(0xFFFFD18F);

  // Tons de fundo profundo (base da aurora)
  static const Color spaceDeep = Color(0xFF05060F);
  static const Color spaceNavy = Color(0xFF0A1030);
  static const Color spaceViolet = Color(0xFF1A0B33);

  // Preenchimentos de vidro (translucidos)
  static Color glassFill({double strength = 0.10}) => Colors.white.withOpacity(strength);
  static Color glassFillStrong({double strength = 0.16}) => Colors.white.withOpacity(strength);
  static Color glassBorder({double strength = 0.22}) => Colors.white.withOpacity(strength);
  static Color glassHighlight = Colors.white.withOpacity(0.30);
  static Color glassShadow = Colors.black.withOpacity(0.35);

  // Gradiente de borda especular (topo brilhante, base subtil)
  static const LinearGradient specularGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x66FFFFFF), Color(0x11FFFFFF), Color(0x33FFFFFF)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentCyan, accentViolet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient auroraBlob1 =
      LinearGradient(colors: [Color(0x664DE8FF), Color(0x004DE8FF)]);
  static const LinearGradient auroraBlob2 =
      LinearGradient(colors: [Color(0x55B388FF), Color(0x00B388FF)]);
  static const LinearGradient auroraBlob3 =
      LinearGradient(colors: [Color(0x44FF8FB1), Color(0x00FF8FB1)]);
}

// -----------------------------------------------------------------------------
//  Superficie de vidro reutilizavel — o bloco basico do design
// -----------------------------------------------------------------------------
class GlassSurface extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderOpacity;
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradientOverlay;
  final bool highlightTop;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  const GlassSurface({
    super.key,
    required this.child,
    this.blur = 22.0,
    this.opacity = 0.10,
    this.borderOpacity = 0.22,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding,
    this.margin,
    this.gradientOverlay,
    this.highlightTop = true,
    this.width,
    this.height,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius.resolve(Directionality.maybeOf(context) ?? TextDirection.ltr),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            alignment: alignment,
            padding: padding,
            decoration: BoxDecoration(
              gradient: gradientOverlay ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(opacity + 0.04),
                      Colors.white.withOpacity(opacity * 0.6),
                    ],
                  ),
              border: Border.all(
                color: Colors.white.withOpacity(borderOpacity),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                if (highlightTop)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 1.2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.55),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  Botao de vidro com resposta fluida (escala + brilho no foco/toque)
// -----------------------------------------------------------------------------
class GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final bool accent;
  final IconData? icon;
  final FocusNode? focusNode;
  final bool autofocus;

  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.width,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.accent = false,
    this.icon,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final active = _hover || _focus;
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (f) => setState(() => _focus = f),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: active ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: widget.width,
              height: widget.height,
              padding: widget.padding,
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                gradient: widget.accent
                    ? LinearGradient(
                        colors: active
                            ? [GlassColors.accentCyan, GlassColors.accentViolet]
                            : [GlassColors.accentCyan.withOpacity(0.85), GlassColors.accentViolet.withOpacity(0.85)],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withOpacity(active ? 0.22 : 0.12),
                          Colors.white.withOpacity(active ? 0.14 : 0.06),
                        ],
                      ),
                border: Border.all(
                  color: active
                      ? (widget.accent ? Colors.white.withOpacity(0.7) : GlassColors.accentCyan.withOpacity(0.8))
                      : Colors.white.withOpacity(0.2),
                  width: active ? 1.4 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.accent ? GlassColors.accentCyan : Colors.white).withOpacity(active ? 0.35 : 0.12),
                    blurRadius: active ? 28 : 12,
                    spreadRadius: active ? 1.5 : 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: widget.borderRadius.resolve(TextDirection.ltr),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: active ? 26 : 18, sigmaY: active ? 26 : 18),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon,
                            color: widget.accent ? Colors.white : (active ? GlassColors.accentCyan : Colors.white70),
                            size: 20),
                        const SizedBox(width: 8),
                      ],
                      DefaultTextStyle(
                        style: TextStyle(
                          color: widget.accent ? const Color(0xFF06122A) : (active ? Colors.white : Colors.white70),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                        child: widget.child,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  Campo de entrada de vidro
// -----------------------------------------------------------------------------
class GlassTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final bool obscure;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final double? height;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.obscure = false,
    this.autofocus = false,
    this.focusNode,
    this.keyboardType,
    this.onSubmitted,
    this.height,
  });

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  bool _focus = false;
  late final FocusNode _node;

  @override
  void initState() {
    super.initState();
    _node = widget.focusNode ?? FocusNode();
    _node.addListener(() => setState(() => _focus = _node.hasFocus));
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      height: widget.height ?? 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.black.withOpacity(_focus ? 0.35 : 0.22),
        border: Border.all(
          color: _focus ? GlassColors.accentCyan.withOpacity(0.85) : Colors.white.withOpacity(0.18),
          width: _focus ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: GlassColors.accentCyan.withOpacity(_focus ? 0.25 : 0.0),
            blurRadius: 20,
            spreadRadius: _focus ? 1 : 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Center(
            child: TextField(
              controller: widget.controller,
              focusNode: _node,
              autofocus: widget.autofocus,
              obscureText: widget.obscure,
              keyboardType: widget.keyboardType,
              onSubmitted: widget.onSubmitted,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
              cursorColor: GlassColors.accentCyan,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                prefixIcon: widget.icon != null
                    ? Icon(widget.icon, color: _focus ? GlassColors.accentCyan : Colors.white38, size: 20)
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  Fundo Aurora animado — manchas de cor fluidas que derivam lentamente,
//  criando a base colorida que o vidro refrata.
// -----------------------------------------------------------------------------
class AuroraBackground extends StatefulWidget {
  final Widget child;
  const AuroraBackground({super.key, required this.child});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 24))..repeat(reverse: true);
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
      builder: (context, _) {
        final t = _ctrl.value;
        return Stack(
          children: [
            // Base profunda
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [GlassColors.spaceDeep, GlassColors.spaceNavy, GlassColors.spaceViolet],
                ),
              ),
            ),
            // Blob 1 — ciano (superior esquerdo, deriva para direita)
            Positioned(
              top: -120 + t * 60,
              left: -100 + t * 140,
              child: _blob(380, GlassColors.auroraBlob1),
            ),
            // Blob 2 — violeta (inferior direito)
            Positioned(
              bottom: -140 - t * 50,
              right: -120 + t * 100,
              child: _blob(440, GlassColors.auroraBlob2),
            ),
            // Blob 3 — rosa (centro, pulso)
            Positioned(
              top: 200 + (1 - t) * 80,
              right: 80 + t * 60,
              child: Opacity(opacity: 0.7, child: _blob(300, GlassColors.auroraBlob3)),
            ),
            // Camada de granulado sutil (ruido) para profundidade
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.18)),
            ),
            Positioned.fill(child: widget.child),
          ],
        );
      },
    );
  }

  Widget _blob(double size, Gradient gradient) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: [
          BoxShadow(color: Colors.white.withOpacity(0.05), blurRadius: 120, spreadRadius: 40),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  Chip / Badge de vidro
// -----------------------------------------------------------------------------
class GlassChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool accent;
  final Color? color;
  const GlassChip({super.key, required this.label, this.icon, this.accent = false, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? (accent ? GlassColors.accentCyan : Colors.white);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: c.withOpacity(accent ? 0.20 : 0.10),
        border: Border.all(color: c.withOpacity(0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: c), const SizedBox(width: 4)],
          Text(label, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  Titulo com gradiente accent
// -----------------------------------------------------------------------------
class GradientText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  const GradientText(this.text, {super.key, this.fontSize = 28, this.fontWeight = FontWeight.w700});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => GlassColors.accentGradient.createShader(bounds),
      child: Text(
        text,
        style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: Colors.white, letterSpacing: -0.3),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  Dialog de vidro (usado como wrapper em showDialog)
// -----------------------------------------------------------------------------
class GlassDialog extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const GlassDialog({super.key, required this.child, this.padding = const EdgeInsets.all(24)});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassSurface(
        opacity: 0.14,
        borderOpacity: 0.28,
        blur: 30,
        borderRadius: BorderRadius.circular(28),
        padding: padding,
        child: child,
      ),
    );
  }
}

// Helpers de tema
ThemeData buildGlassTheme() {
  final base = ThemeData.dark();
  return base.copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    primaryColor: GlassColors.accentCyan,
    colorScheme: const ColorScheme.dark(
      primary: GlassColors.accentCyan,
      secondary: GlassColors.accentViolet,
      surface: Colors.transparent,
      error: Color(0xFFFF6B81),
    ),
    dialogBackgroundColor: Colors.transparent,
    textTheme: base.textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
      fontFamily: 'Roboto',
    ),
  );
}
