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

  /// Classificação da qualidade de vídeo recomendada para a velocidade medida.
  String get qualityRecommendation {
    if (!reachable || downloadMbps < 1.5) {
      return "SD (480p) — conexão muito lenta";
    }
    if (downloadMbps < 4) return "SD (480p) — recomendado para evitar travamentos";
    if (downloadMbps < 8) return "HD (720p) — qualidade boa para esta internet";
    if (downloadMbps < 16) return "Full HD (1080p) — ideal para esta velocidade";
    if (downloadMbps < 35) return "Full HD (1080p) — 4K pode travar no horário de pico";
    return "4K (2160p) — excelente conexão, qualidade máxima recomendada";
  }

  String get classification {
    if (!reachable) return "Servidor inacessível";
    if (downloadMbps < 3) return "Ruim";
    if (downloadMbps < 8) return "Razoável";
    if (downloadMbps < 25) return "Boa";
    if (downloadMbps < 50) return "Muito Boa";
    return "Excelente";
  }
}

/// Teste de velocidade estilo fast.com / speedtest.net.
///
/// Mede ping (latência) e velocidade de DOWNLOAD real baixando um arquivo
/// grande de um CDN público (Cloudflare — mesmo tipo de endpoint usado por
/// fast.com e speedtest). Reporta progresso em Mbps em tempo real via
/// [onProgress] e, ao final, recomenda a qualidade de imagem ideal.
class SpeedTestService {
  // Endpoint público de download de teste (Cloudflare, global, confiável).
  // ?bytes=N força o download de N bytes (sempre o mesmo conteúdo, rápido).
  static const _downloadUrl =
      "https://speed.cloudflare.com/__down?bytes=30000000"; // 30 MB
  static const _pingUrl = "https://speed.cloudflare.com/__down?bytes=0";

  static Future<SpeedTestResult> run(
    String? dns, {
    void Function(double mbps)? onProgress,
  }) async {
    final stopwatch = Stopwatch();

    // ---- 1. Ping / latência (3 amostras contra o CDN público) ----
    final pings = <double>[];
    var reachable = false;
    for (var i = 0; i < 3; i++) {
      stopwatch.reset();
      stopwatch.start();
      try {
        final resp = await http
            .get(Uri.parse(_pingUrl))
            .timeout(const Duration(seconds: 6));
        if (resp.statusCode < 500) reachable = true;
      } catch (_) {
        // fallback: testa o próprio DNS do usuário (servidor IPTV)
        try {
          final base = (dns ?? "").endsWith("/")
              ? (dns ?? "").substring(0, (dns ?? "").length - 1)
              : (dns ?? "");
          if (base.isNotEmpty) {
            final resp = await http
                .head(Uri.parse(base))
                .timeout(const Duration(seconds: 5));
            if (resp.statusCode < 500) reachable = true;
          }
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

    // ---- 2. Download real (estilo fast.com): lê bytes por até 10s ----
    double totalBytes = 0;
    stopwatch.reset();
    stopwatch.start();
    try {
      final client = http.Client();
      final resp = await client
          .send(http.Request("GET", Uri.parse(_downloadUrl)))
          .timeout(const Duration(seconds: 12));
      await for (final chunk in resp.stream) {
        totalBytes += chunk.length;
        final elapsed = stopwatch.elapsedMilliseconds / 1000;
        if (elapsed > 0.3) {
          onProgress?.call((totalBytes * 8 / 1e6) / elapsed);
        }
        // Para após 10s ou 50MB (o suficiente para medir com precisão).
        if (stopwatch.elapsed.inSeconds > 10 || totalBytes > 50 * 1024 * 1024) {
          break;
        }
      }
      client.close();
    } catch (_) {
      // CDN parou — usa o que já foi medido.
    }
    stopwatch.stop();
    final elapsedSec = max(stopwatch.elapsedMilliseconds / 1000, 0.1);
    final mbps = (totalBytes * 8 / 1e6) / elapsedSec;
    return SpeedTestResult(
        pingMs: ping, jitterMs: jitter, downloadMbps: mbps, reachable: true);
  }
}
