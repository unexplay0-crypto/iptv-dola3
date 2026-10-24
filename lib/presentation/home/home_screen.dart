import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../core/models.dart';
import '../../core/storage.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/trending_service.dart';
import '../../widgets/fast_image.dart';
import '../../widgets/banner_rotator.dart';
import '../../widgets/tv_focusable_item.dart';
import '../../widgets/skeleton.dart';
import '../player/player_screen.dart';
import '../series/series_screen.dart';

/// Início — banner rotativo de recomendações (trending, sempre do catálogo) +
/// linhas horizontais de pôsteres grandes (continuar assistindo, mais
/// assistidos, histórico).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final _repo = ContentRepository();
  final _trending = TrendingService.instance;
  List<ResolvedBanner> _banners = [];
  List<MediaItem> _continueWatching = [];
  List<MediaItem> _history = [];
  List<MediaItem> _mostWatched = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // 1. Tenta banners cacheados do TrendingService (atualizados a cada 48h
      //    em background). Sempre itens DO catálogo.
      final cached = await _trending.getCached();
      if (cached != null && cached.isNotEmpty) {
        _banners = await _resolveBanners(cached);
      }
      // 2. Se cache vazio/vencido, dispara refresh em background (imperceptível)
      //    e usa fallback: filmes aleatórios DO catálogo (nunca de fora).
      if (_banners.isEmpty) {
        _trending.refreshIfStale();
        final movies = await _repo.movies(limit: 60);
        movies.shuffle();
        _banners = movies.take(5).map((m) => ResolvedBanner(
              kind: "movie",
              displayName: m.name,
              movie: m,
            )).toList();
        // Quando o refresh em background concluir, atualiza os banners.
        _trending.refresh().then((fresh) async {
          if (fresh.isNotEmpty) {
            final resolved = await _resolveBanners(fresh);
            if (resolved.isNotEmpty && mounted) {
              setState(() => _banners = resolved);
            }
          }
        }).catchError((_) {});
      }
      final storage = AppStorage.instance;
      final progressIds = storage.vodProgress.keys.toList().take(10).toList();
      _continueWatching = await _repo.byIds(progressIds);
      _history = await _repo.byIds(storage.history.take(10).toList());
      final views = storage.channelViews;
      final sorted = views.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      _mostWatched =
          await _repo.byIds(sorted.take(10).map((e) => e.key).toList());
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  /// Resolve MatchedBanner (ids) em ResolvedBanner (objetos reais do catálogo).
  /// Itens que não resolvem (ex: removidos da lista) são descartados.
  Future<List<ResolvedBanner>> _resolveBanners(
      List<MatchedBanner> list) async {
    final out = <ResolvedBanner>[];
    for (final b in list) {
      if (b.kind == "series") {
        final sg = await _repo.seriesByKey(b.itemId);
        if (sg != null) {
          out.add(ResolvedBanner(
              kind: "series", displayName: sg.name, series: sg, tmdb: b.tmdb));
        }
      } else {
        final m = await _repo.byId(b.itemId);
        if (m != null) {
          out.add(ResolvedBanner(
              kind: "movie", displayName: m.name, movie: m, tmdb: b.tmdb));
        }
      }
    }
    return out;
  }

  /// Clique no banner: filme → player; série → tela de detalhes da série.
  void _openBanner(ResolvedBanner b) {
    if (b.kind == "series" && b.series != null) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SeriesDetailScreen(series: b.series!)));
    } else if (b.movie != null) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => PlayerScreen(item: b.movie!)));
    }
  }

  void _open(MediaItem item) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => PlayerScreen(item: item)));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: SkeletonGrid());
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        BannerRotator(items: _banners, onSelect: _openBanner),
        const SizedBox(height: 24),
        if (_continueWatching.isNotEmpty)
          _row("Continuar Assistindo", _continueWatching, accent: true),
        if (_mostWatched.isNotEmpty)
          _row("Canais Mais Assistidos", _mostWatched),
        if (_history.isNotEmpty) _row("Histórico Recente", _history),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _row(String title, List<MediaItem> items, {bool accent = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                gradient: accent
                    ? AppTheme.accentGradient
                    : const LinearGradient(
                        colors: [AppTheme.gold, Color(0xFFE6B800)]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(title, style: AppTheme.sectionTitle),
            const SizedBox(width: 8),
            Text("${items.length}",
                style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final item = items[i];
              final isVod = item.type != ContentType.live;
              return TVFocusableItem(
                borderRadius: AppTheme.radiusPoster,
                onTap: () => _open(item),
                child: Container(
                  width: 130,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPoster),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      item.logo != null && item.logo!.isNotEmpty
                          ? FastImage(
                              url: item.logo!,
                              width: 130,
                              height: 200,
                              fit: isVod ? BoxFit.cover : BoxFit.contain,
                              httpHeaders: item.headers.isEmpty ? null : item.headers,
                            )
                          : const Center(
                              child: Icon(Icons.play_circle_outline,
                                  size: 36, color: AppTheme.textMuted)),
                      const DecoratedBox(
                          decoration:
                              BoxDecoration(gradient: AppTheme.cardGradient)),
                      if (accent)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: LinearProgressIndicator(
                            value: 0.4,
                            minHeight: 3,
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.accent),
                          ),
                        ),
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 10,
                        child: Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.15),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
