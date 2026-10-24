import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models.dart';
import '../db/database.dart';
import 'tmdb_service.dart';

/// Título em alta ("trending") obtido de uma fonte externa de mercado.
class TrendingTitle {
  final String title; // título original
  final String kind; // "movie" ou "show" (série)
  final int rank; // ordem de popularidade (menor = mais popular)
  const TrendingTitle(
      {required this.title, required this.kind, required this.rank});
}

/// Banner de recomendação resolvido: item EXISTENTE no catálogo local +
/// metadados TMDB (backdrop/título/sinopse/ano/nota) para exibição.
/// Garantia: [itemId] sempre existe no catálogo conectado no momento do match.
class MatchedBanner {
  final String kind; // "movie" ou "series"
  final String itemId; // id do MediaItem (movie) ou seriesKey (série)
  final String displayName;
  final TmdbInfo? tmdb;
  const MatchedBanner({
    required this.kind,
    required this.itemId,
    required this.displayName,
    this.tmdb,
  });
  Map<String, dynamic> toJson() => {
        "kind": kind,
        "itemId": itemId,
        "displayName": displayName,
        "tmdb": tmdb?.toJson(),
      };
  static MatchedBanner fromJson(Map<String, dynamic> j) => MatchedBanner(
        kind: j["kind"]?.toString() ?? "movie",
        itemId: j["itemId"]?.toString() ?? "",
        displayName: j["displayName"]?.toString() ?? "",
        tmdb: j["tmdb"] is Map ? TmdbInfo.fromJson(j["tmdb"] as Map<String, dynamic>) : null,
      );
}

/// Normaliza título para matching: minúsculas, remove ano, tags de qualidade,
/// pontuação e espaços extras. Mesma família de limpeza usada no parser M3U.
String normalizeTitle(String raw) {
  var s = raw.toLowerCase().trim();
  s = s.replaceAll(RegExp(r"[\[\(]\d{4}[\]\)]"), " ");
  s = s.replaceAll(
      RegExp(
          r"\b(4k|2160p|fhd|1080p|hd|720p|sd|480p|dual.?audio|dublado|legendado|webrip|bluray|hdtv)\b"),
      " ");
  s = s.replaceAll(RegExp(r"[^\w\s]"), " ").replaceAll(RegExp(r"\s+"), " ").trim();
  return s;
}

/// Motor de recomendações da tela inicial.
///
/// NÃO usa TMDB para selecionar o que recomendar (TMDB é só metadados).
/// Em vez disso, varre FONTES DE MERCADO de popularidade em tempo real:
///   1. JustWatch (agregador de streaming) — filmes + séries, sem API key.
///   2. Letterboxd (filmes mais populares da semana) — RSS público, sem key.
/// Agrega por título (preservando ordem de popularidade), depois faz MATCH
/// FUZZY contra o catálogo M3U/Xtream conectado. Só seleciona conteúdo que
/// EXISTE no catálogo; pula para o próximo da lista até chegar a 5.
/// Cache local de 48h; atualização em background (imperceptível).
class TrendingService {
  static final TrendingService instance = TrendingService._();
  TrendingService._();

  static const _kCache = "trending_banners_v1";
  static const _kCacheTime = "trending_banners_time_v1";
  static const cacheValidity = Duration(hours: 48);
  static const targetCount = 5;

  bool _refreshing = false;

  /// Banners cacheados (válidos). Retorna null se vazio ou vencido.
  Future<List<MatchedBanner>?> getCached() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCache);
    final time = prefs.getInt(_kCacheTime) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (raw == null || now - time > cacheValidity.inMilliseconds) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => MatchedBanner.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Atualiza em background se o cache estiver vencido/ausente.
  /// Fire-and-forget: NÃO aguarda, NÃO mostra spinner. No-op se cache válido
  /// ou se já houver refresh em andamento.
  void refreshIfStale() {
    if (_refreshing) return;
    Future(() async {
      final cached = await getCached();
      if (cached != null && cached.isNotEmpty) return;
      await refresh();
    }).catchError((_) {});
  }

  /// Refresh completo (sempre roda). Chamado apenas em background.
  Future<List<MatchedBanner>> refresh() async {
    if (_refreshing) return [];
    _refreshing = true;
    try {
      final trending = await _fetchAllTrending();
      final matched = await _matchCatalog(trending);
      // Enriquece cada match com metadados TMDB (backdrop/sinopse/ano/nota).
      // TMDB aqui é SÓ metadados — a seleção do que recomendar já foi feita
      // pelas fontes de mercado + match com catálogo.
      final tmdb = TmdbService();
      final enriched = <MatchedBanner>[];
      for (final m in matched.take(targetCount)) {
        TmdbInfo? info;
        try {
          final fakeItem = MediaItem(
            id: "trending_${m.itemId}",
            name: m.displayName,
            url: "",
            type: m.kind == "series" ? ContentType.episode : ContentType.movie,
            seriesKey: m.kind == "series" ? m.itemId : null,
          );
          info = await tmdb.enrich(fakeItem);
        } catch (_) {}
        enriched.add(MatchedBanner(
          kind: m.kind,
          itemId: m.itemId,
          displayName: m.displayName,
          tmdb: info,
        ));
      }
      // Fallback: se nenhum trending casou (ex: catálogo muito nicho),
      // preenche com filmes aleatórios DO CATÁLOGO (nunca de fora).
      final finalList = enriched.isNotEmpty
          ? enriched
          : await _fallbackFromCatalog();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kCache, jsonEncode(finalList.map((e) => e.toJson()).toList()));
      await prefs.setInt(
          _kCacheTime, DateTime.now().millisecondsSinceEpoch);
      return finalList;
    } catch (_) {
      return [];
    } finally {
      _refreshing = false;
    }
  }

  /// Fallback: filmes/séries aleatórios DO catálogo (mantém regra de nunca
  /// recomendar conteúdo fora do catálogo).
  Future<List<MatchedBanner>> _fallbackFromCatalog() async {
    final db = AppDatabase.instance;
    final movies = await db.itemsByType(ContentType.movie, limit: 50);
    movies.shuffle();
    return movies.take(targetCount).map((m) => MatchedBanner(
          kind: "movie",
          itemId: m.id,
          displayName: m.name,
        )).toList();
  }

  // ===== Fontes de mercado =====

  Future<List<TrendingTitle>> _fetchAllTrending() async {
    final results = await Future.wait([
      _fetchJustWatch().catchError((_) => <TrendingTitle>[]),
      _fetchLetterboxd().catchError((_) => <TrendingTitle>[]),
    ]);
    final merged = <String, TrendingTitle>{};
    var rank = 0;
    // Intercala fontes preservando ordem de popularidade de cada uma.
    final jw = results[0];
    final lb = results[1];
    final maxLen = (jw.length > lb.length) ? jw.length : lb.length;
    for (var i = 0; i < maxLen; i++) {
      if (i < jw.length) {
        final t = jw[i];
        final key = "${t.kind}|${normalizeTitle(t.title)}";
        if (!merged.containsKey(key)) {
          merged[key] = TrendingTitle(
              title: t.title, kind: t.kind, rank: rank++);
        }
      }
      if (i < lb.length) {
        final t = lb[i];
        final key = "${t.kind}|${normalizeTitle(t.title)}";
        if (!merged.containsKey(key)) {
          merged[key] = TrendingTitle(
              title: t.title, kind: t.kind, rank: rank++);
        }
      }
    }
    final list = merged.values.toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));
    return list;
  }

  /// JustWatch: agregador de streaming — "popular" = filmes/séries mais
  /// assistidos/agregados no momento. Endpoint público sem API key.
  Future<List<TrendingTitle>> _fetchJustWatch() async {
    final resp = await http
        .post(
          Uri.parse("https://apis.justwatch.com/content/titles/en_US/popular"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "content_types": ["movie", "show"],
            "page": 1,
            "page_size": 40,
          }),
        )
        .timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) return [];
    final json = jsonDecode(resp.body);
    final items = json["items"] as List? ?? [];
    final out = <TrendingTitle>[];
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      final title = (it["title"] ?? "").toString();
      final type = (it["object_type"] ?? "").toString();
      if (title.isEmpty) continue;
      out.add(TrendingTitle(
        title: title,
        kind: type == "show" ? "show" : "movie",
        rank: i,
      ));
    }
    return out;
  }

  /// Letterboxd: filmes mais populares da semana (RSS público).
  Future<List<TrendingTitle>> _fetchLetterboxd() async {
    final resp = await http
        .get(Uri.parse(
            "https://letterboxd.com/films/popular/this/week/rss/"))
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return [];
    final titles = RegExp(r"<title>(.*?)</title>", dotAll: false)
        .allMatches(resp.body)
        .map((m) => m.group(1)!.trim())
        .where((t) => t != "Popular films this week")
        .toList();
    return [
      for (var i = 0; i < titles.length; i++)
        TrendingTitle(title: titles[i], kind: "movie", rank: i),
    ];
  }

  // ===== Match com catálogo local =====

  Future<List<MatchedBanner>> _matchCatalog(List<TrendingTitle> trending) async {
    final db = AppDatabase.instance;
    // Mapas leves: nome normalizado -> id. Apenas 2 colunas, memória baixa.
    final movieMap = await _movieNameMap(db);
    final seriesMap = await _seriesNameMap(db);
    final matched = <MatchedBanner>[];
    for (final t in trending) {
      if (matched.length >= targetCount) break;
      final norm = normalizeTitle(t.title);
      if (norm.isEmpty || norm.length < 3) continue;
      if (t.kind == "show") {
        final key = _bestMatch(norm, seriesMap);
        if (key != null) {
          matched.add(MatchedBanner(
              kind: "series", itemId: key, displayName: seriesMap[key]!.$2));
        }
      } else {
        final key = _bestMatch(norm, movieMap);
        if (key != null) {
          matched.add(MatchedBanner(
              kind: "movie", itemId: key, displayName: movieMap[key]!.$2));
        }
      }
    }
    return matched;
  }

  /// nome normalizado -> (id, nome original)
  Future<Map<String, (String, String)>> _movieNameMap(AppDatabase db) async {
    final rows = await (await db.db).query("media",
        columns: ["id", "name"], where: "type = ?", whereArgs: ["movie"]);
    final map = <String, (String, String)>{};
    for (final r in rows) {
      final id = r["id"].toString();
      final name = r["name"].toString();
      final norm = normalizeTitle(name);
      if (norm.length >= 3) map[norm] = (id, name);
    }
    return map;
  }

  /// nome normalizado -> (seriesKey, nome original)
  Future<Map<String, (String, String)>> _seriesNameMap(AppDatabase db) async {
    final rows = await (await db.db).query("media",
        columns: ["series_key", "name"],
        where: "type = ? AND series_key IS NOT NULL AND series_key != ''",
        whereArgs: ["episode"]);
    final map = <String, (String, String)>{};
    for (final r in rows) {
      final key = r["series_key"].toString();
      final name = r["name"].toString();
      final norm = normalizeTitle(name);
      if (norm.length >= 3) map[norm] = (key, name);
    }
    return map;
  }

  /// Match fuzzy: exato normalizado, ou o título do catálogo CONTÉM o título
  /// trending (ou vice-versa), com penalidade de comprimento.
  String? _bestMatch(String norm, Map<String, (String, String)> map) {
    if (map.containsKey(norm)) return map[norm]!.$1;
    String? best;
    int bestScore = 0;
    for (final entry in map.entries) {
      final k = entry.key;
      if (k.contains(norm) || norm.contains(k)) {
        final score = (norm.length + k.length) -
            (norm.length - k.length).abs() * 2;
        if (score > bestScore) {
          bestScore = score;
          best = entry.value.$1;
        }
      }
    }
    return best;
  }
}
