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

/// Séries — pôsteres GRANDES (4 colunas). Catálogo carregado uma vez em
/// memória; busca filtra em memória (sem recarregar, sem spinner).
class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen>
    with AutomaticKeepAliveClientMixin {
  final _repo = ContentRepository();
  final TextEditingController _searchCtrl = TextEditingController();

  List<SeriesGroup> _allSeries = []; // cache em memória
  bool _loading = true;
  String _search = "";

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _allSeries = await _repo.series();
    if (mounted) setState(() => _loading = false);
  }

  List<SeriesGroup> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _allSeries;
    return _allSeries
        .where((s) => s.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: SkeletonGrid());

    final series = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
          child: Row(
            children: [
              const Text("Séries", style: AppTheme.titleH1),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
                ),
                child: Text("${series.length} séries",
                    style: AppTheme.badge
                        .copyWith(color: AppTheme.gold, fontSize: 10)),
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
                    hintText: "Buscar série...",
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
          child: series.isEmpty
              ? const Center(
                  child: Text("Nenhuma série encontrada.",
                      style: TextStyle(color: AppTheme.textSecondary)))
              : GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: series.length,
                  itemBuilder: (_, i) {
                    final s = series[i];
                    return TVFocusableItem(
                      autofocus: i == 0,
                      borderRadius: AppTheme.radiusPoster,
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  SeriesDetailScreen(series: s))),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusPoster),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            s.logo != null && s.logo!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: s.logo!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => const Center(
                                        child: Icon(Icons.tv_rounded,
                                            size: 48,
                                            color: AppTheme.textMuted)),
                                  )
                                : const Center(
                                    child: Icon(Icons.tv_rounded,
                                        size: 48, color: AppTheme.textMuted)),
                            const DecoratedBox(
                                decoration:
                                    BoxDecoration(gradient: AppTheme.cardGradient)),
                            Positioned(
                              left: 10,
                              right: 10,
                              bottom: 10,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.posterTitle,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${s.seasonNumbers.length} temp. • ${s.episodeCount} ep.",
                                    style: AppTheme.posterMeta,
                                  ),
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
    _selectedSeason = widget.series.seasonNumbers.isNotEmpty
        ? widget.series.seasonNumbers.first
        : 1;
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
      final client = XtreamApiClient(
          dns: creds.dns,
          username: creds.username,
          password: creds.password);
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
    final episodes = (_seasons[_selectedSeason] ?? [])
      ..sort((a, b) => (a.episode ?? 0).compareTo(b.episode ?? 0));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF12202E), AppTheme.background],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.overscan / 2),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                TVFocusableItem(
                  autofocus: true,
                  borderRadius: 20,
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: AppTheme.textPrimary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(widget.series.name,
                      style: AppTheme.titleH1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                if (widget.series.logo != null &&
                    widget.series.logo!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                        imageUrl: widget.series.logo!,
                        width: 56,
                        height: 80,
                        fit: BoxFit.cover),
                  ),
              ]),
              const SizedBox(height: 18),
              if (seasonNums.isNotEmpty)
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: seasonNums.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final s = seasonNums[i];
                      final sel = s == _selectedSeason;
                      return TVFocusableItem(
                        borderRadius: 22,
                        onTap: () => setState(() => _selectedSeason = s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 12),
                          decoration: BoxDecoration(
                            gradient:
                                sel ? AppTheme.accentGradient : null,
                            color: sel ? null : AppTheme.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                                color: sel
                                    ? Colors.transparent
                                    : AppTheme.glassBorder),
                            boxShadow: sel
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
                          child: Text("Temporada $s",
                              style: TextStyle(
                                  color: sel
                                      ? Colors.black
                                      : AppTheme.textPrimary,
                                  fontWeight:
                                      sel ? FontWeight.w900 : FontWeight.w600,
                                  fontSize: 14)),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 18),
              if (_loadingEpisodes)
                const Expanded(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.accent)))
              else if (episodes.isEmpty)
                const Expanded(
                    child: Center(
                        child: Text("Nenhum episódio encontrado.",
                            style:
                                TextStyle(color: AppTheme.textSecondary))))
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: episodes.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (_, i) {
                      final ep = episodes[i];
                      final num = ep.episode ?? (i + 1);
                      return TVFocusableItem(
                        borderRadius: AppTheme.radiusMd,
                        focusScale: 1.01,
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => PlayerScreen(item: ep))),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 14),
                          child: Row(children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: AppTheme.accentGradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accent
                                        .withValues(alpha: 0.3),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text("$num",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                      fontSize: 18)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(ep.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15)),
                                    const SizedBox(height: 4),
                                    if (ep.durationSec != null &&
                                        ep.durationSec! > 0)
                                      Text(
                                          "${(ep.durationSec! ~/ 60)} min",
                                          style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12)),
                                  ]),
                            ),
                            const Icon(Icons.play_circle_fill_rounded,
                                color: AppTheme.accent, size: 30),
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
