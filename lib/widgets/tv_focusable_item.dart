import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';

/// Item navegável por controle remoto (D-pad).
/// No foco: escala 1.06 + borda brilhante + glow (sombras suaves).
/// Suporta clique curto (ação) e longo (favoritar).
/// Performance: sem blur, apenas transform + sombra — 60fps em TV boxes antigas.
class TVFocusableItem extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final FocusNode? focusNode;
  final bool autofocus;
  final double borderRadius;
  final Color focusColor;
  final double focusScale;

  const TVFocusableItem({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.focusNode,
    this.autofocus = false,
    this.borderRadius = 8,
    this.focusColor = AppTheme.accent,
    this.focusScale = 1.06,
  });

  @override
  State<TVFocusableItem> createState() => _TVFocusableItemState();
}

class _TVFocusableItemState extends State<TVFocusableItem> {
  bool _focused = false;
  late FocusNode _node;

  @override
  void initState() {
    super.initState();
    _node = widget.focusNode ?? FocusNode();
    _node.addListener(_onFocus);
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    if (widget.focusNode == null) _node.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (mounted) setState(() => _focused = _node.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _focused ? widget.focusScale : 1.0;
    return Focus(
      focusNode: _node,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          if (widget.onTap != null) widget.onTap!();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.diagonal3Values(scale, scale, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _focused ? widget.focusColor : Colors.transparent,
              width: _focused ? 3 : 0,
            ),
            boxShadow: _focused
                ? [
                    // Sombra preta de elevação (profundidade) + glow colorido.
                    const BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 28,
                      offset: Offset(0, 10),
                    ),
                    ...AppTheme.focusGlow(widget.focusColor),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
