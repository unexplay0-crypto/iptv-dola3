import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/models.dart';

/// Parser M3U em máquina de estados (sem regex pesado por linha).
/// Executado dentro de Isolate via compute().
class M3uParser {
  /// Ponto de entrada para Isolate: recebe o texto completo e devolve itens.
  static Future<List<MediaItem>> parseInBackground(String content) async {
    return compute(_parseM3u, content);
  }

  static List<MediaItem> _parseM3u(String content) {
    final lines = const LineSplitter().convert(content);
    return parseLines(lines);
  }

  static List<MediaItem> parseLines(List<String> lines) {
    final items = <MediaItem>[];
    String? name;
    String? logo;
    String group = "";
    String? tvgId;
    bool catchup = false;
    int? duration;
    final headers = <String, String>{};

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      if (line.startsWith("#EXTINF:")) {
        final parsed = _parseExtinf(line);
        name = parsed["name"];
        logo = parsed["logo"];
        group = parsed["group"] ?? "";
        tvgId = parsed["tvg-id"];
        catchup = parsed["catchup"] == "true";
        duration = parsed["duration"] != null
            ? int.tryParse(parsed["duration"]!)
            : null;
        continue;
      }
      if (line.startsWith("#EXTVLCOPT:")) {
        final opt = line.substring("#EXTVLCOPT:".length);
        final eq = opt.indexOf("=");
        if (eq > 0) headers[opt.substring(0, eq).trim()] = opt.substring(eq + 1).trim();
        continue;
      }
      if (line.startsWith("#KODIPROP:")) {
        final opt = line.substring("#KODIPROP:".length);
        final eq = opt.indexOf("=");
        if (eq > 0) headers[opt.substring(0, eq).trim()] = opt.substring(eq + 1).trim();
        continue;
      }
      if (line.startsWith("#")) continue; // demais diretivas ignoradas

      // Linha de URL
      if (line.startsWith("http") || line.startsWith("rtmp") || line.startsWith("udp")) {
        final urlParts = line.split("|");
        final url = urlParts[0];
        final pipeHeaders = urlParts.length > 1 ? _parsePipeHeaders(urlParts.sublist(1).join("|")) : <String, String>{};
        final allHeaders = {...headers, ...pipeHeaders};
        final type = _classify(url, group, name ?? "");
        final seriesInfo = _extractSeries(name ?? "");
        final item = MediaItem(
          id: _idFor(tvgId, url, name ?? ""),
          name: _cleanName(name ?? url),
          logo: logo,
          group: group.isEmpty ? "Geral" : group,
          url: url,
          headers: allHeaders,
          type: type,
          quality: _extractQuality(name ?? ""),
          isAdult: _isAdult(group, name ?? ""),
          tvgId: tvgId,
          catchup: catchup,
          durationSec: duration,
          seriesKey: type == ContentType.episode ? seriesInfo?.$1 : null,
          season: type == ContentType.episode ? seriesInfo?.$2 : null,
          episode: type == ContentType.episode ? seriesInfo?.$3 : null,
        );
        items.add(item);
        // reset
        name = null;
        logo = null;
        group = "";
        tvgId = null;
        catchup = false;
        duration = null;
        headers.clear();
      }
    }
    return items;
  }

  static Map<String, String> _parseExtinf(String line) {
    final out = <String, String>{};
    // duração: entre #EXTINF: e o primeiro espaço/vírgula
    final afterTag = line.substring("#EXTINF:".length);
    final commaIdx = afterTag.lastIndexOf(",");
    final attrsPart = commaIdx > 0 ? afterTag.substring(0, commaIdx) : afterTag;
    out["name"] = commaIdx > 0 ? afterTag.substring(commaIdx + 1).trim() : "";

    final durMatch = RegExp(r"^(-?\d+)").firstMatch(attrsPart.trim());
    if (durMatch != null) out["duration"] = durMatch.group(1)!;

    // atributos chave="valor"
    final attrReg = RegExp(r'([a-zA-Z0-9_-]+)="([^"]*)"');
    for (final m in attrReg.allMatches(attrsPart)) {
      final key = m.group(1)!.toLowerCase();
      final value = m.group(2)!;
      if (key == "tvg-logo") out["logo"] = value;
      if (key == "group-title") out["group"] = value;
      if (key == "tvg-id") out["tvg-id"] = value;
      if (key == "catchup" && value.isNotEmpty) out["catchup"] = "true";
    }
    return out;
  }

  static Map<String, String> _parsePipeHeaders(String s) {
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

  static ContentType _classify(String url, String group, String name) {
    final lower = url.toLowerCase();
    if (lower.contains("/live/") || lower.endsWith(".ts")) return ContentType.live;
    if (lower.contains("/movie/")) return ContentType.movie;
    if (lower.contains("/series/") || _extractSeries(name) != null) return ContentType.episode;
    if (lower.endsWith(".mp4") || lower.endsWith(".mkv") || lower.endsWith(".avi")) {
      return _extractSeries(name) != null ? ContentType.episode : ContentType.movie;
    }
    final g = group.toLowerCase();
    if (g.contains("filme") || g.contains("movie")) return ContentType.movie;
    if (g.contains("serie") || g.contains("series")) return ContentType.episode;
    if (_extractSeries(name) != null) return ContentType.episode;
    return ContentType.live;
  }

  static (String, int, int)? _extractSeries(String name) {
    final m = RegExp(r"^(.*?)\s*[Ss](\d+)\s*[Ee](\d+)").firstMatch(name);
    if (m != null) {
      return (m.group(1)!.trim().toLowerCase(), int.parse(m.group(2)!), int.parse(m.group(3)!));
    }
    final m2 = RegExp(r"^(.*?)\s*[Tt](\d+)\s*[Ee](\d+)").firstMatch(name);
    if (m2 != null) {
      return (m2.group(1)!.trim().toLowerCase(), int.parse(m2.group(2)!), int.parse(m2.group(3)!));
    }
    return null;
  }

  static bool _isAdult(String group, String name) {
    final s = "${group.toLowerCase()} ${name.toLowerCase()}";
    return s.contains("adulto") || s.contains("adult") || s.contains("xxx") || s.contains("porn");
  }

  static String? _extractQuality(String name) {
    final s = name.toUpperCase();
    if (s.contains("4K") || s.contains("2160P")) return "4K";
    if (s.contains("FHD") || s.contains("1080P")) return "FHD";
    if (s.contains("HD") || s.contains("720P")) return "HD";
    if (s.contains("SD") || s.contains("480P")) return "SD";
    return null;
  }

  static String _cleanName(String n) {
    return n.replaceAll(RegExp(r"\s+"), " ").trim();
  }

  /// Hash FNV-1a 64-bit determinístico (puro Dart, sem dependência).
  /// Reduz drasticamente colisões de ID vs hashCode de 32 bits.
  static int _fnv1a64(String s) {
    var hash = 0xcbf29ce484222325;
    for (final unit in s.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash;
  }

  static String _idFor(String? tvgId, String url, String name) {
    if (tvgId != null && tvgId.isNotEmpty) {
      // tvg-id pode se repetir entre canais diferentes; combina com a URL
      return _fnv1a64("$tvgId|$url").toRadixString(36);
    }
    return _fnv1a64("$url|$name").toRadixString(36);
  }
}
