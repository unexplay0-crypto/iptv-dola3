import 'dart:convert';
import 'package:http/http.dart' as http;
import 'm3u_parser.dart';
import '../core/models.dart';

/// Leitura por stream linha a linha (evita carregar 15-50MB na RAM de uma vez).
class M3uStreamReader {
  static Future<List<MediaItem>> read(String url, {Duration timeout = const Duration(seconds: 60)}) async {
    final client = http.Client();
    try {
      final req = http.Request("GET", Uri.parse(url));
      final resp = await client.send(req).timeout(timeout);
      if (resp.statusCode != 200) {
        throw Exception("Erro HTTP ${resp.statusCode} ao baixar lista M3U");
      }
      final lines = <String>[];
      await resp.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach(lines.add);
      return M3uParser.parseLines(lines);
    } finally {
      client.close();
    }
  }
}
