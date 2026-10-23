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
    ("Início", Icons.home),
    ("TV Ao Vivo", Icons.live_tv),
    ("Filmes", Icons.movie),
    ("Séries", Icons.tv),
    ("Favoritos", Icons.favorite),
    ("Histórico", Icons.history),
    ("Configurações", Icons.settings),
  ];

  final _pages = const [
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.overscan / 2),
          child: Row(
            children: [
              // Menu lateral (navegável por D-Pad)
              Container(
                width: 180,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.play_circle_fill, color: AppTheme.accent, size: 28),
                        SizedBox(width: 6),
                        Text("UNEX", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ]),
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _tabs.length,
                        itemBuilder: (_, i) {
                          final (label, icon) = _tabs[i];
                          final selected = i == _index;
                          return TVFocusableItem(
                            autofocus: i == 0,
                            borderRadius: 8,
                            onTap: () => setState(() => _index = i),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              decoration: BoxDecoration(
                                color: selected ? AppTheme.accent.withOpacity(0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: selected ? AppTheme.accent : Colors.transparent, width: 1),
                              ),
                              child: Row(children: [
                                Icon(icon, color: selected ? AppTheme.accent : AppTheme.textSecondary, size: 20),
                                const SizedBox(width: 10),
                                Text(label, style: TextStyle(color: selected ? AppTheme.accent : AppTheme.textPrimary, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _pages[_index]),
            ],
          ),
        ),
      ),
    );
  }
}
