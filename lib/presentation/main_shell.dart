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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.2,
            colors: [Color(0xFF12202E), AppTheme.background],
            stops: [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.overscan / 2),
            child: Row(
              children: [
                // Menu lateral moderno
                Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    children: [
                      // Logo
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppTheme.accentGradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accent.withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "UNEX",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                letterSpacing: 2,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Colors.white10, indent: 16, endIndent: 16),
                      const SizedBox(height: 8),
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
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
                                decoration: BoxDecoration(
                                  gradient: selected ? AppTheme.accentGradient : null,
                                  color: selected ? null : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  border: Border.all(
                                    color: selected ? Colors.transparent : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      selected ? iconOn : iconOff,
                                      color: selected ? Colors.black : AppTheme.textSecondary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        color: selected ? Colors.black : AppTheme.textPrimary,
                                        fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceHighlight,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_user_rounded, color: AppTheme.success, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Conta ativa",
                                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Conteúdo
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey(_index),
                      child: _buildPage(_index),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage(int i) {
    switch (i) {
      case 0:
        return const HomeScreen();
      case 1:
        return const LiveTvScreen();
      case 2:
        return const MoviesScreen();
      case 3:
        return const SeriesScreen();
      case 4:
        return const FavoritesScreen();
      case 5:
        return const HistoryScreen();
      case 6:
        return const SettingsScreen();
      default:
        return const HomeScreen();
    }
  }
}
