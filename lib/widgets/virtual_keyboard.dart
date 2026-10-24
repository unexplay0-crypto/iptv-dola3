import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';
import '../core/device_config.dart';
import 'tv_focusable_item.dart';

/// Teclado virtual QWERTY do próprio app (estilo Gboard), em painel de vidro.
///
/// - Linha de números em cima (1 2 3 ... 0).
/// - QWERTY / ASDFG / ZXCVBNM com Shift (maiúsculas).
/// - Barra de espaço larga e botão de apagar (⌫) como no Gboard.
/// - Tecla de atalho que insere "http://" de uma vez.
/// - Tecla de ponto (.).
/// - Tecla Enter (confirma) e tecla de fechar (✕).
/// - Todas as teclas são navegáveis por D-pad (TVFocusableItem).
class VirtualKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onSubmit;
  final VoidCallback? onClose;
  final bool obscureText;

  const VirtualKeyboard({
    super.key,
    required this.controller,
    this.onSubmit,
    this.onClose,
    this.obscureText = false,
  });

  @override
  State<VirtualKeyboard> createState() => _VirtualKeyboardState();
}

class _VirtualKeyboardState extends State<VirtualKeyboard> {
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
    return GlassContainer(
      borderRadius: AppTheme.radiusLg,
      opacity: 0.12,
      blur: 20,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row(_rowNumbers.map((k) => _key(k, _c(k))).toList()),
          const SizedBox(height: 8),
          _row(_rowQ.map((k) => _key(k, _c(k))).toList()),
          const SizedBox(height: 8),
          _row(_rowA.map((k) => _key(k, _c(k))).toList()),
          const SizedBox(height: 8),
          _row([
            _specialKey(
              flex: 2,
              label: _shift ? "⇧" : "⇧",
              active: _shift,
              onTap: () => setState(() => _shift = !_shift),
            ),
            ..._rowZ.map((k) => _key(k, _c(k))),
            _specialKey(
              flex: 2,
              label: "⌫",
              onTap: _backspace,
              onLongPress: _backspace,
            ),
          ]),
          const SizedBox(height: 8),
          _row([
            _specialKey(
                flex: 3, label: "http://", onTap: () => _insert("http://")),
            _specialKey(flex: 1, label: ".", onTap: () => _insert(".")),
            _specialKey(flex: 5, label: "espaço", onTap: () => _insert(" ")),
            _specialKey(flex: 1, label: "@", onTap: () => _insert("@")),
            _specialKey(flex: 2, label: "✓", onTap: widget.onSubmit ?? () {}),
            _specialKey(
                flex: 2,
                label: "✕",
                onTap: widget.onClose ?? () => Navigator.of(context).pop()),
          ]),
        ],
      ),
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

  Widget _key(String raw, String display) {
    return _FlexKey(
      flex: 1,
      child: TVFocusableItem(
        borderRadius: 10,
        focusScale: 1.08,
        onTap: () => _insert(raw),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Text(display,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _specialKey({
    required int flex,
    required String label,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    bool active = false,
  }) {
    return _FlexKey(
      flex: flex,
      child: TVFocusableItem(
        borderRadius: 10,
        focusScale: 1.06,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.accent.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: active
                    ? AppTheme.accent
                    : Colors.white.withValues(alpha: 0.14)),
          ),
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: active ? Colors.white : Colors.white70,
                  fontSize: label.length > 3 ? 12 : 16,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

/// Campo de entrada ADAPTATIVO:
///  - Na TV: usa [GlassInputField] (somente leitura) + o pai abre o
///    [VirtualKeyboard] do app (TV não tem teclado físico/touch).
///  - No celular: TextField editável normal — abre o teclado NATURAL do
///    celular, sem o teclado virtual do app.
///
/// A escolha é automática via [DeviceConfig] — sem configuração do usuário.
class AdaptiveInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final bool active;
  final VoidCallback onSelect;
  final TextInputType? keyboardType;
  final int? maxLines;
  const AdaptiveInputField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    required this.active,
    required this.onSelect,
    this.keyboardType,
    this.maxLines = 1,
  });

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
        onSelect: onSelect,
        keyboardType: keyboardType,
        maxLines: maxLines,
      );
    }
    // Modo celular: campo editável com teclado do sistema.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
            color: active ? AppTheme.accent : AppTheme.glassBorder,
            width: active ? 1.5 : 1),
        boxShadow: active
            ? [
                BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.25),
                    blurRadius: 12)
              ]
            : null,
      ),
      child: TextField(
        controller: controller,
        autofocus: active,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
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

/// Wrapper que carrega flex para o Expanded da linha.
class _FlexKey extends StatelessWidget {
  final int flex;
  final Widget child;
  const _FlexKey({required this.flex, required this.child});
  @override
  Widget build(BuildContext context) => child;
}

/// Campo de texto em painel de vidro, SOMENTE LEITURA (não abre teclado do
/// sistema). Ao ser tocado/focado, notifica o pai para abrir o teclado virtual
/// do app com este [controller].
class GlassInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final bool active;
  final VoidCallback onSelect;
  final TextInputType? keyboardType;
  final int? maxLines;

  const GlassInputField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    required this.active,
    required this.onSelect,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TVFocusableItem(
      borderRadius: AppTheme.radiusMd,
      focusScale: 1.02,
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
              color: active ? AppTheme.accent : AppTheme.glassBorder,
              width: active ? 1.5 : 1),
          boxShadow: active
              ? [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.25), blurRadius: 12)]
              : null,
        ),
        child: TextField(
          controller: controller,
          readOnly: true, // nunca abre teclado do sistema
          showCursor: true,
          onTap: onSelect, // toque no campo também abre o teclado virtual
          obscureText: obscureText,
          maxLines: maxLines,
          style: const TextStyle(
              color: AppTheme.textPrimary, fontSize: 15, height: 1.4),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
                color: active ? AppTheme.accent : AppTheme.textSecondary,
                fontSize: 13),
            hintText: hint,
            hintStyle:
                const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            suffixIcon: active
                ? const Icon(Icons.keyboard_rounded,
                    color: AppTheme.accent, size: 20)
                : null,
          ),
        ),
      ),
    );
  }
}
