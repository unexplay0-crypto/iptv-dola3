import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;

class SpeedTestResult {
  final double pingMs;
  final double jitterMs;
  final double downloadMbps;
  final bool reachable;
  const SpeedTestResult({
    required this.pingMs,
    required this.jitterMs,
    required this.downloadMbps,
    this.reachable = true,
  });

  String get classification {
    if (!reachable) return "Servidor inacessível";
    if (downloadMbps < 3) return "Ruim (SD)";
    if (downloadMbps < 8) return "Razoável (HD)";
    if (downloadMbps < 25) return "Boa (FHD)";
    return "Excelente (4K)";
  }
}

/// Teste de velocidade: ping + download contra o DNS do usuário.
/// Não usa credenciais falsas (evita bloqueio por brute-force no provedor).
class SpeedTestService {
  static Future<SpeedTestResult> run(String dns,
      {void Function(double mbps)? onProgress}) async {
    final base = dns.endsWith("/") ? dns.substring(0, dns.length - 1) : dns;
    final stopwatch = Stopwatch();

    // Ping (3 amostras via HEAD — sem credenciais)
    final pings = <double>[];
    var reachable = false;
    for (var i = 0; i < 3; i++) {
      stopwatch.reset();
      stopwatch.start();
      try {
        final resp = await http
            .head(Uri.parse(base))
            .timeout(const Duration(seconds: 5));
        if (resp.statusCode < 500) reachable = true;
      } catch (_) {
        try {
          final resp = await http
              .get(Uri.parse(base))
              .timeout(const Duration(seconds: 5));
          if (resp.statusCode < 500) reachable = true;
        } catch (_) {}
      }
      stopwatch.stop();
      pings.add(stopwatch.elapsedMilliseconds.toDouble());
    }
    final ping = pings.reduce((a, b) => a + b) / pings.length;
    final jitter = pings.length > 1
        ? pings
                .sublist(1)
                .asMap()
                .entries
                .map((e) => (e.value - pings[e.key]).abs())
                .reduce((a, b) => a + b) /
            (pings.length - 1)
        : 0.0;

    if (!reachable) {
      return SpeedTestResult(
          pingMs: ping, jitterMs: jitter, downloadMbps: 0, reachable: false);
    }

    // Download: lê bytes do servidor por até 8s (endpoint raiz, sem credenciais)
    double totalBytes = 0;
    stopwatch.reset();
    stopwatch.start();
    try {
      final client = http.Client();
      final resp = await client.send(http.Request("GET", Uri.parse(base)));
      await for (final chunk in resp.stream) {
        totalBytes += chunk.length;
        final elapsed = stopwatch.elapsedMilliseconds / 1000;
        if (elapsed > 0.5) {
          onProgress?.call((totalBytes * 8 / 1e6) / elapsed);
        }
        if (stopwatch.elapsed.inSeconds > 8 || totalBytes > 50 * 1024 * 1024) {
          break;
        }
      }
      client.close();
    } catch (_) {
      // servidor parou de responder durante o download — usa o que já mediu
    }
    stopwatch.stop();
    final elapsedSec = max(stopwatch.elapsedMilliseconds / 1000, 0.1);
    final mbps = (totalBytes * 8 / 1e6) / elapsedSec;
    return SpeedTestResult(
        pingMs: ping, jitterMs: jitter, downloadMbps: mbps, reachable: true);
  }
}
