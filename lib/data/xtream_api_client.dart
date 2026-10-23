import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/models.dart';

/// Cliente da API Xtream Codes (player_api.php). Prioritário sobre M3U.
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
      return json["user_info"]?["auth"] == 1 || json["user_info"]?["status"] == "Active";
    } catch (_) {
      return false;
    }
  }

  Future<List<MediaItem>> fetchAll() async {
    final items = <MediaItem>[];
    items.addAll(await _fetchLive());
    items.addAll(await _fetchVod());
    items.addAll(await _fetchSeries());
    return items;
  }

  Future<List<MediaItem>> _fetchLive() async {
    try {
      final resp = await http.get(_action("get_live_streams")).timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) return [];
      final list = jsonDecode(resp.body) as List;
      return list.map((j) => MediaItem(
            id: (j["stream_id"] ?? j["epg_channel_id"] ?? "").toString(),
            name: (j["name"] ?? "").toString(),
            logo: j["stream_icon"]?.toString(),
            group: (j["category_name"] ?? j["category_id"]?.toString() ?? "Geral").toString(),
            url: "$_base/live/$username/$password/${j["stream_id"]}.ts",
            type: ContentType.live,
            tvgId: j["epg_channel_id"]?.toString(),
            isAdult: (j["is_adult"] ?? "0").toString() == "1",
          )).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<MediaItem>> _fetchVod() async {
    try {
      final resp = await http.get(_action("get_vod_streams")).timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) return [];
      final list = jsonDecode(resp.body) as List;
      return list.map((j) => MediaItem(
            id: (j["stream_id"] ?? "").toString(),
            name: (j["name"] ?? "").toString(),
            logo: j["stream_icon"]?.toString(),
            group: (j["category_name"] ?? "Filmes").toString(),
            url: "$_base/movie/$username/$password/${j["stream_id"]}.${j["container_extension"] ?? "mp4"}",
            type: ContentType.movie,
            quality: j["rating_5based"] != null ? null : null,
            isAdult: (j["is_adult"] ?? "0").toString() == "1",
          )).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<MediaItem>> _fetchSeries() async {
    // Busca apenas metadados das séries; episódios carregados sob demanda.
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
          group: (j["category_name"] ?? "Séries").toString(),
          url: "$_base/series/$username/$password/$seriesId",
          type: ContentType.episode,
          seriesKey: name.toLowerCase(),
          isAdult: (j["is_adult"] ?? "0").toString() == "1",
        ));
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  /// Episódios de uma série específica (carregamento sob demanda).
  Future<Map<int, List<MediaItem>>> fetchSeriesInfo(String seriesId) async {
    try {
      final resp = await http
          .get(_action("get_series_info", {"series_id": seriesId}))
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) return {};
      final json = jsonDecode(resp.body);
      final seasons = json["seasons"] as Map? ?? {};
      final episodes = json["episodes"] as List? ?? [];
      final out = <int, List<MediaItem>>{};
      for (final ep in episodes) {
        final season = (ep["season"] ?? 1) as int;
        final num = (ep["episode_num"] ?? 1) as int;
        final ext = (ep["container_extension"] ?? "mp4").toString();
        final id = (ep["id"] ?? "").toString();
        out.putIfAbsent(season, () => []).add(MediaItem(
              id: "ep_$id",
              name: (ep["title"] ?? "Episódio $num").toString(),
              logo: ep["info"]["movie_image"]?.toString(),
              group: "",
              url: "$_base/series/$username/$password/$id.$ext",
              type: ContentType.episode,
              seriesKey: seriesId,
              season: season,
              episode: num,
            ));
      }
      for (final l in out.values) {
        l.sort((a, b) => (a.episode ?? 0).compareTo(b.episode ?? 0));
      }
      return out;
    } catch (_) {
      return {};
    }
  }
}
