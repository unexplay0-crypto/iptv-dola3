import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models.dart';

/// Metadados enriquecidos do TMDB para um item de mídia.
class TmdbInfo {
  final String? backdropUrl; // imagem larga para banner
  final String? posterUrl; // pôster vertical
  final String? overview; // sinopse
  final String? year;
  final double? rating; // 0-10
  final String? title; // título no idioma pt-BR
  const TmdbInfo({
    this.backdropUrl,
    this.posterUrl,
    this.overview,
    this.year,
    this.rating,
    this.title,
  });

  bool get hasBackdrop => backdropUrl != null && backdropUrl!.isNotEmpty;
  bool get hasPoster => posterUrl != null && posterUrl!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        "backdrop": backdropUrl,
        "poster": posterUrl,
        "overview": overview,
        "year": year,
        "rating": rating,
        "title": title,
      };

  static TmdbInfo fromJson(Map<String, dynamic> j) => TmdbInfo(
        backdropUrl: j["backdrop"],
        posterUrl: j["poster"],
        overview: j["overview"],
        year: j["year"],
        rating: (j["rating"] as num?)?.toDouble(),
        title: j["title"],
      );
}

/// Serviço TMDB real (API key configurada).
/// Busca capas (posters), backdrops (imagens largas para banners), sinopse,
/// ano e avaliação. Cache local de 24h para não repetir requisições.
class TmdbService {
  static const apiKey = "32b6d20779ed33fce3b731303f3eccb6";
  static const _base = "https://api.themoviedb.org/3";
  static const _imageBase = "https://image.tmdb.org/t/p";
  static const cacheValidity = Duration(hours: 24);

  static String? _cleanTitle(String name) {
    var s = name.replaceAll(RegExp(r"\s*[Ss]\d{1,2}\s*[Ee]\d{1,3}.*"), "");
    s = s.replaceAll(RegExp(r"\s*[Tt]\d{1,2}\s*[Ee]\d{1,3}.*"), "");
    s = s.replaceAll(RegExp(r"\s*\(\d{4}\).*"), "");
    s = s.replaceAll(
        RegExp(r"\b(4K|2160P|FHD|1080P|HD|720P|SD|480P|DUAL.?AUDIO|DUBLADO|LEGENDADO)\b",
            caseSensitive: false),
        "");
    s = s.replaceAll(RegExp(r"\s+"), " ").trim();
    return s.isEmpty ? null : s;
  }

  static String _yearFromName(String name) {
    final m = RegExp(r"\((\d{4})\)").firstMatch(name);
    return m?.group(1) ?? "";
  }

  /// Busca metadados TMDB para um item (filme ou série). Usa cache local.
  Future<TmdbInfo?> enrich(MediaItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = "tmdb_${item.id}";
    final cached = prefs.getString(cacheKey);
    final cachedTime = prefs.getInt("${cacheKey}_time") ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (cached != null && now - cachedTime < cacheValidity.inMilliseconds) {
      try {
        return TmdbInfo.fromJson(jsonDecode(cached));
      } catch (_) {}
    }

    final query = _cleanTitle(item.name);
    if (query == null) return null;

    try {
      final isSeries =
          item.type == ContentType.episode || item.seriesKey != null;
      final endpoint = isSeries ? "search/tv" : "search/movie";
      final resp = await http
          .get(Uri.parse(
              "$_base/$endpoint?api_key=$apiKey&query=${Uri.encodeComponent(query)}&language=pt-BR&page=1"))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(resp.body);
      final results = json["results"] as List? ?? [];
      if (results.isEmpty) return null;

      final expectedYear = _yearFromName(item.name);
      var best = results.first;
      if (expectedYear.isNotEmpty) {
        for (final r in results) {
          final date =
              (r["release_date"] ?? r["first_air_date"] ?? "").toString();
          if (date.startsWith(expectedYear)) {
            best = r;
            break;
          }
        }
      }

      final backdropPath = best["backdrop_path"]?.toString();
      final posterPath = best["poster_path"]?.toString();
      final info = TmdbInfo(
        backdropUrl:
            backdropPath != null ? "$_imageBase/w1280$backdropPath" : null,
        posterUrl: posterPath != null ? "$_imageBase/w500$posterPath" : null,
        overview: (best["overview"]?.toString().trim().isNotEmpty ?? false)
            ? best["overview"].toString()
            : null,
        year: (best["release_date"] ?? best["first_air_date"] ?? "")
            .toString()
            .substring(0, 4),
        rating: double.tryParse(best["vote_average"]?.toString() ?? ""),
        title: (best["title"] ?? best["name"])?.toString(),
      );

      await prefs.setString(cacheKey, jsonEncode(info.toJson()));
      await prefs.setInt("${cacheKey}_time", now);
      return info;
    } catch (_) {
      return null;
    }
  }

  /// Seleciona até 5 candidatos com logo e enriquece com backdrop do TMDB
  /// para os banners da tela inicial. Retorna lista de {item, tmdb}.
  Future<List<Map<String, dynamic>>> getBanners(
      List<MediaItem> candidates) async {
    final withLogo = candidates
        .where((c) => c.logo != null && c.logo!.isNotEmpty)
        .toList()
      ..shuffle();
    final selected = withLogo.take(8).toList();
    final out = <Map<String, dynamic>>[];
    for (final item in selected) {
      final info = await enrich(item);
      out.add({"item": item, "tmdb": info});
      if (out.length >= 5) break;
    }
    if (out.isEmpty) {
      for (final item in withLogo.take(5)) {
        out.add({"item": item, "tmdb": null});
      }
    }
    return out;
  }
}
