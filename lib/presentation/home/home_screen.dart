import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app_theme.dart';
import '../../core/models.dart';
import '../../core/storage.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/tmdb_service.dart';
import '../../widgets/banner_rotator.dart';
import '../../widgets/tv_focusable_item.dart';
import '../../widgets/skeleton.dart';
import '../player/player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = ContentRepository();
  final _tmdb = TmdbService();
  List<MediaItem> _banners = [];
  List<MediaItem> _continueWatching = [];
  List<MediaItem> _history = [];
  List<MediaItem> _mostWatched = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final movies = await _repo.movies(limit: 50);
      final series = await _repo.itemsByTypeSeriesHack();
      final candidates = [...movies, ...series];
      _banners = await _tmdb.getBanners(candidates);

      final storage = AppStorage.instance;
      // Continuar assistindo (VOD com progresso)
      final progressIds = storage.vodProgress.keys.toList().take(10).toList();
      _continueWatching = await _repo.byIds(progressIds);
      // Histórico de canais
      _history = await _repo.byIds(storage.history.take(10).toList());
      // Canais mais assistidos
      final views = storage.channelViews;
      final sorted = views.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      _mostWatched = await _repo.byIds(sorted.take(10).map((e) => e.key).toList());
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _open(MediaItem item) {
    if (item.isAdult && !AppStorage.instance.adultUnlocked) {
      // será tratado no player; aqui só navega
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(item: item)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: SkeletonGrid());
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        BannerRotator(items: _banners, onSelect: _open),
        const SizedBox(height: 20),
        if (_continueWatching.isNotEmpty) _row("Continuar Assistindo", _continueWatching),
        if (_mostWatched.isNotEmpty) _row("Canais Mais Assistidos", _mostWatched),
        if (_history.isNotEmpty) _row("Histórico Recente", _history),
      ]),
    );
  }

  Widget _row(String title, List<MediaItem> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => TVFocusableItem(
              onTap: () => _open(items[i]),
              child: Container(
                width: 220,
                color: AppTheme.surface,
                child: Row(children: [
                  if (items[i].logo != null)
                    CachedNetworkImage(imageUrl: items[i].logo!, width: 80, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.image, color: Colors.grey))
                  else
                    const SizedBox(width: 80, child: Icon(Icons.play_circle_outline, color: Colors.grey)),
                  Expanded(child: Padding(padding: const EdgeInsets.all(8), child: Text(items[i].name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

extension on ContentRepository {
  Future<List<MediaItem>> itemsByTypeSeriesHack() async {
    final series = await allSeriesKeys();
    return byIds(series);
  }
  Future<List<String>> allSeriesKeys() async {
    final s = await series();
    return s.map((e) => "series_${e.key}").toList();
  }
}
