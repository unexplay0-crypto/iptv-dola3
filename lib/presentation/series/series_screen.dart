import 'dart:ui';
import '../../widgets/fast_image.dart';
import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../core/device_config.dart';
import '../../core/models.dart';
import '../../core/storage.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/xtream_api_client.dart';
import '../../widgets/tv_focusable_item.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/virtual_keyboard.dart';
import '../player/player_screen.dart';

/// Séries — pôsteres GRANDES + sidebar de categorias.
class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen>
    with AutomaticKeepAliveClientMixin {
  final _repo = ContentRepository();
  final TextEditingController _searchCtrl = TextEditingController();
  List<String> _groups = [];
  String? _selectedGroup;
  List<SeriesGroup> _allSeries = [];
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
    final groupsFuture = _repo.seriesGroups();
    final seriesFuture = _repo.series();
    final results = await Future.wait([groupsFuture, seriesFuture]);
    _groups = ["Todos", ...(results[0] as List<String>)];
    _allSeries = results[1] as List<SeriesGroup>;
    if (_groups.isNotEmpty) _selectedGroup = _groups.first;
    if (mounted) setState(() => _loading = false);
  }

  List<SeriesGroup> get _filtered {
    final q = _search.trim().toLowerCase();
    return _allSeries.where((s) {
      if (_selectedGroup != null &&
          _selectedGroup != "Todos" &&
          s.group != _selectedGroup) return false;
      if (q.isNotEmpty && !s.name.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: SkeletonGrid());
    final cfg = DeviceConfig.of(context);
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
                  color: AppTheme.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
                ),
                child: Text("${series.length} séries",
                    style: AppTheme.badge
                        .copyWith(color: AppTheme.gold, fontSize: 10)),
              ),
              const Spacer(),
              SizedBox(
                width: cfg.searchWidth,
                height: 44,
                child: AdaptiveSearchField(
                  controller: _searchCtrl,
                  hint: "Buscar serie...",
                  showClear: _search.isNotEmpty,
                  onClear: () {
                    _searchCtrl.clear();
                    setState(() => _search = "");
                  },
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              if (_groups.isNotEmpty)
                Container(
                  width: cfg.sideMenuWidth,
                  margin: EdgeInsets.only(right: cfg.cardSpacing),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withOpacity(0.55),
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
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                            boxShadow: sel
                                ? [
                                    BoxShadow(
                                      color: AppTheme.accent.withOpacity(0.3),
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
                              fontWeight: sel ? FontWeight.w900 : FontWeight.w600,
                              fontSize: 14,
                              height: 1.2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              Expanded(
                child: series.isEmpty
                    ? const Center(
                        child: Text("Nenhuma série encontrada.",
                            style: TextStyle(color: AppTheme.textSecondary)))
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: cfg.posterWidth,
                          childAspectRatio: 0.62,
                          crossAxisSpacing: cfg.cardSpacing,
                          mainAxisSpacing: cfg.cardSpacing,
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
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusPoster),
                                boxShadow: AppTheme.cardShadow,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  s.logo != null && s.logo!.isNotEmpty
                                      ? FastImage(
                                          url: s.logo!,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) => const Center(
                                              child: Icon(Icons.tv_rounded,
                                                  size: 48,
                                                  color: AppTheme.textMuted)),
                                        )
                                      : const Center(
                                          child: Icon(Icons.tv_rounded,
                                              size: 48,
                                              color: AppTheme.textMuted)),
                                  const DecoratedBox(
                                      decoration: BoxDecoration(
                                          gradient: AppTheme.cardGradient)),
                                  Positioned(
                                    left: 10,
                                    right: 10,
                                    bottom: 10,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
          ),
        ),
      ],
    );
  }
}

// ============================================================================
//  Detalhe da série — estilo Google TV:
//   - Fundo: pôster da série desfocado em tela cheia.
//   - Topo: pôster à esquerda + nome/info à direita.
//   - Chips de temporada (roláveis horizontalmente).
//   - Episódios em lista organizada (número, nome, duração, play).
// ============================================================================
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
  String? _error;

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
    if (!mounted) return;
    setState(() {
      _loadingEpisodes = true;
      _error = null;
    });
    try {
      final client = XtreamApiClient(
          dns: creds.dns,
          username: creds.username,
          password: creds.password);
      final eps = await client.fetchSeriesInfo(seriesId);
      if (!mounted) return;
      if (eps.isNotEmpty) {
        setState(() {
          _seasons = eps;
          final nums = eps.keys.toList()..sort();
          _selectedSeason = nums.first;
        });
      } else {
        setState(() => _error =
            "O servidor não retornou episódios para esta série.");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error =
          "Não foi possível carregar os episódios. Verifique a conexão e tente novamente.");
    } finally {
      if (mounted) setState(() => _loadingEpisodes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = DeviceConfig.of(context).isPhone;
    final seasonNums = _seasons.keys.toList()..sort();
    final episodes = (_seasons[_selectedSeason] ?? [])
      ..sort((a, b) => (a.episode ?? 0).compareTo(b.episode ?? 0));
    final posterUrl = widget.series.logo;
    final hasPoster = posterUrl != null && posterUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fundo desfocado (estilo Google TV)
          if (hasPoster)
            FastImage(
              url: posterUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            )
          else
            const DecoratedBox(
                decoration: BoxDecoration(gradient: AppTheme.ambientGradient)),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(DeviceConfig.of(context).overscan / 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra superior: voltar + título
                  Row(children: [
                    TVFocusableItem(
                      autofocus: true,
                      borderRadius: 20,
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
                      ),
                      child: Text(
                          "${seasonNums.length} temp. • ${widget.series.episodeCount} ep.",
                          style: const TextStyle(
                              color: AppTheme.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 18),
                  // Cabeçalho: pôster + info (apenas TV)
                  if (!isPhone)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasPoster)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: FastImage(
                                url: posterUrl,
                                width: 130,
                                height: 195,
                                fit: BoxFit.cover),
                          ),
                        if (hasPoster) const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.series.group.isNotEmpty)
                                Text(widget.series.group,
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text(
                                "Selecione uma temporada abaixo para ver os episódios. Navegue com o controle remoto e pressione OK para reproduzir.",
                                style: TextStyle(
                                    color: AppTheme.textSecondary
                                        .withOpacity(0.8),
                                    fontSize: 13,
                                    height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  if (!isPhone) const SizedBox(height: 18),
                  // Chips de temporada
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
                          final epCount = (_seasons[s] ?? []).length;
                          return TVFocusableItem(
                            borderRadius: 22,
                            onTap: () => setState(() => _selectedSeason = s),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                gradient:
                                    sel ? AppTheme.accentGradient : null,
                                color: sel ? null : Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                    color: sel
                                        ? Colors.transparent
                                        : AppTheme.glassBorder),
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.accent
                                              .withOpacity(0.35),
                                          blurRadius: 14,
                                          offset: const Offset(0, 3),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("Temporada $s",
                                      style: TextStyle(
                                          color: sel
                                              ? Colors.black
                                              : AppTheme.textPrimary,
                                          fontWeight: sel
                                              ? FontWeight.w900
                                              : FontWeight.w700,
                                          fontSize: 14)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? Colors.black.withOpacity(0.2)
                                          : Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text("$epCount",
                                        style: TextStyle(
                                            color: sel
                                                ? Colors.black
                                                : AppTheme.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 14),
                  // Estado de carregamento / erro
                  if (_loadingEpisodes)
                    const Expanded(
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.accent)))
                  else if (_error != null)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary)),
                            const SizedBox(height: 16),
                            TVFocusableItem(
                              borderRadius: AppTheme.radiusMd,
                              onTap: _loadXtreamEpisodes,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.accentGradient,
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusMd),
                                ),
                                child: const Text("Tentar novamente",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (episodes.isEmpty)
                    const Expanded(
                        child: Center(
                            child: Text("Nenhum episódio encontrado.",
                                style: TextStyle(
                                    color: AppTheme.textSecondary))))
                  else
                    // Lista de episódios organizada
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: isPhone ? 400 : 520,
                          mainAxisExtent: isPhone ? 90 : 84,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: episodes.length,
                        itemBuilder: (_, i) {
                          final ep = episodes[i];
                          final num = ep.episode ?? (i + 1);
                          return TVFocusableItem(
                            borderRadius: AppTheme.radiusMd,
                            focusScale: 1.01,
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        PlayerScreen(item: ep))),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusMd),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.accentGradient,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                          color: AppTheme.accent
                                              .withOpacity(0.3),
                                          blurRadius: 8),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text("$num",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                          fontSize: 17)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                            "E$num · ${ep.name}",
                                            maxLines: 2,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                height: 1.2)),
                                        const SizedBox(height: 4),
                                        if (ep.durationSec != null &&
                                            ep.durationSec! > 0)
                                          Text(
                                              "${(ep.durationSec! ~/ 60)} min",
                                              style: const TextStyle(
                                                  color: AppTheme
                                                      .textSecondary,
                                                  fontSize: 12)),
                                      ]),
                                ),
                                const Icon(
                                    Icons.play_circle_fill_rounded,
                                    color: AppTheme.accent,
                                    size: 28),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
