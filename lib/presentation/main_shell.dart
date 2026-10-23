import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../widgets/tv_focusable_item.dart';
import 'home/home_screen.dart';
import 'live_tv/live_tv_screen.dart';
import 'movies/movies_screen.dart';
import 'series/series_screen.dart';
import 'favorites/favorites_screen.dart';
import 'history/history_screen.dart';
import 'settings/settings_screen.dart';

/// Shell principal: menu lateral (glass) + conteúdo com IndexedStack.
/// IndexedStack preserva o estado de cada aba (posição de scroll, busca)
/// em vez de recriar a página a cada troca — sem recarregamento.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.ambientGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.overscan / 2),
            child: Row(
              children: [
                // Menu lateral — efeito glass (frosted) sem blur pesado
                Container(
                  width: 210,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    border: Border.all(color: AppTheme.glassBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Logo
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                gradient: AppTheme.accentGradient,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accent
                                        .withValues(alpha: 0.45),
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
                          indent: 18,
                          endIndent: 18),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _tabs.length,
                          itemBuilder: (_, i) {
                            final (label, iconOff, iconOn) = _tabs[i];
                            final selected = i == _index;
                            return TVFocusableItem(
                              autofocus: i == 0,
                              borderRadius: AppTheme.radiusMd,
                              onTap: () => setState(() => _index = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 16),
                                decoration: BoxDecoration(
                                  gradient: selected
                                      ? AppTheme.accentGradient
                                      : null,
                                  color: selected
                                      ? null
                                      : Colors.transparent,
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusMd),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.accent
                                                .withValues(alpha: 0.35),
                                            blurRadius: 14,
                                            offset: const Offset(0, 3),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Row(
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
                            );
                          },
                        ),
                      ),
                      // Rodapé: status da conta
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceHighlight
                                .withValues(alpha: 0.6),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: AppTheme.glassBorder),
                          ),
                          child: Row(
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
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Conteúdo — IndexedStack mantém cada aba viva na memória.
                Expanded(child: IndexedStack(index: _index, children: _pages)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
