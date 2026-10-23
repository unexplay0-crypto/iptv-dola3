import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;

class SpeedTestResult {
  final double pingMs;
  final double jitterMs;
  final double downloadMbps;
  const SpeedTestResult({required this.pingMs, required this.jitterMs, required this.downloadMbps});

  String get classification {
    if (downloadMbps < 3) return "Ruim (SD)";
    if (downloadMbps < 8) return "Razoável (HD)";
    if (downloadMbps < 25) return "Boa (FHD)";
    return "Excelente (4K)";
  }
}

/// Teste de velocidade: ping + download de payload contra o DNS do usuário.
class SpeedTestService {
  static Future<SpeedTestResult> run(String dns, {void Function(double mbps)? onProgress}) async {
    final base = dns.endsWith("/") ? dns.substring(0, dns.length - 1) : dns;
    final stopwatch = Stopwatch();

    // Ping (3 amostras)
    final pings = <double>[];
    for (var i = 0; i < 3; i++) {
      stopwatch.reset();
      stopwatch.start();
      try {
        await http.head(Uri.parse(base)).timeout(const Duration(seconds: 5));
      } catch (_) {
        try {
          await http.get(Uri.parse(base)).timeout(const Duration(seconds: 5));
        } catch (_) {}
      }
      stopwatch.stop();
      pings.add(stopwatch.elapsedMilliseconds.toDouble());
    }
    final ping = pings.reduce((a, b) => a + b) / pings.length;
    final jitter = pings.length > 1
        ? pings.sublist(1).asMap().entries.map((e) => (e.value - pings[e.key]).abs()).reduce((a, b) => a + b) / (pings.length - 1)
        : 0;

    // Download: baixa um endpoint do servidor (ou fallback de arquivo conhecido)
    double totalBytes = 0;
    stopwatch.reset();
    stopwatch.start();
    try {
      final client = http.Client();
      final resp = await client.send(http.Request("GET", Uri.parse("$base/player_api.php?username=x&password=x")));
      await for (final chunk in resp.stream) {
        totalBytes += chunk.length;
        final elapsed = stopwatch.elapsedMilliseconds / 1000;
        if (elapsed > 0.5) {
          final mbps = (totalBytes * 8 / 1e6) / elapsed;
          onProgress?.call(mbps);
        }
        if (stopwatch.elapsed.inSeconds > 8 || totalBytes > 50 * 1024 * 1024) break;
      }
      client.close();
    } catch (_) {
      // fallback: simula com pequeno payload se servidor não responder
      totalBytes = max(totalBytes, 1024 * 1024);
    }
    stopwatch.stop();
    final elapsedSec = max(stopwatch.elapsedMilliseconds / 1000, 0.1);
    final mbps = (totalBytes * 8 / 1e6) / elapsedSec;

    return SpeedTestResult(pingMs: ping, jitterMs: jitter, downloadMbps: mbps);
  }
}
