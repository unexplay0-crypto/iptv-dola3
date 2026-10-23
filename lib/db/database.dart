import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../core/models.dart';

/// Banco SQLite local: cache do catálogo + favoritos + histórico.
class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  AppDatabase._();
  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), "unex_play.db");
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE media (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            logo TEXT,
            grp TEXT,
            url TEXT NOT NULL,
            headers TEXT,
            type TEXT NOT NULL,
            quality TEXT,
            is_adult INTEGER DEFAULT 0,
            tvg_id TEXT,
            catchup INTEGER DEFAULT 0,
            duration_sec INTEGER,
            series_key TEXT,
            season INTEGER,
            episode INTEGER
          )
        ''');
        await db.execute(
            "CREATE INDEX idx_media_type ON media(type, grp)");
        await db.execute(
            "CREATE INDEX idx_media_series ON media(series_key)");
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          await db.execute("DROP TABLE IF EXISTS media");
          await db.execute('''
            CREATE TABLE media (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              logo TEXT,
              grp TEXT,
              url TEXT NOT NULL,
              headers TEXT,
              type TEXT NOT NULL,
              quality TEXT,
              is_adult INTEGER DEFAULT 0,
              tvg_id TEXT,
              catchup INTEGER DEFAULT 0,
              duration_sec INTEGER,
              series_key TEXT,
              season INTEGER,
              episode INTEGER
            )
          ''');
        }
      },
    );
  }

  Future<void> replaceAll(List<MediaItem> items) async {
    final d = await db;
    await d.transaction((txn) async {
      await txn.delete("media");
      final batch = txn.batch();
      for (final it in items) {
        batch.insert("media", it.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> clearAll() async {
    final d = await db;
    await d.delete("media");
  }

  Future<int> count() async =>
      (await (await db).rawQuery("SELECT COUNT(*) as c FROM media"))
          .first["c"] as int;

  /// Categorias distintas de um tipo. Adultos sempre no final.
  Future<List<String>> groupsForType(ContentType type) async {
    final rows = await (await db).query(
      "media",
      distinct: true,
      columns: ["grp"],
      where: "type = ? AND grp IS NOT NULL AND grp != ''",
      whereArgs: [type.name],
      orderBy:
          "CASE WHEN LOWER(grp) LIKE '%adult%' OR LOWER(grp) LIKE '%adulto%' OR LOWER(grp) LIKE '%xxx%' OR LOWER(grp) LIKE '%porn%' THEN 1 ELSE 0 END, grp ASC",
    );
    return rows.map((r) => r["grp"].toString()).toList();
  }

  Future<List<MediaItem>> itemsByType(
    ContentType type, {
    String? group,
    int limit = 50,
    int offset = 0,
    String? search,
    bool includeAdult = false,
  }) async {
    final where = StringBuffer("type = ?");
    final args = <Object?>[type.name];
    if (group != null && group.isNotEmpty && group != "Todos") {
      where.write(" AND grp = ?");
      args.add(group);
    }
    if (search != null && search.isNotEmpty) {
      where.write(" AND name LIKE ?");
      args.add("%$search%");
    }
    if (!includeAdult) {
      where.write(" AND is_adult = 0");
    }
    final rows = await (await db).query(
      "media",
      where: where.toString(),
      whereArgs: args,
      limit: limit,
      offset: offset,
      orderBy: "name ASC",
    );
    return rows.map(MediaItem.fromMap).toList();
  }

  Future<List<MediaItem>> byIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final placeholders = List.filled(ids.length, "?").join(",");
    final rows = await (await db).query(
      "media",
      where: "id IN ($placeholders)",
      whereArgs: ids,
    );
    final byId = {for (final r in rows) r["id"].toString(): MediaItem.fromMap(r)};
    return ids.where((id) => byId.containsKey(id)).map((id) => byId[id]!).toList();
  }

  Future<MediaItem?> byId(String id) async {
    final rows = await (await db).query("media",
        where: "id = ?", whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return MediaItem.fromMap(rows.first);
  }

  /// Normaliza nome para chave de série (fallback quando series_key é null).
  static String _seriesKeyFallback(String name) {
    var s = name.toLowerCase();
    s = s.replaceAll(RegExp(r"\s*[Ss]\d{1,2}\s*[Ee]\d{1,3}.*"), "");
    s = s.replaceAll(RegExp(r"\s*[Tt]\d{1,2}\s*[Ee]\d{1,3}.*"), "");
    s = s.replaceAll(RegExp(r"\s*\(\d{4}\).*"), "");
    s = s.replaceAll(
        RegExp(r"\b(4k|2160p|fhd|1080p|hd|720p|sd|480p|dual.?audio|dublado|legendado)\b"),
        "");
    s = s.replaceAll(RegExp(r"[^\w\s]"), " ").replaceAll(RegExp(r"\s+"), " ").trim();
    return s.isEmpty ? name.toLowerCase() : s;
  }

  static String _seriesName(String full) {
    final m = RegExp(r"^(.*?)\s*[Ss]\d{1,2}\s*[Ee]\d{1,3}").firstMatch(full);
    if (m != null) return m.group(1)!.trim();
    final m2 = RegExp(r"^(.*?)\s*[Tt]\d{1,2}\s*[Ee]\d{1,3}").firstMatch(full);
    if (m2 != null) return m2.group(1)!.trim();
    return full.trim();
  }

  /// Agrupa episódios por série → temporadas → episódios ordenados.
  /// Fallback: se series_key for null, agrupa pelo nome normalizado.
  Future<List<SeriesGroup>> allSeries({String? search}) async {
    final where = StringBuffer("type = ?");
    final args = <Object?>[ContentType.episode.name];
    if (search != null && search.isNotEmpty) {
      where.write(" AND name LIKE ?");
      args.add("%$search%");
    }
    final rows = await (await db).query(
      "media",
      where: where.toString(),
      whereArgs: args.isEmpty ? null : args,
      orderBy: "series_key ASC, season ASC, episode ASC",
    );

    final byKey = <String, Map<String, Object>>{};
    final seasons = <String, Map<int, List<MediaItem>>>{};
    final logoCount = <String, Map<String, int>>{};

    for (final row in rows) {
      final item = MediaItem.fromMap(row);
      // Placeholder de série Xtream (id series_*) — não é episódio reproduzível,
      // mas define a série. Usa seriesKey como chave.
      final key = item.seriesKey ?? _seriesKeyFallback(item.name);
      byKey.putIfAbsent(
          key, () => {"name": _seriesName(item.name), "key": key, "group": item.group});
      seasons.putIfAbsent(key, () => {});
      // Placeholder Xtream não tem season/episode — não adiciona à lista de
      // episódios (serão carregados sob demanda via fetchSeriesInfo).
      if (!item.id.startsWith("series_")) {
        final s = item.season ?? 1;
        seasons[key]!.putIfAbsent(s, () => []).add(item);
      }
      if (item.logo != null && item.logo!.isNotEmpty) {
        final lc = logoCount.putIfAbsent(key, () => {});
        lc[item.logo!] = (lc[item.logo!] ?? 0) + 1;
      }
    }

    final result = <SeriesGroup>[];
    byKey.forEach((key, info) {
      String? logo;
      if (logoCount.containsKey(key)) {
        final entries = logoCount[key]!.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        logo = entries.first.key;
      }
      result.add(SeriesGroup(
        key: key,
        name: info["name"].toString(),
        logo: logo,
        group: info["group"]?.toString() ?? "",
        seasons: seasons[key] ?? {},
      ));
    });
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  Future<SeriesGroup?> seriesByKey(String key) async {
    final all = await allSeries();
    for (final s in all) {
      if (s.key == key) return s;
    }
    return null;
  }
}
