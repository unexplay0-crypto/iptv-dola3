import '../../widgets/fast_image.dart';
import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../core/models.dart';
import '../../core/storage.dart';
import '../../data/repositories/content_repository.dart';
import '../../widgets/tv_focusable_item.dart';
import '../../widgets/skeleton.dart';
import '../player/player_screen.dart';

/// Filmes — pôsteres GRANDES (4 colunas, proporção 2:3).
/// Performance: catálogo carregado uma vez em memória; troca de categoria
/// e busca filtram em memória (síncrono, sem recarregar, sem spinner).
class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen>
    with AutomaticKeepAliveClientMixin {
  final _repo = ContentRepository();
  final TextEditingController _searchCtrl = TextEditingController();

  List<String> _groups = [];
  String? _selectedGroup;
  List<MediaItem> _allMovies = []; // cache em memória
  bool _loading = true;
  String _search = "";

  static final _yearReg = RegExp(r"\((\d{4})\)");

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final groupsFuture = _repo.movieGroups();
    final moviesFuture = _repo.movies(limit: 100000);
    final results = await Future.wait([groupsFuture, moviesFuture]);
    _groups = ["Todos", ...(results[0] as List<String>)];
    _allMovies = results[1] as List<MediaItem>;
    if (_groups.isNotEmpty) _selectedGroup = _groups.first;
    if (mounted) setState(() => _loading = false);
  }

  List<MediaItem> get _filtered {
    final q = _search.trim().toLowerCase();
    return _allMovies.where((m) {
      if (_selectedGroup != null &&
          _selectedGroup != "Todos" &&
          m.group != _selectedGroup) return false;
      if (q.isNotEmpty && !m.name.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  String? _yearOf(String name) {
    final m = _yearReg.firstMatch(name);
    return m?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: SkeletonGrid());

    final movies = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
          child: Row(
            children: [
              const Text("Filmes", style: AppTheme.titleH1),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.accent.withValues(alpha: 0.4)),
                ),
                child: Text("${movies.length} títulos",
                    style: AppTheme.badge
                        .copyWith(color: AppTheme.accent, fontSize: 10)),
              ),
              const Spacer(),
              SizedBox(
                width: 300,
                height: 44,
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Buscar filme...",
                    hintStyle: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 14),
                    prefixIcon:
                        const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: AppTheme.textMuted, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _search = "");
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.surface.withValues(alpha: 0.8),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: const BorderSide(
                            color: AppTheme.accent, width: 1.5)),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              // Sidebar de categorias (glass)
              Container(
                width: 220,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: _groups.length,
                  itemBuilder: (_, i) {
                    final g = _groups[i];
                    final sel = g == _selectedGroup;
                    return TVFocusableItem(
                      autofocus: i == 0,
                      borderRadius: AppTheme.radiusSm,
                      onTap: () => setState(() => _selectedGroup = g),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            vertical: 13, horizontal: 14),
                        decoration: BoxDecoration(
                          gradient: sel ? AppTheme.accentGradient : null,
                          color: sel ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                    color: AppTheme.accent
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          g,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: sel ? Colors.black : AppTheme.textPrimary,
                            fontWeight:
                                sel ? FontWeight.w900 : FontWeight.w600,
                            fontSize: 14,
                            height: 1.2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Grade de pôsteres GRANDES (4 colunas, proporção 2:3)
              Expanded(
                child: movies.isEmpty
                    ? const Center(
                        child: Text("Nenhum filme encontrado.",
                            style: TextStyle(color: AppTheme.textSecondary)))
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.62, // pôster 2:3 com espaço para título
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: movies.length,
                        itemBuilder: (_, i) {
                          final m = movies[i];
                          final fav = AppStorage.instance.isFavorite(m.id);
                          final year = _yearOf(m.name);
                          return TVFocusableItem(
                            borderRadius: AppTheme.radiusPoster,
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => PlayerScreen(item: m))),
                            onLongPress: () {
                              AppStorage.instance.toggleFavorite(m.id);
                              setState(() {});
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusPoster),
                                boxShadow: AppTheme.cardShadow,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Pôster em tamanho grande
                                  m.logo != null && m.logo!.isNotEmpty
                                      ? FastImage(
                                          url: m.logo!,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) =>
                                              const Center(
                                                  child: Icon(
                                                      Icons.movie_rounded,
                                                      size: 48,
                                                      color: AppTheme
                                                          .textMuted)),
                                        )
                                      : const Center(
                                          child: Icon(Icons.movie_rounded,
                                              size: 48,
                                              color: AppTheme.textMuted)),
                                  // Gradiente sobreposto para legibilidade
                                  const DecoratedBox(
                                      decoration:
                                          BoxDecoration(gradient: AppTheme.cardGradient)),
                                  // Badge de qualidade (topo)
                                  if (m.quality != null &&
                                      m.quality!.isNotEmpty)
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: AppTheme.qualityBadge(m.quality),
                                    ),
                                  // Favorito (topo direito)
                                  if (fav)
                                    const Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Icon(Icons.favorite,
                                          color: AppTheme.danger, size: 20),
                                    ),
                                  // Título + ano (base)
                                  Positioned(
                                    left: 10,
                                    right: 10,
                                    bottom: 10,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTheme.posterTitle,
                                        ),
                                        if (year != null) ...[
                                          const SizedBox(height: 4),
                                          Text(year,
                                              style: AppTheme.posterMeta),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
