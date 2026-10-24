import '../../widgets/fast_image.dart';
import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../core/device_config.dart';
import '../../core/models.dart';
import '../../core/storage.dart';
import '../../data/repositories/content_repository.dart';
import '../../widgets/tv_focusable_item.dart';
import '../../widgets/skeleton.dart';
import '../player/player_screen.dart';

/// TV Ao Vivo — layout em LISTA (um canal por linha).
/// Performance: todo o catálogo é carregado UMA vez em memória no initState.
/// Trocar de categoria ou buscar filtra em memória (síncrono, sem spinner,
/// sem recarregar do banco) — instantâneo mesmo em TV boxes antigos.
class LiveTvScreen extends StatefulWidget {
  const LiveTvScreen({super.key});

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen>
    with AutomaticKeepAliveClientMixin {
  final _repo = ContentRepository();
  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  List<String> _groups = [];
  String? _selectedGroup;
  List<MediaItem> _allChannels = []; // cache em memória (todos os canais)
  bool _loading = true;
  String _search = "";

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Carga única: grupos + todos os canais em paralelo.
  Future<void> _load() async {
    final groupsFuture = _repo.liveGroups();
    final channelsFuture = _repo.liveChannels(limit: 100000);
    final results = await Future.wait([groupsFuture, channelsFuture]);
    _groups = ["Todos", ...(results[0] as List<String>)];
    _allChannels = results[1] as List<MediaItem>;
    if (_groups.isNotEmpty) _selectedGroup = _groups.first;
    if (mounted) setState(() => _loading = false);
  }

  /// Filtro em memória (síncrono, instantâneo).
  List<MediaItem> get _filtered {
    final q = _search.trim().toLowerCase();
    return _allChannels.where((c) {
      if (_selectedGroup != null &&
          _selectedGroup != "Todos" &&
          c.group != _selectedGroup) return false;
      if (q.isNotEmpty && !c.name.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  void _open(MediaItem ch) {
    AppStorage.instance.addToHistory(ch.id);
    AppStorage.instance.incrementChannelView(ch.id);
    AppStorage.instance.setLastChannel(ch.id);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => PlayerScreen(item: ch)));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: SkeletonGrid());

    final cfg = DeviceConfig.of(context);
    final channels = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
          child: Row(
            children: [
              const Text("TV Ao Vivo", style: AppTheme.titleH1),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.danger.withValues(alpha: 0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                          color: AppTheme.danger, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text("${channels.length} canais",
                      style: AppTheme.badge
                          .copyWith(color: AppTheme.danger, fontSize: 10)),
                ]),
              ),
              const Spacer(),
              // Busca (filtro instantâneo em memória)
              SizedBox(
                width: cfg.searchWidth,
                height: 44,
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Buscar canal...",
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
                width: cfg.sideMenuWidth,
                margin: EdgeInsets.only(right: cfg.cardSpacing),
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
                      onTap: () {
                        // Troca instantânea (filtro em memória, sem recarga)
                        setState(() => _selectedGroup = g);
                        _scroll.jumpTo(0);
                      },
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
              // Lista de canais (um por linha, nome completo sem cortar)
              Expanded(
                child: channels.isEmpty
                    ? const Center(
                        child: Text("Nenhum canal encontrado.",
                            style: TextStyle(color: AppTheme.textSecondary)))
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: channels.length,
                        itemBuilder: (_, i) {
                          final ch = channels[i];
                          final fav = AppStorage.instance.isFavorite(ch.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TVFocusableItem(
                              borderRadius: AppTheme.radiusChannel,
                              focusScale: 1.02,
                              onTap: () => _open(ch),
                              onLongPress: () {
                                AppStorage.instance.toggleFavorite(ch.id);
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface
                                      .withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusChannel),
                                  border: Border.all(
                                      color: Colors.white.withValues(
                                          alpha: 0.04)),
                                ),
                                child: Row(
                                  children: [
                                    // Logo do canal
                                    Container(
                                      width: 76,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: AppTheme.backgroundDeep,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: ch.logo != null &&
                                              ch.logo!.isNotEmpty
                                          ? FastImage(
                                              url: ch.logo!,
                                              fit: BoxFit.contain,
                                              errorWidget: (_, __, ___) =>
                                                  const Icon(
                                                      Icons.live_tv_rounded,
                                                      size: 28,
                                                      color:
                                                          AppTheme.textMuted),
                                            )
                                          : const Center(
                                              child: Icon(
                                                  Icons.live_tv_rounded,
                                                  size: 28,
                                                  color: AppTheme.textMuted)),
                                    ),
                                    const SizedBox(width: 16),
                                    // Nome do canal — ÁREA DEDICADA, SEM CORTAR
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ch.name,
                                            style: AppTheme.channelName,
                                            softWrap: true,
                                            // Sem maxLines: nome aparece completo,
                                            // quebrando linhas conforme necessário.
                                          ),
                                          const SizedBox(height: 5),
                                          Row(children: [
                                            AppTheme.liveBadge(),
                                            const SizedBox(width: 8),
                                            if (ch.quality != null &&
                                                ch.quality!.isNotEmpty)
                                              AppTheme.qualityBadge(
                                                  ch.quality),
                                            const SizedBox(width: 8),
                                            if (ch.group.isNotEmpty)
                                              Expanded(
                                                child: Text(
                                                  ch.group,
                                                  style: AppTheme.channelMeta,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                          ]),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Favorito
                                    if (fav)
                                      const Icon(Icons.favorite,
                                          color: AppTheme.danger, size: 22),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.play_circle_fill_rounded,
                                        color: AppTheme.accent, size: 30),
                                  ],
                                ),
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
