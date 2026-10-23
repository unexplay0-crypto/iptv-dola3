import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app_theme.dart';
import '../../core/models.dart';
import '../../core/storage.dart';
import '../../data/repositories/content_repository.dart';
import '../../widgets/tv_focusable_item.dart';
import '../player/player_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<MediaItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = AppStorage.instance.history;
    _items = await ContentRepository().byIds(ids);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    if (_items.isEmpty) {
      return const Center(child: Text("Histórico vazio.", style: TextStyle(color: AppTheme.textSecondary)));
    }
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white10),
      itemBuilder: (_, i) {
        final item = _items[i];
        final progress = AppStorage.instance.progressFor(item.id);
        return TVFocusableItem(
          autofocus: i == 0,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(item: item))),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(children: [
              Container(width: 60, height: 60, color: AppTheme.surface, child: item.logo != null ? CachedNetworkImage(imageUrl: item.logo!, fit: BoxFit.cover) : const Icon(Icons.history, color: Colors.grey)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                if (progress != null) LinearProgressIndicator(value: (progress / 100 / 60 / 1000).clamp(0.0, 1.0), backgroundColor: Colors.white12, color: AppTheme.accent, minHeight: 3),
              ])),
              const Icon(Icons.play_arrow, color: AppTheme.textSecondary),
            ]),
          ),
        );
      },
    );
  }
}
