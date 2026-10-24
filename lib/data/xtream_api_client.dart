import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/models.dart';
import '../core/storage.dart';

/// Cliente da API Xtream Codes (player_api.php). Prioritário sobre M3U.
/// Busca primeiro os nomes das categorias (get_*_categories) para nunca
/// exibir IDs numéricos no lugar dos nomes.
class XtreamApiClient {
  final String dns; // ex: http://servidor.com:8080
  final String username;
  final String password;

  XtreamApiClient({required this.dns, required this.username, required this.password});

  String get _base => dns.endsWith("/") ? dns.substring(0, dns.length - 1) : dns;

  Uri _action(String action, [Map<String, String> extra = const {}]) {
    final params = {
      "username": username,
      "password": password,
      "action": action,
      ...extra,
    };
    return Uri.parse("$_base/player_api.php").replace(queryParameters: params);
  }

  Future<bool> authenticate() async {
    try {
      final resp = await http
          .get(Uri.parse("$_base/player_api.php?username=$username&password=$password"))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return false;
      final json = jsonDecode(resp.body);
      final userInfo = json["user_info"];
      if (userInfo is Map) {
        final auth = userInfo["auth"]?.toString();
        final status = userInfo["status"]?.toString().toLowerCase();
        // Captura data de vencimento (exp_date = timestamp Unix em segundos)
        final expSec = int.tryParse(userInfo["exp_date"]?.toString() ?? "");
        if (expSec != null && expSec > 0) {
          await AppStorage.instance.setExpiryDateMillis(expSec * 1000);
        } else {
          await AppStorage.instance.setExpiryDateMillis(null);
        }
        if (auth == "0") return false;
        if (status != null && {"disabled", "banned", "expired", "inactive"}.contains(status)) {
          return false;
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Busca um mapa category_id -> category_name para um tipo de categoria.
  Future<Map<String, String>> _categoryNames(String action) async {
    final map = <String, String>{};
    try {
      final resp = await http.get(_action(action)).timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) return map;
      final list = jsonDecode(resp.body) as List;
      for (final j in list) {
        final id = (j["category_id"] ?? "").toString();
        final name = (j["category_name"] ?? "").toString().trim();
        if (id.isNotEmpty && name.isNotEmpty) map[id] = name;
      }
    } catch (_) {}
    return map;
  }

  Future<List<MediaItem>> fetchAll() async {
    final items = <MediaItem>[];
    final liveCats = await _categoryNames("get_live_categories");
    final vodCats = await _categoryNames("get_vod_categories");
    final seriesCats = await _categoryNames("get_series_categories");
    items.addAll(await _fetchLive(liveCats));
    items.addAll(await _fetchVod(vodCats));
    items.addAll(await _fetchSeries(seriesCats));
    return items;
  }

  String _resolveGroup(Map<String, String> catMap, dynamic categoryId, dynamic categoryName, String fallback) {
    final name = (categoryName ?? "").toString().trim();
    if (name.isNotEmpty) return name;
    final id = (categoryId ?? "").toString();
    if (id.isNotEmpty && catMap.containsKey(id)) return catMap[id]!;
    if (id.isNotEmpty) return id; // último recurso, mas raro
    return fallback;
  }

  Future<List<MediaItem>> _fetchLive(Map<String, String> catMap) async {
    try {
      final resp = await http.get(_action("get_live_streams")).timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) return [];
      final list = jsonDecode(resp.body) as List;
      return list.map((j) {
        final sid = (j["stream_id"] ?? "").toString();
        return MediaItem(
          id: sid.isNotEmpty ? sid : (j["epg_channel_id"] ?? "").toString(),
          name: (j["name"] ?? "").toString(),
          logo: j["stream_icon"]?.toString(),
          group: _resolveGroup(catMap, j["category_id"], j["category_name"], "Canais"),
          url: "$_base/live/$username/$password/$sid.ts",
          headers: const {},
          type: ContentType.live,
          tvgId: j["epg_channel_id"]?.toString(),
          isAdult: (j["is_adult"] ?? "0").toString() == "1",
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<MediaItem>> _fetchVod(Map<String, String> catMap) async {
    try {
      final resp = await http.get(_action("get_vod_streams")).timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) return [];
      final list = jsonDecode(resp.body) as List;
      return list.map((j) {
        final sid = (j["stream_id"] ?? "").toString();
        final ext = (j["container_extension"] ?? "mp4").toString();
        return MediaItem(
          id: sid,
          name: (j["name"] ?? "").toString(),
          logo: j["stream_icon"]?.toString(),
          group: _resolveGroup(catMap, j["category_id"], j["category_name"], "Filmes"),
          url: "$_base/movie/$username/$password/$sid.$ext",
          headers: const {},
          type: ContentType.movie,
          quality: _qualityFromRating(j["rating_5based"]),
          isAdult: (j["is_adult"] ?? "0").toString() == "1",
          durationSec: int.tryParse((j["duration"] ?? "0").toString()),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<MediaItem>> _fetchSeries(Map<String, String> catMap) async {
    // Metadados das séries; episódios carregados sob demanda via fetchSeriesInfo.
    try {
      final resp = await http.get(_action("get_series")).timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) return [];
      final list = jsonDecode(resp.body) as List;
      final out = <MediaItem>[];
      for (final j in list) {
        final seriesId = (j["series_id"] ?? "").toString();
        final name = (j["name"] ?? "").toString();
        out.add(MediaItem(
          id: "series_$seriesId",
          name: name,
          logo: j["cover"]?.toString(),
          group: _resolveGroup(catMap, j["category_id"], j["category_name"], "Séries"),
          url: "$_base/series/$username/$password/$seriesId",
          headers: const {},
          type: ContentType.episode,
          seriesKey: "xtream_$seriesId",
          isAdult: (j["is_adult"] ?? "0").toString() == "1",
        ));
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  /// Converte valor dinâmico (int ou String, com zeros à esquerda) para int.
  /// Nunca lança — usa [fallback] em caso de falha de parse.
  static int _toInt(dynamic v, int fallback) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.toInt();
    final s = v.toString().trim();
    if (s.isEmpty) return fallback;
    final parsed = int.tryParse(s);
    if (parsed != null) return parsed;
    final d = double.tryParse(s);
    if (d != null) return d.toInt();
    return fallback;
  }

  /// Episódios de uma série específica (carregamento sob demanda).
  /// Retorna mapa season -> lista de episódios ordenada por número ascendente.
  ///
  /// Robustez (corrige falha silenciosa que zerava as temporadas):
  ///  - season/episode_num/id podem vir como int OU String (com zeros à
  ///    esquerda) — parse via [_toInt], sem cast `as int` que quebrava.
  ///  - `episodes` pode vir como Lista plana OU como Map<season, List>
  ///    (variação comum entre painéis Xtream) — ambos os formatos aceitos.
  ///  - Até 2 tentativas com timeout maior (30s).
  Future<Map<int, List<MediaItem>>> fetchSeriesInfo(String seriesId) async {
    Exception? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final resp = await http
            .get(_action("get_series_info", {"series_id": seriesId}))
            .timeout(const Duration(seconds: 30));
        if (resp.statusCode != 200) {
          lastError = Exception("HTTP ${resp.statusCode}");
          continue;
        }
        final dynamic json = jsonDecode(resp.body);
        if (json is! Map) return {};
        final dynamic episodes = json["episodes"];
        final out = <int, List<MediaItem>>{};
        void addEpisode(dynamic ep, {int? seasonHint}) {
          if (ep is! Map) return;
          final season = seasonHint ?? _toInt(ep["season"], 1);
          final num = _toInt(ep["episode_num"], _toInt(ep["episode"], 1));
          final ext = (ep["container_extension"]?.toString().trim().isNotEmpty ?? false)
              ? ep["container_extension"].toString()
              : "mp4";
          final id = (ep["id"]?.toString().trim().isNotEmpty ?? false)
              ? ep["id"].toString()
              : "s${season}e$num";
          final info = ep["info"] is Map ? ep["info"] as Map : const {};
          final title = (ep["title"]?.toString().trim().isNotEmpty ?? false)
              ? ep["title"].toString()
              : (info["title"]?.toString().trim().isNotEmpty ?? false)
                  ? info["title"].toString()
                  : "Episódio $num";
          final logo = info["movie_image"]?.toString() ?? ep["cover"]?.toString() ?? ep["stream_icon"]?.toString();
          out.putIfAbsent(season, () => []).add(MediaItem(
                id: "ep_$id",
                name: title,
                logo: (logo?.isNotEmpty ?? false) ? logo : null,
                group: "",
                url: "$_base/series/$username/$password/$id.$ext",
                headers: const {},
                type: ContentType.episode,
                seriesKey: "xtream_$seriesId",
                season: season,
                episode: num,
                durationSec: int.tryParse((info["duration"] ?? "0").toString()),
              ));
        }
        if (episodes is List) {
          for (final ep in episodes) {
            addEpisode(ep);
          }
        } else if (episodes is Map) {
          // Formato alternativo: {"1": [ep1, ep2], "2": [...]}
          episodes.forEach((k, v) {
            final season = _toInt(k, 1);
            if (v is List) {
              for (final ep in v) {
                addEpisode(ep, seasonHint: season);
              }
            } else {
              addEpisode(v, seasonHint: season);
            }
          });
        }
        // Remove temporadas sem episódios e ordena cada uma.
        out.removeWhere((_, l) => l.isEmpty);
        for (final l in out.values) {
          l.sort((a, b) => (a.episode ?? 0).compareTo(b.episode ?? 0));
        }
        return out;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }
    // Falhou após tentativas — propaga para a UI mostrar erro/retry.
    if (lastError != null) throw lastError;
    return {};
  }

  String? _qualityFromRating(dynamic rating) {
    final r = double.tryParse(rating?.toString() ?? "");
    if (r == null) return null;
    if (r >= 4.5) return "4K";
    if (r >= 3.5) return "FHD";
    if (r >= 2.5) return "HD";
    return "SD";
  }
}
