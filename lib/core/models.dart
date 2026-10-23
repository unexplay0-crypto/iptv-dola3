/// Modelos de domínio do UNEX PLAY.

enum ContentType { live, movie, episode }

extension ContentTypeLabel on ContentType {
  String get label {
    switch (this) {
      case ContentType.live:
        return "Ao Vivo";
      case ContentType.movie:
        return "Filme";
      case ContentType.episode:
        return "Série";
    }
  }
}

/// Item de mídia único (canal, filme ou episódio de série).
class MediaItem {
  final String id; // tvg-id ou hash da url
  final String name;
  final String? logo;
  final String group;
  final String url;
  final Map<String, String> headers;
  final ContentType type;
  final String? quality;
  final bool isAdult;
  final String? tvgId;
  final bool catchup;
  final int? durationSec;

  // Agrupamento de séries
  final String? seriesKey; // nome normalizado da série
  final int? season;
  final int? episode;

  const MediaItem({
    required this.id,
    required this.name,
    this.logo,
    this.group = "",
    required this.url,
    this.headers = const {},
    required this.type,
    this.quality,
    this.isAdult = false,
    this.tvgId,
    this.catchup = false,
    this.durationSec,
    this.seriesKey,
    this.season,
    this.episode,
  });

  bool get isSeriesEpisode => seriesKey != null && type == ContentType.episode;

  Map<String, Object?> toMap() => {
        "id": id,
        "name": name,
        "logo": logo,
        "grp": group,
        "url": url,
        "headers": _encodeHeaders(headers),
        "type": type.name,
        "quality": quality,
        "is_adult": isAdult ? 1 : 0,
        "tvg_id": tvgId,
        "catchup": catchup ? 1 : 0,
        "duration_sec": durationSec,
        "series_key": seriesKey,
        "season": season,
        "episode": episode,
      };

  factory MediaItem.fromMap(Map<String, Object?> m) => MediaItem(
        id: (m["id"] ?? "").toString(),
        name: (m["name"] ?? "").toString(),
        logo: m["logo"]?.toString(),
        group: (m["grp"] ?? "").toString(),
        url: (m["url"] ?? "").toString(),
        headers: _decodeHeaders((m["headers"] ?? "").toString()),
        type: ContentType.values.firstWhere(
          (e) => e.name == (m["type"] ?? "live").toString(),
          orElse: () => ContentType.live,
        ),
        quality: m["quality"]?.toString(),
        isAdult: (m["is_adult"] ?? 0) == 1,
        tvgId: m["tvg_id"]?.toString(),
        catchup: (m["catchup"] ?? 0) == 1,
        durationSec: m["duration_sec"] as int?,
        seriesKey: m["series_key"]?.toString(),
        season: m["season"] as int?,
        episode: m["episode"] as int?,
      );

  static String _encodeHeaders(Map<String, String> h) => h.entries
      .map((e) => "${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}")
      .join("&");

  static Map<String, String> _decodeHeaders(String s) {
    if (s.isEmpty) return {};
    final out = <String, String>{};
    for (final part in s.split("&")) {
      final i = part.indexOf("=");
      if (i > 0) {
        out[Uri.decodeComponent(part.substring(0, i))] =
            Uri.decodeComponent(part.substring(i + 1));
      }
    }
    return out;
  }
}

/// Série agrupada por temporadas e episódios.
class SeriesGroup {
  final String key;
  final String name;
  final String? logo;
  final Map<int, List<MediaItem>> seasons; // season -> episodes sorted

  const SeriesGroup({
    required this.key,
    required this.name,
    this.logo,
    required this.seasons,
  });

  List<int> get seasonNumbers => seasons.keys.toList()..sort();
  int get episodeCount => seasons.values.fold(0, (a, l) => a + l.length);
}

/// Credenciais do usuário (login Xtream / M3U).
class AppCredentials {
  final String dns;
  final String username;
  final String password;
  final String? m3uUrl;
  final String? activationCode;

  const AppCredentials({
    this.dns = "",
    this.username = "",
    this.password = "",
    this.m3uUrl,
    this.activationCode,
  });

  bool get isEmpty =>
      dns.isEmpty && (m3uUrl == null || m3uUrl!.isEmpty) && (activationCode == null || activationCode!.isEmpty);
}
