import 'package:shared_preferences/shared_preferences.dart';
import '../core/models.dart';

/// Serviço de sugestões de destaque (match com a lista do usuário).
/// Sem chave de API configurada, seleciona itens do próprio catálogo
/// com logo, com cache de 24h.
class TmdbService {
  static const _kCache = "tmdb_banners";
  static const _kCacheTime = "tmdb_banners_time";
  static const cacheValidity = Duration(hours: 24);

  /// Retorna até 5 itens para destaque. Usa cache de IDs válido por 24h;
  /// resolve os IDs contra os candidatos atuais (nunca retorna vazio se
  /// houver candidatos com logo).
  Future<List<MediaItem>> getBanners(List<MediaItem> candidates) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedTime = prefs.getInt(_kCacheTime) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final withLogo =
        candidates.where((c) => c.logo != null && c.logo!.isNotEmpty).toList();

    if (now - cachedTime < cacheValidity.inMilliseconds) {
      final cachedIds = prefs.getStringList(_kCache);
      if (cachedIds != null && cachedIds.isNotEmpty) {
        final byId = {for (final c in withLogo) c.id: c};
        final resolved =
            cachedIds.where((id) => byId.containsKey(id)).map((id) => byId[id]!).toList();
        if (resolved.isNotEmpty) return resolved;
        // cache aponta para itens que não existem mais → renova
      }
    }

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
