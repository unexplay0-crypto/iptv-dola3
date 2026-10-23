import '../../core/models.dart';
import '../../core/storage.dart';
import '../../db/database.dart';
import '../xtream_api_client.dart';
import '../m3u_stream_reader.dart';

/// Repositório central: orquestra Xtream API (prioritário) com fallback M3U,
/// persiste no banco local e serve consultas paginadas.
class ContentRepository {
  final AppDatabase _db = AppDatabase.instance;
  final AppStorage _storage = AppStorage.instance;

  Future<List<MediaItem>> loadCatalog({void Function(String status)? onStatus}) async {
    final creds = _storage.credentials;
    List<MediaItem> items = [];

    if (creds.dns.isNotEmpty && creds.username.isNotEmpty) {
      onStatus?.call("Conectando ao servidor Xtream...");
      final client = XtreamApiClient(
        dns: creds.dns,
        username: creds.username,
        password: creds.password,
      );
      final ok = await client.authenticate();
      if (ok) {
        onStatus?.call("Carregando canais ao vivo...");
        items = await client.fetchAll();
      }
    }

    if (items.isEmpty && (creds.m3uUrl?.isNotEmpty ?? false)) {
      onStatus?.call("Baixando lista M3U...");
      items = await M3uStreamReader.read(creds.m3uUrl!);
    }

    if (items.isEmpty) {
      throw Exception("Não foi possível carregar o catálogo. Verifique DNS/usuário/senha.");
    }

    onStatus?.call("Organizando ${items.length} itens...");
    await _db.replaceAll(items);
    return items;
  }

  Future<int> get catalogCount => _db.count();

  Future<List<String>> liveGroups() => _db.groupsForType(ContentType.live);
  Future<List<String>> movieGroups() => _db.groupsForType(ContentType.movie);
  Future<List<String>> seriesGroups() => _db.groupsForType(ContentType.episode);

  Future<List<MediaItem>> liveChannels({String? group, int limit = 50, int offset = 0, String? search}) =>
      _db.itemsByType(ContentType.live, group: group, limit: limit, offset: offset, search: search, includeAdult: _storage.adultUnlocked);

  Future<List<MediaItem>> movies({String? group, int limit = 50, int offset = 0, String? search}) =>
      _db.itemsByType(ContentType.movie, group: group, limit: limit, offset: offset, search: search, includeAdult: _storage.adultUnlocked);

  Future<List<SeriesGroup>> series({String? search}) => _db.allSeries(search: search);
  Future<SeriesGroup?> seriesByKey(String key) => _db.seriesByKey(key);

  Future<List<MediaItem>> byIds(List<String> ids) => _db.byIds(ids);
  Future<MediaItem?> byId(String id) => _db.byId(id);
}
