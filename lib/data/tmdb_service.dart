import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models.dart';

/// Metadados enriquecidos do TMDB para um item de mídia.
/// O TMDB é usado EXCLUSIVAMENTE para metadados: título correto, data de
/// lançamento, sinopse, duração, pôster/backdrop e avaliação.
/// A SELEÇÃO do que recomendar nos banners NÃO usa TMDB — fica a cargo do
/// TrendingService (fontes de mercado de popularidade + match com catálogo).
class TmdbInfo {
  final String? backdropUrl; // imagem larga para banner
  final String? posterUrl; // pôster vertical
  final String? overview; // sinopse
  final String? year; // ano de lançamento
  final String? releaseDate; // data completa de lançamento
  final double? rating; // 0-10
  final String? title; // título no idioma pt-BR
  final int? runtimeMinutes; // duração em minutos
  const TmdbInfo({
    this.backdropUrl,
    this.posterUrl,
    this.overview,
    this.year,
    this.releaseDate,
    this.rating,
    this.title,
    this.runtimeMinutes,
  });
  bool get hasBackdrop => backdropUrl != null && backdropUrl!.isNotEmpty;
  bool get hasPoster => posterUrl != null && posterUrl!.isNotEmpty;
  Map<String, dynamic> toJson() => {
        "backdrop": backdropUrl,
        "poster": posterUrl,
        "overview": overview,
        "year": year,
        "releaseDate": releaseDate,
        "rating": rating,
        "title": title,
        "runtime": runtimeMinutes,
      };
  static TmdbInfo fromJson(Map<String, dynamic> j) => TmdbInfo(
        backdropUrl: j["backdrop"],
        posterUrl: j["poster"],
        overview: j["overview"],
        year: j["year"],
        releaseDate: j["releaseDate"],
        rating: (j["rating"] as num?)?.toDouble(),
        title: j["title"],
        runtimeMinutes: (j["runtime"] as num?)?.toInt(),
      );
}

/// Serviço TMDB (metadados apenas).
/// Otimização de velocidade: imagens baixadas em tamanho reduzido
/// (backdrop w780 em vez de w1280, pôster w300 em vez de w500) — ~3x menos
/// bytes por imagem, carregamento perceptivelmente mais rápido. Cache 24h.
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
        RegExp(
            r"\b(4K|2160P|FHD|1080P|HD|720P|SD|480P|DUAL.?AUDIO|DUBLADO|LEGENDADO)\b",
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
      final tmdbId = best["id"];
      final releaseDate =
          (best["release_date"] ?? best["first_air_date"] ?? "").toString();
      // Duração: requer chamada extra ao detalhe (best-effort, timeout curto).
      int? runtime;
      if (tmdbId != null) {
        runtime = await _fetchRuntime(
            isSeries ? "tv/$tmdbId" : "movie/$tmdbId");
      }
      final info = TmdbInfo(
        backdropUrl:
            backdropPath != null ? "$_imageBase/w780$backdropPath" : null,
        posterUrl: posterPath != null ? "$_imageBase/w300$posterPath" : null,
        overview: (best["overview"]?.toString().trim().isNotEmpty ?? false)
            ? best["overview"].toString()
            : null,
        year: releaseDate.length >= 4 ? releaseDate.substring(0, 4) : null,
        releaseDate: releaseDate.isNotEmpty ? releaseDate : null,
        rating: double.tryParse(best["vote_average"]?.toString() ?? ""),
        title: (best["title"] ?? best["name"])?.toString(),
        runtimeMinutes: runtime,
      );
      await prefs.setString(cacheKey, jsonEncode(info.toJson()));
      await prefs.setInt("${cacheKey}_time", now);
      return info;
    } catch (_) {
      return null;
    }
  }

  /// Busca duração (runtime) no endpoint de detalhe. Best-effort.
  Future<int?> _fetchRuntime(String detailPath) async {
    try {
      final resp = await http
          .get(Uri.parse(
              "$_base/$detailPath?api_key=$apiKey&language=pt-BR"))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode != 200) return null;
      final j = jsonDecode(resp.body);
      final rt = j["runtime"];
      if (rt is num && rt > 0) return rt.toInt();
      // Para séries: usa episode_run_time[0]
      final eps = j["episode_run_time"];
      if (eps is List && eps.isNotEmpty && eps[0] is num) {
        return (eps[0] as num).toInt();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
