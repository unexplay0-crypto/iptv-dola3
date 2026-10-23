import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app_theme.dart';
import '../../core/models.dart';
import '../../core/storage.dart';
import '../../data/repositories/content_repository.dart';
import '../../widgets/tv_focusable_item.dart';
import '../player/player_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<MediaItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = AppStorage.instance.favorites.toList();
    _items = await ContentRepository().byIds(ids);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    if (_items.isEmpty) {
      return const Center(child: Text("Nenhum favorito ainda. Segure OK sobre um canal para favoritar.", style: TextStyle(color: AppTheme.textSecondary)));
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.8, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: _items.length,
      itemBuilder: (_, i) {
        final item = _items[i];
        return TVFocusableItem(
          autofocus: i == 0,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(item: item))),
          onLongPress: () {
            AppStorage.instance.toggleFavorite(item.id);
            _load();
          },
          child: Container(color: AppTheme.surface, padding: const EdgeInsets.all(8), child: Column(children: [
            Expanded(child: item.logo != null ? CachedNetworkImage(imageUrl: item.logo!, fit: BoxFit.contain, errorWidget: (_, __, ___) => const Icon(Icons.star, color: Colors.grey)) : const Icon(Icons.star, color: Colors.grey)),
            const SizedBox(height: 6),
            Text(item.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
          ])),
        );
      },
    );
  }
}
