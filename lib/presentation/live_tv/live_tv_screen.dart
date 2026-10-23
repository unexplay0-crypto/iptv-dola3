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
    _channels = await _repo.liveChannels(group: _selectedGroup, limit: 500);
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
    return Row(children: [
      // Categorias
      Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
        child: ListView.builder(
          itemCount: _groups.length,
          itemBuilder: (_, i) {
            final g = _groups[i];
            final sel = g == _selectedGroup;
            return TVFocusableItem(
              autofocus: i == 0,
              onTap: () async {
                _selectedGroup = g;
                setState(() => _loading = true);
                await _loadChannels();
                setState(() => _loading = false);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.accent.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(g, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: sel ? AppTheme.accent : AppTheme.textPrimary, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
              ),
            );
          },
        ),
      ),
      // Canais
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
            : GridView.builder(
                controller: _scroll,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.9, crossAxisSpacing: 10, mainAxisSpacing: 10),
                itemCount: _channels.length,
                itemBuilder: (_, i) {
                  final ch = _channels[i];
                  final fav = AppStorage.instance.isFavorite(ch.id);
                  return TVFocusableItem(
                    onTap: () => _open(ch),
                    onLongPress: () {
                      AppStorage.instance.toggleFavorite(ch.id);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(fav ? "Removido dos favoritos" : "Adicionado aos favoritos"), duration: const Duration(seconds: 1)));
                    },
                    child: Container(
                      color: AppTheme.surface,
                      padding: const EdgeInsets.all(8),
                      child: Column(children: [
                        Expanded(
                          child: ch.logo != null
                              ? CachedNetworkImage(imageUrl: ch.logo!, fit: BoxFit.contain, errorWidget: (_, __, ___) => const Icon(Icons.tv, size: 40, color: Colors.grey))
                              : const Icon(Icons.tv, size: 40, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Text(ch.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                        if (fav) const Icon(Icons.favorite, color: AppTheme.danger, size: 14),
                      ]),
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}
