import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../core/models.dart';

/// Banco local SQLite com bulk insert e consultas paginadas.
class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  AppDatabase._();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, "unex_play.db"),
      version: 1,
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
        await db.execute("CREATE INDEX idx_type ON media(type)");
        await db.execute("CREATE INDEX idx_grp ON media(grp)");
        await db.execute("CREATE INDEX idx_series ON media(series_key)");
      },
    );
    return _db!;
  }

  /// Insere lista em lotes de 1000 (substitui catálogo anterior).
  Future<void> replaceAll(List<MediaItem> items) async {
    final d = await db;
    await d.transaction((txn) async {
      await txn.delete("media");
      var batch = txn.batch();
      for (var i = 0; i < items.length; i++) {
        batch.insert("media", items[i].toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
        if (i % 1000 == 999) {
          await batch.commit(noResult: true);
          batch = txn.batch();
        }
      }
      await batch.commit(noResult: true);
    });
  }

  Future<int> count() async =>
      Sqflite.firstIntValue(await (await db).rawQuery("SELECT COUNT(*) FROM media")) ?? 0;

  /// Apaga todo o catalogo (usado no logout / troca de conta).
  Future<void> clearAll() async {
    final d = await db;
    await d.delete("media");
  }

  Future<List<String>> groupsForType(ContentType type) async {
    // Categorias adultas sempre no final da lista.
    final rows = await (await db).query(
      "media",
      distinct: true,
      columns: ["grp"],
      where: "type = ? AND grp IS NOT NULL AND grp != ''",
      whereArgs: [type.name],
      orderBy: "CASE WHEN LOWER(grp) LIKE '%adult%' OR LOWER(grp) LIKE '%adulto%' OR LOWER(grp) LIKE '%xxx%' OR LOWER(grp) LIKE '%porn%' THEN 1 ELSE 0 END, grp ASC",
    );
    return rows.map((r) => r["grp"].toString()).toList();
  }

  Future<List<MediaItem>> itemsByType(
    ContentType type, {
    String? group,
    int limit = 50,
    int offset = 0,
    String? search,
    bool includeAdult = true,
  }) async {
    final where = StringBuffer("type = ?");
    final args = <Object?>[type.name];
    if (group != null) {
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
      orderBy: "name ASC",
      limit: limit,
      offset: offset,
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
    final map = {for (final m in rows.map(MediaItem.fromMap)) m.id: m};
    return ids.where((id) => map.containsKey(id)).map((id) => map[id]!).toList();
  }

  Future<MediaItem?> byId(String id) async {
    final rows = await (await db).query("media", where: "id = ?", whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return MediaItem.fromMap(rows.first);
  }

  /// Todas as séries agrupadas (um registro por série).
  Future<List<SeriesGroup>> allSeries({String? search}) async {
    final where = StringBuffer("type = 'episode' AND series_key IS NOT NULL");
    final args = <Object?>[];
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
      final key = item.seriesKey!;
      byKey.putIfAbsent(key, () => {"name": _seriesName(item.name), "key": key, "group": item.group});
      seasons.putIfAbsent(key, () => {});
      final s = item.season ?? 1;
      seasons[key]!.putIfAbsent(s, () => []).add(item);
      if (item.logo != null) {
        logoCount.putIfAbsent(key, () => {});
        logoCount[key]![item.logo!] = (logoCount[key]![item.logo!] ?? 0) + 1;
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
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  Future<SeriesGroup?> seriesByKey(String key) async {
    final all = await allSeries();
    for (final s in all) {
      if (s.key == key) return s;
    }
    return null;
  }

  static String _seriesName(String episodeName) {
    final reg = RegExp(r"^(.*?)\s*[Ss](\d+)\s*[Ee](\d+)", caseSensitive: false);
    final m = reg.firstMatch(episodeName);
    if (m != null) return m.group(1)!.trim();
    final reg2 = RegExp(r"^(.*?)\s*[Tt](\d+)\s*[Ee](\d+)");
    final m2 = reg2.firstMatch(episodeName);
    if (m2 != null) return m2.group(1)!.trim();
    return episodeName;
  }
}
