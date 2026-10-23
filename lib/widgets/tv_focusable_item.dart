import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';

/// Item navegável por controle remoto: destaca foco com borda colorida
/// e escala. Suporta clique curto (ação) e longo (favoritar).
class TVFocusableItem extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final FocusNode? focusNode;
  final bool autofocus;
  final double borderRadius;

  const TVFocusableItem({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.focusNode,
    this.autofocus = false,
    this.borderRadius = 8,
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
    return Focus(
      focusNode: _node,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey.keyLabel == "Select" ||
                event.logicalKey.keyLabel == "Enter")) {
          if (widget.onTap != null) widget.onTap!();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.diagonal3Values(_focused ? 1.06 : 1.0, _focused ? 1.06 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _focused ? AppTheme.accent : Colors.transparent,
              width: _focused ? 3 : 0,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.35),
                      blurRadius: 18,
                      spreadRadius: 2,
                    )
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
