import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';
import '../core/device_config.dart';
import 'tv_focusable_item.dart';

/// Teclado QWERTY puro (sem contêiner), reaproveitável dentro de um diálogo
/// estilo Fire TV ou embutido no layout. Estilo Gboard: fileira de números,
/// três fileiras de letras com Shift, espaço largo, apagar, atalhos.
class QwertyKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onSubmit;
  final VoidCallback? onClose;
  final bool obscureText;
  final double keyHeight;
  final double fontSize;

  const QwertyKeyboard({
    super.key,
    required this.controller,
    this.onSubmit,
    this.onClose,
    this.obscureText = false,
    this.keyHeight = 52,
    this.fontSize = 18,
  });

  @override
  State<QwertyKeyboard> createState() => _QwertyKeyboardState();
}

class _QwertyKeyboardState extends State<QwertyKeyboard> {
  bool _shift = false;
  static const _rowNumbers = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"];
  static const _rowQ = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"];
  static const _rowA = ["a", "s", "d", "f", "g", "h", "j", "k", "l"];
  static const _rowZ = ["z", "x", "c", "v", "b", "n", "m"];

  String _c(String s) => _shift ? s.toUpperCase() : s;

  void _insert(String s) {
    final text = widget.controller.text;
    final sel = widget.controller.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final newText = text.replaceRange(start, end, s);
    widget.controller.text = newText;
    widget.controller.selection =
        TextSelection.collapsed(offset: start + s.length);
    if (_shift) setState(() => _shift = false);
  }

  void _backspace() {
    final text = widget.controller.text;
    if (text.isEmpty) return;
    final sel = widget.controller.selection;
    final start = sel.isValid ? sel.start : text.length;
    if (start <= 0) return;
    final newText = text.replaceRange(start - 1, start, "");
    widget.controller.text = newText;
    widget.controller.selection = TextSelection.collapsed(offset: start - 1);
  }

  @override
  Widget build(BuildContext context) {
    final kh = widget.keyHeight;
    final fs = widget.fontSize;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row(_rowNumbers.map((k) => _key(k, _c(k), kh, fs)).toList()),
        const SizedBox(height: 8),
        _row(_rowQ.map((k) => _key(k, _c(k), kh, fs)).toList()),
        const SizedBox(height: 8),
        _row(_rowA.map((k) => _key(k, _c(k), kh, fs)).toList()),
        const SizedBox(height: 8),
        _row([
          _specialKey(
            flex: 2,
            label: "⇧",
            active: _shift,
            height: kh,
            onTap: () => setState(() => _shift = !_shift),
          ),
          ..._rowZ.map((k) => _key(k, _c(k), kh, fs)),
          _specialKey(
            flex: 2,
            label: "⌫",
            height: kh,
            onTap: _backspace,
            onLongPress: _backspace,
          ),
        ]),
        const SizedBox(height: 8),
        _row([
          _specialKey(
              flex: 3, label: "http://", height: kh, onTap: () => _insert("http://")),
          _specialKey(flex: 1, label: ".", height: kh, onTap: () => _insert(".")),
          _specialKey(flex: 1, label: "@", height: kh, onTap: () => _insert("@")),
          _specialKey(flex: 4, label: "espaço", height: kh, onTap: () => _insert(" ")),
          _specialKey(
              flex: 2,
              label: "✓",
              height: kh,
              accent: true,
              onTap: widget.onSubmit ?? () {}),
          _specialKey(
              flex: 2,
              label: "✕",
              height: kh,
              onTap: widget.onClose ?? () => Navigator.of(context).pop()),
        ]),
      ],
    );
  }

  Widget _row(List<Widget> keys) {
    return Row(
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(flex: keys[i] is _FlexKey ? (keys[i] as _FlexKey).flex : 1, child: keys[i]),
        ],
      ],
    );
  }

  Widget _key(String raw, String display, double h, double fs) {
    return _FlexKey(
      flex: 1,
      child: TVFocusableItem(
        borderRadius: 10,
        focusScale: 1.08,
        onTap: () => _insert(raw),
        child: Container(
          height: h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: Text(display,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: fs,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _specialKey({
    required int flex,
    required String label,
    required VoidCallback onTap,
    required double height,
    VoidCallback? onLongPress,
    bool active = false,
    bool accent = false,
  }) {
    return _FlexKey(
      flex: flex,
      child: TVFocusableItem(
        borderRadius: 10,
        focusScale: 1.06,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          height: height,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: accent
                ? AppTheme.accent.withOpacity(0.85)
                : active
                    ? AppTheme.accent.withOpacity(0.35)
                    : Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: accent
                    ? AppTheme.accent
                    : active
                        ? AppTheme.accent
                        : Colors.white.withOpacity(0.14)),
          ),
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: accent ? Colors.black : active ? Colors.white : Colors.white70,
                  fontSize: label.length > 3 ? 12 : 16,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

/// Wrapper que carrega flex para o Expanded da linha.
class _FlexKey extends StatelessWidget {
  final int flex;
  final Widget child;
  const _FlexKey({required this.flex, required this.child});
  @override
  Widget build(BuildContext context) => child;
}

// ============================================================================
//  DIÁLOGO DE TECLADO ESTILO FIRE TV / GOOGLE TV
//  Ao selecionar um campo de texto, abre uma JANELA centralizada com:
//   - preview do texto sendo digitado (com cursor piscante) no topo
//   - teclado QWERTY completo abaixo
//  Nunca toca no IME do sistema — 100% controle do app.
// ============================================================================
class TvKeyboardDialog extends StatefulWidget {
  final String initialText;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;

  const TvKeyboardDialog({
    super.key,
    this.initialText = "",
    this.label = "Digite o texto",
    this.hint,
    this.obscureText = false,
    this.keyboardType,
  });

  /// Abre o diálogo e retorna o texto final (ou null se cancelado).
  static Future<String?> show(
    BuildContext context, {
    String initialText = "",
    String label = "Digite o texto",
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TvKeyboardDialog(
        initialText: initialText,
        label: label,
        hint: hint,
        obscureText: obscureText,
        keyboardType: keyboardType,
      ),
    );
  }

  @override
  State<TvKeyboardDialog> createState() => _TvKeyboardDialogState();
}

class _TvKeyboardDialogState extends State<TvKeyboardDialog>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _ctrl;
  late final AnimationController _cursorAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialText);
    _cursorAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 530))
      ..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _cursorAnim.dispose();
    super.dispose();
  }

  String get _displayText =>
      widget.obscureText ? "•" * _ctrl.text.length : _ctrl.text;

  @override
  Widget build(BuildContext context) {
    final isPhone = DeviceConfig.of(context).isPhone;
    final dialogWidth = isPhone ? double.infinity : 680.0;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
          horizontal: isPhone ? 12 : 40, vertical: 24),
      child: Container(
        width: dialogWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A2233), Color(0xFF0B0F18)],
          ),
          border: Border.all(color: AppTheme.glassBorder),
          boxShadow: [
            const BoxShadow(
                color: Colors.black54, blurRadius: 40, offset: Offset(0, 20)),
            BoxShadow(
                color: AppTheme.accent.withOpacity(0.12),
                blurRadius: 60,
                spreadRadius: -10),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.keyboard_rounded,
                        color: Colors.black, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.label,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                  ),
                  TVFocusableItem(
                    borderRadius: 10,
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Icon(Icons.close,
                          color: AppTheme.textSecondary, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ÁREA DE PREVIEW DO TEXTO (estilo Fire TV) — campo com
              // cursor piscante, mostra exatamente o que está sendo digitado.
              AnimatedBuilder(
                animation: _cursorAnim,
                builder: (context, _) {
                  final showCursor = _cursorAnim.value > 0.5;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.accent, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: AppTheme.accent.withOpacity(0.2),
                            blurRadius: 16)
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            reverse: true,
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  if (_displayText.isEmpty &&
                                      widget.hint != null)
                                    TextSpan(
                                        text: widget.hint,
                                        style: const TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 18)),
                                  if (_displayText.isNotEmpty)
                                    TextSpan(
                                        text: _displayText,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5)),
                                  WidgetSpan(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 2),
                                      child: AnimatedOpacity(
                                        duration:
                                            const Duration(milliseconds: 100),
                                        opacity: showCursor ? 1.0 : 0.0,
                                        child: Container(
                                          width: 2.5,
                                          height: 24,
                                          color: AppTheme.accent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_ctrl.text.isNotEmpty)
                          TVFocusableItem(
                            borderRadius: 8,
                            onTap: () {
                              _ctrl.clear();
                              setState(() {});
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.clear,
                                  color: AppTheme.textSecondary, size: 18),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text("${_ctrl.text.length} caracteres",
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)),
              ),
              const SizedBox(height: 14),
              QwertyKeyboard(
                controller: _ctrl,
                obscureText: widget.obscureText,
                keyHeight: isPhone ? 46 : 52,
                fontSize: isPhone ? 16 : 18,
                onSubmit: () => Navigator.of(context).pop(_ctrl.text.trim()),
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  "Use o controle remoto para navegar • OK para selecionar",
                  style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      letterSpacing: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
//  Campos adaptativos: na TV abrem o diálogo de teclado do app; no celular
//  usam TextField nativo com o IME do sistema.
// ============================================================================

class AdaptiveInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final bool active;
  final VoidCallback? onSelect;
  final TextInputType? keyboardType;
  final int? maxLines;
  final ValueChanged<String>? onChanged;

  const AdaptiveInputField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.active = false,
    this.onSelect,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
  });

  Future<void> _openKeyboard(BuildContext context) async {
    onSelect?.call();
    final result = await TvKeyboardDialog.show(
      context,
      initialText: controller.text,
      label: label,
      hint: hint,
      obscureText: obscureText,
      keyboardType: keyboardType,
    );
    if (result != null) {
      controller.text = result;
      onChanged?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTv = DeviceConfig.of(context).isTv;
    if (isTv) {
      return GlassInputField(
        controller: controller,
        label: label,
        hint: hint,
        obscureText: obscureText,
        active: active,
        onSelect: () => _openKeyboard(context),
        maxLines: maxLines,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? Colors.white.withOpacity(0.14)
            : Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
            color: active ? AppTheme.accent : AppTheme.glassBorder,
            width: active ? 1.5 : 1),
        boxShadow: active
            ? [
                BoxShadow(
                    color: AppTheme.accent.withOpacity(0.25), blurRadius: 12)
              ]
            : null,
      ),
      child: TextField(
        controller: controller,
        autofocus: active,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        style: const TextStyle(
            color: AppTheme.textPrimary, fontSize: 15, height: 1.4),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: active ? AppTheme.accent : AppTheme.textSecondary,
              fontSize: 13),
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class AdaptiveSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final bool showClear;

  const AdaptiveSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.onClear,
    this.showClear = false,
  });

  Future<void> _openKeyboard(BuildContext context) async {
    final result = await TvKeyboardDialog.show(
      context,
      initialText: controller.text,
      label: "Buscar",
      hint: hint,
    );
    if (result != null) {
      controller.text = result;
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTv = DeviceConfig.of(context).isTv;
    return TextField(
      controller: controller,
      readOnly: isTv,
      showCursor: isTv,
      onTap: isTv ? () => _openKeyboard(context) : null,
      onChanged: onChanged,
      style: const TextStyle(
          color: AppTheme.textPrimary, fontSize: 14, height: 1.3),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppTheme.textMuted, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
        suffixIcon: showClear
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 18),
                onPressed: onClear,
              )
            : (isTv
                ? const Icon(Icons.keyboard_rounded,
                    color: AppTheme.accent, size: 18)
                : null),
        filled: true,
        fillColor: AppTheme.surface.withOpacity(0.8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: const BorderSide(color: AppTheme.accent, width: 1.5)),
      ),
    );
  }
}

class GlassInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final bool active;
  final VoidCallback onSelect;
  final int? maxLines;

  const GlassInputField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.active = false,
    required this.onSelect,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final display = obscureText && controller.text.isNotEmpty
        ? "•" * controller.text.length
        : controller.text;
    return TVFocusableItem(
      borderRadius: AppTheme.radiusMd,
      focusScale: 1.02,
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withOpacity(0.14)
              : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
              color: active ? AppTheme.accent : AppTheme.glassBorder,
              width: active ? 1.5 : 1),
          boxShadow: active
              ? [BoxShadow(color: AppTheme.accent.withOpacity(0.25), blurRadius: 12)]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Text(label,
                      style: TextStyle(
                          color:
                              active ? AppTheme.accent : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    display.isEmpty ? (hint ?? "") : display,
                    maxLines: maxLines ?? 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: display.isEmpty
                            ? AppTheme.textMuted
                            : AppTheme.textPrimary,
                        fontSize: 15,
                        height: 1.4),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Icon(
              active ? Icons.keyboard_rounded : Icons.keyboard_arrow_up_rounded,
              color: active ? AppTheme.accent : AppTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
