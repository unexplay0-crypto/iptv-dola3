import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app_theme.dart';
import '../../core/models.dart';
import '../../core/storage.dart';
import '../../data/repositories/content_repository.dart';
import '../../widgets/tv_focusable_item.dart';
import '../../widgets/skeleton.dart';
import '../player/player_screen.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final _repo = ContentRepository();
  List<String> _genres = [];
  String? _selected;
  List<MediaItem> _movies = [];
  bool _loading = true;
  String _search = "";

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _genres = await _repo.movieGroups();
    _selected = _genres.isNotEmpty ? _genres.first : null;
    await _loadMovies();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMovies() async {
    _movies = await _repo.movies(group: _selected, limit: 1000, search: _search.isEmpty ? null : _search);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: SkeletonGrid());
    return Column(children: [
      // Barra de busca + gêneros
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Expanded(
            child: TextField(
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: "Buscar filme...",
                hintStyle: TextStyle(color: AppTheme.textSecondary),
                prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
              onChanged: (v) async {
                _search = v;
                await _loadMovies();
              },
            ),
          ),
        ]),
      ),
      SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _genres.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final g = _genres[i];
            final sel = g == _selected;
            return TVFocusableItem(
              autofocus: i == 0,
              onTap: () async {
                _selected = g;
                setState(() => _loading = true);
                await _loadMovies();
                setState(() => _loading = false);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.accent : AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(g, style: TextStyle(color: sel ? Colors.black : AppTheme.textPrimary, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, childAspectRatio: 0.6, crossAxisSpacing: 10, mainAxisSpacing: 10),
          itemCount: _movies.length,
          itemBuilder: (_, i) {
            final m = _movies[i];
            return TVFocusableItem(
              onTap: () {
                if (m.isAdult && !AppStorage.instance.adultUnlocked) {
                  // abre player que pedirá PIN
                }
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(item: m)));
              },
              child: Column(children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: AppTheme.surface,
                    child: m.logo != null
                        ? CachedNetworkImage(imageUrl: m.logo!, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.movie, size: 40, color: Colors.grey))
                        : const Icon(Icons.movie, size: 40, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 4),
                Text(m.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}
