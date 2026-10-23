import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app_theme.dart';
import '../../core/models.dart';
import '../../core/storage.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/xtream_api_client.dart';
import '../../widgets/tv_focusable_item.dart';
import '../../widgets/skeleton.dart';
import '../player/player_screen.dart';

class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  final _repo = ContentRepository();
  List<SeriesGroup> _series = [];
  bool _loading = true;
  String _search = "";

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _series = await _repo.series(search: _search.isEmpty ? null : _search);
    if (mounted) setState(() => _loading = false);
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
              const Text("Séries", style: AppTheme.titleH1),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text("${_series.length} séries", style: AppTheme.badge.copyWith(color: AppTheme.gold)),
              ),
              const Spacer(),
              SizedBox(
                width: 260,
                height: 40,
                child: TextField(
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Buscar série...",
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
                    setState(() => _loading = true);
                    await _load();
                    setState(() => _loading = false);
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, childAspectRatio: 0.58, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemCount: _series.length,
            itemBuilder: (_, i) {
              final s = _series[i];
              return TVFocusableItem(
                autofocus: i == 0,
                borderRadius: AppTheme.radiusLg,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SeriesDetailScreen(series: s))),
                child: Container(
                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      s.logo != null && s.logo!.isNotEmpty
                          ? CachedNetworkImage(imageUrl: s.logo!, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Center(child: Icon(Icons.tv_rounded, size: 40, color: AppTheme.textMuted)))
                          : const Center(child: Icon(Icons.tv_rounded, size: 40, color: AppTheme.textMuted)),
                      const DecoratedBox(decoration: BoxDecoration(gradient: AppTheme.cardGradient)),
                      Positioned(
                        left: 8, right: 8, bottom: 8,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text("${s.seasonNumbers.length} temp. • ${s.episodeCount} ep.", style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                        ]),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Detalhe da série: abas de temporada + episódios numerados em ordem crescente.
/// Séries Xtream carregam episódios sob demanda via fetchSeriesInfo.
class SeriesDetailScreen extends StatefulWidget {
  final SeriesGroup series;
  const SeriesDetailScreen({super.key, required this.series});

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  late Map<int, List<MediaItem>> _seasons;
  late int _selectedSeason;
  bool _loadingEpisodes = false;

  @override
  void initState() {
    super.initState();
    _seasons = widget.series.seasons;
    _selectedSeason = widget.series.seasonNumbers.isNotEmpty ? widget.series.seasonNumbers.first : 1;
    if (_seasons.isEmpty) _loadXtreamEpisodes();
  }

  Future<void> _loadXtreamEpisodes() async {
    final key = widget.series.key;
    if (!key.startsWith("xtream_")) return;
    final seriesId = key.replaceFirst("xtream_", "");
    final creds = AppStorage.instance.credentials;
    if (creds.dns.isEmpty || creds.username.isEmpty) return;
    setState(() => _loadingEpisodes = true);
    try {
      final client = XtreamApiClient(dns: creds.dns, username: creds.username, password: creds.password);
      final eps = await client.fetchSeriesInfo(seriesId);
      if (eps.isNotEmpty) {
        _seasons = eps;
        final nums = eps.keys.toList()..sort();
        _selectedSeason = nums.first;
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingEpisodes = false);
  }

  @override
  Widget build(BuildContext context) {
    final seasonNums = _seasons.keys.toList()..sort();
    final episodes = (_seasons[_selectedSeason] ?? [])..sort((a, b) => (a.episode ?? 0).compareTo(b.episode ?? 0));
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF12202E), AppTheme.background], stops: [0.0, 0.4])),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.overscan / 2),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                TVFocusableItem(
                  autofocus: true,
                  borderRadius: 20,
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.arrow_back, color: AppTheme.textPrimary)),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(widget.series.name, style: AppTheme.titleH1, maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (widget.series.logo != null && widget.series.logo!.isNotEmpty)
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: widget.series.logo!, width: 50, height: 70, fit: BoxFit.cover)),
              ]),
              const SizedBox(height: 16),
              if (seasonNums.isNotEmpty)
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: seasonNums.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final s = seasonNums[i];
                      final sel = s == _selectedSeason;
                      return TVFocusableItem(
                        borderRadius: 20,
                        onTap: () => setState(() => _selectedSeason = s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(gradient: sel ? AppTheme.accentGradient : null, color: sel ? null : AppTheme.surface, borderRadius: BorderRadius.circular(20)),
                          child: Text("Temporada $s", style: TextStyle(color: sel ? Colors.black : AppTheme.textPrimary, fontWeight: sel ? FontWeight.w800 : FontWeight.w500)),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              if (_loadingEpisodes)
                const Expanded(child: Center(child: CircularProgressIndicator(color: AppTheme.accent)))
              else if (episodes.isEmpty)
                const Expanded(child: Center(child: Text("Nenhum episódio encontrado.", style: TextStyle(color: AppTheme.textSecondary))))
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: episodes.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (_, i) {
                      final ep = episodes[i];
                      final num = ep.episode ?? (i + 1);
                      return TVFocusableItem(
                        borderRadius: AppTheme.radiusMd,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(item: ep))),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          child: Row(children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(10)),
                              alignment: Alignment.center,
                              child: Text("$num", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 16)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(ep.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                if (ep.durationSec != null && ep.durationSec! > 0) Text("${(ep.durationSec! ~/ 60)} min", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              ]),
                            ),
                            const Icon(Icons.play_circle_fill_rounded, color: AppTheme.accent, size: 28),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
