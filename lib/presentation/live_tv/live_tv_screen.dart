import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app_theme.dart';
import '../../core/models.dart';
import '../../core/storage.dart';
import '../../data/repositories/content_repository.dart';
import '../../widgets/tv_focusable_item.dart';
import '../../widgets/skeleton.dart';
import '../player/player_screen.dart';

class LiveTvScreen extends StatefulWidget {
  const LiveTvScreen({super.key});

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen> {
  final _repo = ContentRepository();
  List<String> _groups = [];
  String? _selectedGroup;
  List<MediaItem> _channels = [];
  bool _loading = true;
  String _search = "";
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    _groups = await _repo.liveGroups();
    if (_groups.isNotEmpty) {
      _selectedGroup = _groups.first;
      await _loadChannels();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadChannels() async {
    _channels = await _repo.liveChannels(
      group: _selectedGroup,
      limit: 1000,
      search: _search.isEmpty ? null : _search,
    );
    if (mounted) setState(() {});
  }

  void _open(MediaItem ch) {
    AppStorage.instance.addToHistory(ch.id);
    AppStorage.instance.incrementChannelView(ch.id);
    AppStorage.instance.setLastChannel(ch.id);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(item: ch)));
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
              const Text("TV Ao Vivo", style: AppTheme.titleH1),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text("${_channels.length} ao vivo", style: AppTheme.badge.copyWith(color: AppTheme.danger)),
                ]),
              ),
              const Spacer(),
              SizedBox(
                width: 260,
                height: 40,
                child: TextField(
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Buscar canal...",
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
                    await _loadChannels();
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
                        await _loadChannels();
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
                        controller: _scroll,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.95, crossAxisSpacing: 12, mainAxisSpacing: 12),
                        itemCount: _channels.length,
                        itemBuilder: (_, i) {
                          final ch = _channels[i];
                          final fav = AppStorage.instance.isFavorite(ch.id);
                          return TVFocusableItem(
                            borderRadius: AppTheme.radiusLg,
                            onTap: () => _open(ch),
                            onLongPress: () {
                              AppStorage.instance.toggleFavorite(ch.id);
                              setState(() {});
                            },
                            child: Container(
                              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                              padding: const EdgeInsets.all(10),
                              child: Stack(
                                children: [
                                  Column(
                                    children: [
                                      Expanded(
                                        child: Center(
                                          child: ch.logo != null && ch.logo!.isNotEmpty
                                              ? CachedNetworkImage(imageUrl: ch.logo!, fit: BoxFit.contain, errorWidget: (_, __, ___) => const Icon(Icons.live_tv_rounded, size: 42, color: AppTheme.textMuted))
                                              : const Icon(Icons.live_tv_rounded, size: 42, color: AppTheme.textMuted),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(ch.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      AppTheme.qualityBadge(ch.quality),
                                    ],
                                  ),
                                  if (fav) const Positioned(top: 4, right: 4, child: Icon(Icons.favorite, color: AppTheme.danger, size: 16)),
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
