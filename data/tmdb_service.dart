import 'package:shared_preferences/shared_preferences.dart';
import '../core/models.dart';

/// Serviço de sugestões TMDB (match fuzzy com a lista do usuário).
/// Sem chave de API configurada, usa os próprios itens do catálogo como
/// "destaques" (cache de 24h).
class TmdbService {
  static const _kCache = "tmdb_banners";
  static const _kCacheTime = "tmdb_banners_time";
  static const cacheValidity = Duration(hours: 24);

  Future<List<MediaItem>> getBanners(List<MediaItem> candidates) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedTime = prefs.getInt(_kCacheTime) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - cachedTime < cacheValidity.inMilliseconds) {
      final cached = prefs.getStringList(_kCache);
      if (cached != null && cached.isNotEmpty) {
        // banners cacheados por id; resolução feita pelo repositório
        return [];
      }
    }
    // Seleciona até 5 candidatos com logo (filmes/séries) como destaque
    final withLogo = candidates.where((c) => c.logo != null && c.logo!.isNotEmpty).toList();
    withLogo.shuffle();
    final selected = withLogo.take(5).toList();
    await prefs.setStringList(_kCache, selected.map((e) => e.id).toList());
    await prefs.setInt(_kCacheTime, now);
    return selected;
  }

  Future<List<String>?> cachedBannerIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kCache);
  }
}
