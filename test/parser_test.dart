import 'package:flutter_test/flutter_test.dart';
import 'package:unex_play/data/m3u_parser.dart';
import 'package:unex_play/core/models.dart';

void main() {
  test("Parser M3U classifica canal ao vivo por URL .ts", () {
    const m3u = '''#EXTM3U
#EXTINF:-1 tvg-id="globo" tvg-logo="http://logo.png" group-title="CANAIS | ABERTOS",GLOBO FHD
http://servidor.com:8080/live/user/pass/12345.ts
''';
    final items = M3uParser.parseLines(m3u.split("\n"));
    expect(items.length, 1);
    expect(items.first.type, ContentType.live);
    expect(items.first.name, "GLOBO FHD");
    expect(items.first.group, "CANAIS | ABERTOS");
  });

  test("Parser detecta série por padrão S01E01 no nome", () {
    const m3u = '''#EXTM3U
#EXTINF:-1 group-title="SERIES",Breaking Bad S01E01
http://servidor.com/movies/user/pass/99999.mp4
''';
    final items = M3uParser.parseLines(m3u.split("\n"));
    expect(items.length, 1);
    expect(items.first.type, ContentType.episode);
    expect(items.first.season, 1);
    expect(items.first.episode, 1);
    expect(items.first.seriesKey, "breaking bad");
  });

  test("Parser separa pipe headers da URL", () {
    const m3u = '''#EXTM3U
#EXTINF:-1,Canal Teste
http://servidor.com/live/u/p/1.ts|User-Agent=CustomAgent&Referer=http://servidor.com
''';
    final items = M3uParser.parseLines(m3u.split("\n"));
    expect(items.first.url, "http://servidor.com/live/u/p/1.ts");
    expect(items.first.headers["User-Agent"], "CustomAgent");
    expect(items.first.headers["Referer"], "http://servidor.com");
  });
}
