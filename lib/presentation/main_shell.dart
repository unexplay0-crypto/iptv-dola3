import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';
import '../core/device_config.dart';
import '../core/storage.dart';
import '../data/speed_test_service.dart';
import '../widgets/tv_focusable_item.dart';
import 'home/home_screen.dart';
import 'live_tv/live_tv_screen.dart';
import 'movies/movies_screen.dart';
import 'series/series_screen.dart';
import 'favorites/favorites_screen.dart';
import 'history/history_screen.dart';
import 'settings/settings_screen.dart';

/// Shell principal: menu lateral (glass) recolhível + conteúdo com IndexedStack.
/// - Ao entrar em TV Ao Vivo / Filmes / Séries, o menu recolhe automaticamente
///   (mais espaço para conteúdo). Reabre com o botão Voltar ou com seta ← no
///   conteúdo (D-pad).
/// - Teste de velocidade disponível apenas aqui (pós-login).
/// - Mostra data de vencimento da lista; aviso de 3s se faltar ≤3 dias.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  bool _menuCollapsed = false;
  DateTime? _lastBack;
  // Animação escalonada (stagger) dos itens do menu — cada item entra com
  // fade + slide sequencial, padrão fluido e divertido.
  late final AnimationController _menuAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  static const _tabs = [
    ("Início", Icons.home_outlined, Icons.home),
    ("TV Ao Vivo", Icons.live_tv_outlined, Icons.live_tv),
    ("Filmes", Icons.movie_outlined, Icons.movie),
    ("Séries", Icons.tv_outlined, Icons.tv),
    ("Favoritos", Icons.favorite_border, Icons.favorite),
    ("Histórico", Icons.history_outlined, Icons.history),
    ("Configurações", Icons.settings_outlined, Icons.settings),
  ];

  static const _pages = [
    HomeScreen(),
    LiveTvScreen(),
    MoviesScreen(),
    SeriesScreen(),
    FavoritesScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  // Abas que recolhem o menu automaticamente (conteúdo em grade).
  static const _collapseFor = {1, 2, 3}; // TV Ao Vivo, Filmes, Séries

  @override
  void initState() {
    super.initState();
    _menuAnim.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkExpiry());
  }

  @override
  void dispose() {
    _menuAnim.dispose();
    super.dispose();
  }

  /// Avisa sobre vencimento iminente (≤3 dias) com popup de 3 segundos.
  void _checkExpiry() {
    final days = AppStorage.instance.daysUntilExpiry;
    if (days != null && days >= 0 && days <= 3) {
      final msg = days == 0
          ? "Sua lista vence HOJE!"
          : "Sua lista vence em $days ${days == 1 ? 'dia' : 'dias'}.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: days <= 1 ? AppTheme.danger : AppTheme.gold,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _selectTab(int i) {
    final wasCollapsed = _menuCollapsed;
    setState(() {
      _index = i;
      _menuCollapsed = _collapseFor.contains(i);
    });
    // Re-dispara a animação escalonada quando o menu volta a abrir.
    if (wasCollapsed && !_menuCollapsed) _menuAnim.forward(from: 0);
  }

  void _toggleMenu() {
    final wasCollapsed = _menuCollapsed;
    setState(() => _menuCollapsed = !_menuCollapsed);
    if (wasCollapsed) _menuAnim.forward(from: 0);
  }

  Future<bool> _onWillPop() async {
    // Se o menu está recolhido, o primeiro Voltar o reabre (não sai do app).
    if (_menuCollapsed) {
      setState(() => _menuCollapsed = false);
      return false;
    }
    final now = DateTime.now();
    if (_lastBack != null &&
        now.difference(_lastBack!) < const Duration(milliseconds: 1200)) {
      return true; // sai do app
    }
    _lastBack = now;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Pressione Voltar novamente para sair"),
        duration: Duration(seconds: 1)));
    return false;
  }

  void _runSpeedTest() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SpeedTestDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cfg = DeviceConfig.of(context);
    final collapsedW = (cfg.sideMenuWidth * 0.36).clamp(56.0, 90.0);
    final menuWidth = _menuCollapsed ? collapsedW : cfg.sideMenuWidth;
    final days = AppStorage.instance.daysUntilExpiry;
    final expiryMillis = AppStorage.instance.expiryDateMillis;
    String? expiryText;
    if (expiryMillis != null) {
      final d = DateTime.fromMillisecondsSinceEpoch(expiryMillis);
      expiryText =
          "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, __) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (!mounted) return;
        if (shouldPop) Navigator.of(context).pop();
      },
      child: Scaffold(
        body: Container(
          decoration:
              const BoxDecoration(gradient: AppTheme.ambientGradient),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(cfg.overscan / 2),
              child: Row(
                children: [
                  // Menu lateral — glass, com largura animada
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: menuWidth,
                    margin: const EdgeInsets.only(right: 16),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusXl),
                      border: Border.all(color: AppTheme.glassBorder),
                      boxShadow: AppTheme.glassShadow,
                    ),
                    child: Stack(
                      children: [
                        // Vidro fosco: blur real do fundo (painel fixo)
                        Positioned.fill(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                            child: const SizedBox.shrink(),
                          ),
                        ),
                        // Brilho especular no topo (reflexo de luz)
                        const Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(
                                  Radius.circular(AppTheme.radiusXl)),
                              gradient: AppTheme.glassSpecular,
                            ),
                          ),
                        ),
                        Column(
                      children: [
                        // Logo
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: _menuCollapsed
                              ? Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.accentGradient,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.play_arrow_rounded,
                                      color: Colors.black, size: 24),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.accentGradient,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.accent
                                                .withOpacity(0.45),
                                            blurRadius: 18,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.black,
                                          size: 24),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      "UNEX",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 22,
                                        letterSpacing: 2.5,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const Divider(
                            height: 1,
                            color: Colors.white10,
                            indent: 14,
                            endIndent: 14),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _tabs.length,
                            itemBuilder: (_, i) {
                              final (label, iconOff, iconOn) = _tabs[i];
                              final selected = i == _index;
                              // Animação escalonada: cada item começa num
                              // instante diferente (fade + slide da esquerda).
                              final itemAnim = CurvedAnimation(
                                parent: _menuAnim,
                                curve: Interval((i / _tabs.length) * 0.5, 1.0,
                                    curve: Curves.easeOutCubic),
                              );
                              return FadeTransition(
                                opacity: itemAnim,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(-0.18, 0),
                                    end: Offset.zero,
                                  ).animate(itemAnim),
                                  child: TVFocusableItem(
                                autofocus: i == 0,
                                borderRadius: AppTheme.radiusMd,
                                onTap: () => _selectTab(i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  padding: EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: _menuCollapsed ? 0 : 16),
                                  decoration: BoxDecoration(
                                    gradient: selected
                                        ? AppTheme.accentGradient
                                        : null,
                                    color: selected
                                        ? null
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMd),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.accent
                                                  .withOpacity(0.35),
                                              blurRadius: 14,
                                              offset: const Offset(0, 3),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: _menuCollapsed
                                      ? Center(
                                          child: Icon(
                                            selected ? iconOn : iconOff,
                                            color: selected
                                                ? Colors.black
                                                : AppTheme.textSecondary,
                                            size: 24,
                                          ),
                                        )
                                      : Row(
                                          children: [
                                            Icon(
                                              selected ? iconOn : iconOff,
                                              color: selected
                                                  ? Colors.black
                                                  : AppTheme.textSecondary,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 14),
                                            Text(
                                              label,
                                              style: TextStyle(
                                                color: selected
                                                    ? Colors.black
                                                    : AppTheme.textPrimary,
                                                fontWeight: selected
                                                    ? FontWeight.w900
                                                    : FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              )));
                            },
                          ),
                        ),
                        // Teste de velocidade (apenas pós-login, no menu)
                        if (!_menuCollapsed)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            child: TVFocusableItem(
                              borderRadius: AppTheme.radiusMd,
                              onTap: _runSpeedTest,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 14),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceHighlight
                                      .withOpacity(0.6),
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusMd),
                                  border:
                                      Border.all(color: AppTheme.glassBorder),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.speed,
                                        color: AppTheme.accent, size: 20),
                                    SizedBox(width: 12),
                                    Text("Testar Velocidade",
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // Rodapé: status da conta + vencimento
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceHighlight
                                  .withOpacity(0.6),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                              border:
                                  Border.all(color: AppTheme.glassBorder),
                            ),
                            child: _menuCollapsed
                                ? const Center(
                                    child: Icon(Icons.verified_user_rounded,
                                        color: AppTheme.success, size: 20),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                                color: AppTheme.success,
                                                shape: BoxShape.circle),
                                          ),
                                          const SizedBox(width: 10),
                                          const Expanded(
                                            child: Text(
                                              "Conta ativa",
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppTheme.textSecondary,
                                                  fontWeight:
                                                      FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (expiryText != null) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.event,
                                                color: AppTheme.textMuted,
                                                size: 14),
                                            const SizedBox(width: 6),
                                            Text(
                                              "Vence: $expiryText",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: (days != null &&
                                                        days <= 3)
                                                    ? AppTheme.danger
                                                    : AppTheme.textMuted,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (days != null && days >= 0)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 3),
                                            child: Text(
                                              days <= 0
                                                  ? "Vence hoje"
                                                  : "Faltam $days ${days == 1 ? 'dia' : 'dias'}",
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: days <= 3
                                                    ? AppTheme.danger
                                                    : AppTheme.textMuted,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                      ],
                    ),
                  ),
                  // Conteúdo — seta ← reabre o menu quando recolhido
                  Expanded(
                    child: Focus(
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent &&
                            _menuCollapsed &&
                            event.logicalKey.keyLabel == "Arrow Left") {
                          _toggleMenu();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: IndexedStack(index: _index, children: _pages),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog de teste de velocidade (executa e mostra resultado).
class _SpeedTestDialog extends StatefulWidget {
  const _SpeedTestDialog();

  @override
  State<_SpeedTestDialog> createState() => _SpeedTestDialogState();
}

class _SpeedTestDialogState extends State<_SpeedTestDialog> {
  bool _testing = true;
  double _download = 0;
  double _ping = 0;
  double _jitter = 0;
  String _error = "";

  Color get _qualityColor {
    if (_download < 3) return AppTheme.danger;
    if (_download < 8) return AppTheme.gold;
    if (_download < 25) return AppTheme.success;
    return AppTheme.accent;
  }

  String get _qualityLabel {
    if (_download < 3) return "Ruim — recomendado SD";
    if (_download < 8) return "Razoável — recomendado HD";
    if (_download < 25) return "Boa — recomendado FHD";
    return "Excelente — recomendado 4K";
  }

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final dns = AppStorage.instance.credentials.dns;
      final r = await SpeedTestService.run(
          dns.isNotEmpty ? dns : "https://speed.cloudflare.com");
      if (mounted) {
        setState(() {
          _download = r.downloadMbps;
          _ping = r.pingMs;
          _jitter = r.jitterMs;
          _testing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Erro: $e";
          _testing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Teste de Velocidade",
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            if (_testing) ...[
              const CircularProgressIndicator(color: AppTheme.accent),
              const SizedBox(height: 16),
              const Text("Medindo... isso leva alguns segundos",
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
            ] else if (_error.isNotEmpty) ...[
              const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
              const SizedBox(height: 12),
              Text(_error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.danger)),
            ] else ...[
              // Download em destaque grande
              Text(_download.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: _qualityColor,
                    height: 1,
                  )),
              const Text("Mbps de download",
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _qualityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _qualityColor.withOpacity(0.5)),
                ),
                child: Text(_qualityLabel,
                    style: TextStyle(
                        color: _qualityColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _metric("Ping", "${_ping.toStringAsFixed(0)} ms"),
                  const SizedBox(width: 32),
                  _metric("Jitter", "${_jitter.toStringAsFixed(0)} ms"),
                ],
              ),
            ],
            const SizedBox(height: 24),
            TVFocusableItem(
              autofocus: true,
              borderRadius: AppTheme.radiusMd,
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                alignment: Alignment.center,
                child: const Text("Fechar",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 11)),
      ],
    );
  }
}
