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
  List<String> _groups = [];
  String? _selectedGroup;
  List<MediaItem> _movies = [];
  bool _loading = true;
  String _search = "";

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _groups = await _repo.movieGroups();
    _selectedGroup = _groups.isNotEmpty ? _groups.first : null;
    await _loadMovies();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMovies() async {
    _movies = await _repo.movies(group: _selectedGroup, limit: 1000, search: _search.isEmpty ? null : _search);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: SkeletonGrid());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
          child: Row(
            children: [
              const Text("Filmes", style: AppTheme.titleH1),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text("${_movies.length} títulos", style: AppTheme.badge.copyWith(color: AppTheme.accent)),
              ),
              const Spacer(),
              SizedBox(
                width: 260,
                height: 40,
                child: TextField(
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Buscar filme...",
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 18),
                    filled: true,
                    fillColor: AppTheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: const BorderSide(color: AppTheme.accent, width: 1.5)),
                  ),
                  onChanged: (v) async {
                    _search = v;
                    await _loadMovies();
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(color: AppTheme.surface.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _groups.length,
                  itemBuilder: (_, i) {
                    final g = _groups[i];
                    final sel = g == _selectedGroup;
                    return TVFocusableItem(
                      autofocus: i == 0,
                      borderRadius: AppTheme.radiusSm,
                      onTap: () async {
                        _selectedGroup = g;
                        setState(() => _loading = true);
                        await _loadMovies();
                        setState(() => _loading = false);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                        decoration: BoxDecoration(
                          color: sel ? AppTheme.accent.withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(color: sel ? AppTheme.accent : Colors.transparent, width: sel ? 1.5 : 0),
                        ),
                        child: Text(g, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: sel ? AppTheme.accent : AppTheme.textPrimary, fontWeight: sel ? FontWeight.w800 : FontWeight.w500, fontSize: 13)),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, childAspectRatio: 0.58, crossAxisSpacing: 12, mainAxisSpacing: 12),
                        itemCount: _movies.length,
                        itemBuilder: (_, i) {
                          final m = _movies[i];
                          final fav = AppStorage.instance.isFavorite(m.id);
                          return TVFocusableItem(
                            borderRadius: AppTheme.radiusLg,
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(item: m))),
                            onLongPress: () {
                              AppStorage.instance.toggleFavorite(m.id);
                              setState(() {});
                            },
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      m.logo != null && m.logo!.isNotEmpty
                                          ? CachedNetworkImage(imageUrl: m.logo!, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Center(child: Icon(Icons.movie_rounded, size: 40, color: AppTheme.textMuted)))
                                          : const Center(child: Icon(Icons.movie_rounded, size: 40, color: AppTheme.textMuted)),
                                      const DecoratedBox(decoration: BoxDecoration(gradient: AppTheme.cardGradient)),
                                      Positioned(
                                        left: 8, right: 8, bottom: 8,
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(m.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                                          const SizedBox(height: 4),
                                          AppTheme.qualityBadge(m.quality),
                                        ]),
                                      ),
                                    ],
                                  ),
                                ),
                                if (fav) const Positioned(top: 6, right: 6, child: Icon(Icons.favorite, color: AppTheme.danger, size: 18)),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
