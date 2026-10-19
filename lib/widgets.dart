import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core.dart';
import 'glass.dart';

// =============================================================================
//  WIDGETS REUTILIZAVEIS — versao Liquid Glass
//  Assinaturas identicas ao original para compatibilidade total com as telas.
// =============================================================================

// -----------------------------------------------------------------------------
//  1. Item focavel para TV (D-pad) — com brilho de vidro e escala no foco
// -----------------------------------------------------------------------------
class TVFocusableItem extends StatefulWidget {
  final VoidCallback onSelect;
  final Widget Function(BuildContext context, bool isFocused) builder;
  final bool autoScroll;
  final bool autofocus;
  final FocusNode? focusNode;
  final VoidCallback? onMoveLeft;
  final VoidCallback? onMoveRight;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const TVFocusableItem({
    super.key,
    required this.onSelect,
    required this.builder,
    this.autoScroll = true,
    this.autofocus = false,
    this.focusNode,
    this.onMoveLeft,
    this.onMoveRight,
    this.onMoveUp,
    this.onMoveDown,
  });

  @override
  State<TVFocusableItem> createState() => _TVFocusableItemState();
}

class _TVFocusableItemState extends State<TVFocusableItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
        if (focused && widget.autoScroll) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Scrollable.ensureVisible(context, alignment: 0.5, duration: const Duration(milliseconds: 350));
          });
        }
      },
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final k = event.logicalKey;
        if (k == LogicalKeyboardKey.arrowLeft && widget.onMoveLeft != null) {
          widget.onMoveLeft!();
          return KeyEventResult.handled;
        }
        if (k == LogicalKeyboardKey.arrowRight && widget.onMoveRight != null) {
          widget.onMoveRight!();
          return KeyEventResult.handled;
        }
        if (k == LogicalKeyboardKey.arrowUp && widget.onMoveUp != null) {
          widget.onMoveUp!();
          return KeyEventResult.handled;
        }
        if (k == LogicalKeyboardKey.arrowDown && widget.onMoveDown != null) {
          widget.onMoveDown!();
          return KeyEventResult.handled;
        }
        if (k == LogicalKeyboardKey.select ||
            k == LogicalKeyboardKey.enter ||
            k == LogicalKeyboardKey.numpadEnter ||
            k == LogicalKeyboardKey.gameButtonA) {
          widget.onSelect();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedScale(
        scale: _isFocused ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: GlassColors.accentCyan.withOpacity(0.45),
                      blurRadius: 32,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: GlassColors.accentViolet.withOpacity(0.25),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                  ],
          ),
          child: widget.builder(context, _isFocused),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  2. Botao de icone para TV (vidro)
// -----------------------------------------------------------------------------
class TVIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final double size;
  final bool autofocus;
  final FocusNode? focusNode;

  const TVIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = Colors.white70,
    this.size = 20,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TVFocusableItem(
      autofocus: autofocus,
      focusNode: focusNode,
      autoScroll: false,
      onSelect: onPressed,
      builder: (c, f) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(f ? 0.28 : 0.10),
              Colors.white.withOpacity(f ? 0.16 : 0.05),
            ],
          ),
          border: Border.all(
            color: f ? GlassColors.accentCyan.withOpacity(0.9) : Colors.white.withOpacity(0.18),
            width: f ? 1.5 : 1.0,
          ),
          boxShadow: f
              ? [BoxShadow(color: GlassColors.accentCyan.withOpacity(0.4), blurRadius: 20, spreadRadius: 1)]
              : [],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Icon(icon, color: f ? Colors.white : color, size: size),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  3. Teclado virtual para TV (vidro) — A-Z, 0-9, backspace, limpar, confirmar
// -----------------------------------------------------------------------------
Future<void> showTVVirtualKeyboard(
  BuildContext context,
  TextEditingController ctrl,
  String title, {
  bool isPassword = false,
  ValueChanged<String>? onChanged,
}) async {
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const digits = '0123456789';
  final symbols = ['@', '.', '_', '-', ':', '/', '?', '&', '=', '+'];

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModal) {
        void addChar(String ch) {
          ctrl.text += ch;
          ctrl.selection = TextSelection.fromPosition(TextPosition(offset: ctrl.text.length));
          onChanged?.call(ctrl.text);
          setModal(() {});
        }

        void backspace() {
          if (ctrl.text.isNotEmpty) {
            ctrl.text = ctrl.text.substring(0, ctrl.text.length - 1);
            onChanged?.call(ctrl.text);
            setModal(() {});
          }
        }

        Widget keyBtn(String label, VoidCallback onTap, {bool wide = false, IconData? icon, bool accent = false}) {
          return TVFocusableItem(
            autoScroll: false,
            onSelect: onTap,
            builder: (c, f) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 46,
              width: wide ? 110 : 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: accent
                    ? LinearGradient(colors: [GlassColors.accentCyan, GlassColors.accentViolet])
                    : LinearGradient(colors: [
                        Colors.white.withOpacity(f ? 0.25 : 0.10),
                        Colors.white.withOpacity(f ? 0.14 : 0.05),
                      ]),
                border: Border.all(
                  color: f ? GlassColors.accentCyan.withOpacity(0.9) : Colors.white.withOpacity(0.16),
                  width: f ? 1.4 : 1.0,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: icon != null
                      ? Icon(icon, color: accent ? const Color(0xFF06122A) : (f ? Colors.white : Colors.white70), size: 20)
                      : Text(
                          label,
                          style: TextStyle(
                            color: accent ? const Color(0xFF06122A) : (f ? Colors.white : Colors.white70),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          );
        }

        return GlassDialog(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.keyboard_rounded, color: GlassColors.accentCyan, size: 22),
                    const SizedBox(width: 10),
                    Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
                  ],
                ),
                const SizedBox(height: 14),
                GlassSurface(
                  opacity: 0.12,
                  borderRadius: BorderRadius.circular(14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Text(
                    isPassword ? (ctrl.text.isEmpty ? 'Digite...' : '•' * ctrl.text.length) : (ctrl.text.isEmpty ? 'Digite...' : ctrl.text),
                    style: TextStyle(color: ctrl.text.isEmpty ? Colors.white38 : Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(spacing: 6, runSpacing: 6, children: [for (final c in letters.split('')) keyBtn(c, () => addChar(c))]),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: [for (final c in digits.split('')) keyBtn(c, () => addChar(c))]),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: [for (final s in symbols) keyBtn(s, () => addChar(s))]),
                const SizedBox(height: 14),
                Row(
                  children: [
                    keyBtn('APAGAR', backspace, wide: true, icon: Icons.backspace_rounded),
                    const SizedBox(width: 8),
                    keyBtn('LIMPAR', () {
                      ctrl.clear();
                      onChanged?.call(ctrl.text);
                      setModal(() {});
                    }, wide: true, icon: Icons.clear_rounded),
                    const Spacer(),
                    keyBtn('CONFIRMAR', () => Navigator.pop(ctx), wide: true, icon: Icons.check_rounded, accent: true),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

// -----------------------------------------------------------------------------
//  4. Controle Parental (+18) — desbloqueio. Padrao: 0000
// -----------------------------------------------------------------------------
Future<bool> showParentalPinPrompt(
  BuildContext context, {
  DeviceMode deviceMode = DeviceMode.tv,
}) async {
  bool unlocked = false;
  final pinCtrl = TextEditingController();
  final correctPin = await AppStorage.loadParentalPin();
  String errorText = '';

  if (!context.mounted) return false;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModal) => GlassDialog(
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF6B81).withOpacity(0.2),
                      border: Border.all(color: const Color(0xFFFF6B81).withOpacity(0.6)),
                    ),
                    child: const Icon(Icons.lock_rounded, color: Color(0xFFFF6B81), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Conteúdo Adulto (+18)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Digite a senha de Controle Parental para liberar o acesso (Padrão: 0000):',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (deviceMode == DeviceMode.mobile)
                GlassTextField(
                  controller: pinCtrl,
                  hint: '0000',
                  icon: Icons.pin_rounded,
                  obscure: true,
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) {},
                )
              else
                TVFocusableItem(
                  autoScroll: false,
                  onSelect: () async {
                    await showTVVirtualKeyboard(context, pinCtrl, 'Senha Parental', isPassword: true, onChanged: (_) => setModal(() {}));
                    setModal(() {});
                  },
                  builder: (c, f) => GlassSurface(
                    opacity: f ? 0.18 : 0.10,
                    borderOpacity: f ? 0.6 : 0.22,
                    borderRadius: BorderRadius.circular(14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Text(
                      pinCtrl.text.isEmpty ? 'Selecione para digitar a senha...' : '•' * pinCtrl.text.length,
                      style: TextStyle(color: pinCtrl.text.isEmpty ? Colors.white38 : Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              if (errorText.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(errorText, style: const TextStyle(color: Color(0xFFFF6B81), fontSize: 12.5, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GlassButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 10),
                  GlassButton(
                    accent: true,
                    icon: Icons.lock_open_rounded,
                    onPressed: () {
                      if (pinCtrl.text.trim() == correctPin) {
                        unlocked = true;
                        Navigator.pop(ctx);
                      } else {
                        setModal(() {
                          errorText = 'Senha incorreta. Tente novamente.';
                          pinCtrl.clear();
                        });
                      }
                    },
                    child: const Text('Desbloquear'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return unlocked;
}

// -----------------------------------------------------------------------------
//  5. Alterar senha parental
// -----------------------------------------------------------------------------
Future<void> showChangeParentalPinDialog(
  BuildContext context, {
  DeviceMode deviceMode = DeviceMode.tv,
}) async {
  final currentCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  String errorText = '';

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModal) => GlassDialog(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_rounded, color: GlassColors.accentCyan, size: 24),
                  const SizedBox(width: 10),
                  const Text('Alterar Senha Parental', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 16),
              GlassTextField(controller: currentCtrl, hint: 'Senha Atual (Padrão: 0000)', icon: Icons.lock_rounded, obscure: true),
              const SizedBox(height: 10),
              GlassTextField(controller: newCtrl, hint: 'Nova Senha (4 dígitos)', icon: Icons.refresh_rounded, obscure: true),
              const SizedBox(height: 10),
              GlassTextField(controller: confirmCtrl, hint: 'Confirmar Nova Senha', icon: Icons.check_rounded, obscure: true),
              if (errorText.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(errorText, style: const TextStyle(color: Color(0xFFFF6B81), fontSize: 12.5, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GlassButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                  const SizedBox(width: 10),
                  GlassButton(
                    accent: true,
                    icon: Icons.save_rounded,
                    onPressed: () async {
                      final correct = await AppStorage.loadParentalPin();
                      if (currentCtrl.text.trim() != correct) {
                        setModal(() => errorText = 'Senha atual incorreta.');
                        return;
                      }
                      if (newCtrl.text.trim().length < 4) {
                        setModal(() => errorText = 'A nova senha deve ter ao menos 4 dígitos.');
                        return;
                      }
                      if (newCtrl.text.trim() != confirmCtrl.text.trim()) {
                        setModal(() => errorText = 'As senhas não coincidem.');
                        return;
                      }
                      await AppStorage.saveParentalPin(newCtrl.text.trim());
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Salvar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// -----------------------------------------------------------------------------
//  6. Cartaz de streaming (poster) — vidro, usado em todas as grades
// -----------------------------------------------------------------------------
Widget buildStreamingPosterCard({
  required String title,
  required String subtitle,
  required String logoUrl,
  required String badgeText,
  required VoidCallback onTap,
  bool isFocused = false,
  bool isPlaying = false,
  bool isFavorite = false,
  bool isAdultLocked = false,
  double? progress,
  VoidCallback? onFavoriteTap,
  String? audioBadgeText,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(isFocused ? 0.20 : 0.10),
            Colors.white.withOpacity(isFocused ? 0.12 : 0.05),
          ],
        ),
        border: Border.all(
          color: isFocused ? GlassColors.accentCyan.withOpacity(0.9) : Colors.white.withOpacity(0.16),
          width: isFocused ? 1.5 : 1.0,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(color: GlassColors.accentCyan.withOpacity(0.4), blurRadius: 28, spreadRadius: 1.5),
              ]
            : [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: isFocused ? 24 : 16, sigmaY: isFocused ? 24 : 16),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (logoUrl.isNotEmpty)
                          Image.network(
                            logoUrl,
                            fit: BoxFit.cover,
                            cacheWidth: 300,
                            errorBuilder: (_, __, ___) => _posterPlaceholder(title),
                          )
                        else
                          _posterPlaceholder(title),
                        // Gradiente de vidro sobre o poster
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                            ),
                          ),
                        ),
                        // Badge de qualidade
                        if (badgeText.isNotEmpty)
                          Positioned(top: 8, left: 8, child: buildQualityBadge(badgeText)),
                        // Badge de audio (Dublado/Legendado)
                        if (audioBadgeText != null && audioBadgeText.isNotEmpty)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GlassChip(label: audioBadgeText, accent: true),
                          ),
                        // Cadeado adulto
                        if (isAdultLocked)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFF6B81).withOpacity(0.85),
                              ),
                              child: const Icon(Icons.lock_rounded, color: Colors.white, size: 14),
                            ),
                          ),
                        // Indicador "agora tocando"
                        if (isPlaying)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: GlassColors.accentGradient,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text('AO VIVO', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                                ],
                              ),
                            ),
                          ),
                        // Favorito
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: onFavoriteTap,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.4),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Icon(
                                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isFavorite ? const Color(0xFFFF6B81) : Colors.white70,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Barra de progresso (continue watching)
                  if (progress != null)
                    LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 3,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(GlassColors.accentCyan),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _posterPlaceholder(String title) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [GlassColors.accentCyan.withOpacity(0.25), GlassColors.accentViolet.withOpacity(0.25)],
      ),
    ),
    child: Center(
      child: Text(
        title.isNotEmpty ? title[0].toUpperCase() : '?',
        style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white.withOpacity(0.7)),
      ),
    ),
  );
}

// -----------------------------------------------------------------------------
//  7. Badge de qualidade (4K / FHD / HD)
// -----------------------------------------------------------------------------
Widget buildQualityBadge(String tag) {
  final isHigh = tag == '4K' || tag == 'FHD';
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: isHigh ? GlassColors.accentCyan.withOpacity(0.25) : Colors.black.withOpacity(0.6),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: isHigh ? GlassColors.accentCyan : Colors.white.withOpacity(0.25),
        width: 1,
      ),
    ),
    child: Text(
      tag,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.4,
        color: isHigh ? GlassColors.accentCyan : Colors.white,
      ),
    ),
  );
}

// -----------------------------------------------------------------------------
//  8. Logo do canal (vidro)
// -----------------------------------------------------------------------------
Widget buildChannelLogo(String url, {double size = 48, bool isLocked = false}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.05)]),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.18)),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: isLocked
            ? const Icon(Icons.lock_rounded, color: Color(0xFFFF6B81), size: 22)
            : url.isNotEmpty
                ? Image.network(
                    url,
                    fit: BoxFit.contain,
                    cacheWidth: 120,
                    errorBuilder: (_, __, ___) => const Icon(Icons.live_tv_rounded, color: GlassColors.accentCyan),
                  )
                : const Icon(Icons.live_tv_rounded, color: GlassColors.accentCyan),
      ),
    ),
  );
}

// -----------------------------------------------------------------------------
//  9. Prompt de retomar VOD (continue watching)
// -----------------------------------------------------------------------------
Future<Duration?> showVodResumePrompt({
  required BuildContext context,
  required VodProgressEntry entry,
}) async {
  return showDialog<Duration?>(
    context: context,
    builder: (ctx) => GlassDialog(
      child: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_rounded, color: GlassColors.accentCyan, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Você parou em ${entry.formattedPosition} (${entry.formattedRemaining}).',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: entry.progress,
                minHeight: 7,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(GlassColors.accentCyan),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GlassButton(
                  onPressed: () => Navigator.pop(ctx, Duration.zero),
                  child: const Text('Do Início'),
                ),
                const SizedBox(width: 10),
                GlassButton(
                  accent: true,
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => Navigator.pop(ctx, Duration(seconds: entry.positionSeconds)),
                  child: const Text('Continuar'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
