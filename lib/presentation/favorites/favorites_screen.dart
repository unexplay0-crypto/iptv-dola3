import '../../widgets/fast_image.dart';
import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../core/device_config.dart';
import '../../core/models.dart';
import '../../core/storage.dart';
import '../../data/repositories/content_repository.dart';
import '../../widgets/tv_focusable_item.dart';
import '../movies/movie_detail_screen.dart';

/// Favoritos — grid de pôsteres grandes (4 colunas).
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with AutomaticKeepAliveClientMixin {
  List<MediaItem> _items = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
    if (_loading)
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accent));
    if (_items.isEmpty) {
      return const Center(
          child: Text(
              "Nenhum favorito ainda. Segure OK sobre um item para favoritar.",
              style: TextStyle(color: AppTheme.textSecondary)));
    }
    final cfg = DeviceConfig.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 0, 4, 14),
          child: Text("Favoritos", style: AppTheme.titleH1),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: cfg.posterWidth,
              childAspectRatio: 0.62,
              crossAxisSpacing: cfg.cardSpacing,
              mainAxisSpacing: cfg.cardSpacing,
            ),
            itemCount: _items.length,
            itemBuilder: (_, i) {
              final item = _items[i];
              final isVod = item.type != ContentType.live;
              return TVFocusableItem(
                autofocus: i == 0,
                borderRadius: AppTheme.radiusPoster,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MovieDetailScreen(movie: item))),
                onLongPress: () {
                  AppStorage.instance.toggleFavorite(item.id);
                  _load();
                },
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
                      item.logo != null && item.logo!.isNotEmpty
                          ? FastImage(
                              url: item.logo!,
                              fit: isVod ? BoxFit.cover : BoxFit.contain,
                              httpHeaders:
                                  item.headers.isEmpty ? null : item.headers,
                              errorWidget: (_, __, ___) => const Center(
                                  child: Icon(Icons.star,
                                      size: 40, color: AppTheme.textMuted)),
                            )
                          : const Center(
                              child: Icon(Icons.star,
                                  size: 40, color: AppTheme.textMuted)),
                      const DecoratedBox(
                          decoration:
                              BoxDecoration(gradient: AppTheme.cardGradient)),
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(Icons.favorite,
                            color: AppTheme.danger, size: 20),
                      ),
                      if (item.quality != null && item.quality!.isNotEmpty)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: AppTheme.qualityBadge(item.quality),
                        ),
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.posterTitle,
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
