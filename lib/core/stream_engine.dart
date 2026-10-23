import 'dart:async';
import 'package:video_player/video_player.dart';
import 'models.dart';

/// Motor de reprodução singleton (SharedStreamEngine).
/// Tenta múltiplas estratégias de headers em sequência, normaliza a URL
/// e gerencia reconexão automática para streams ao vivo.
class SharedStreamEngine {
  static final SharedStreamEngine instance = SharedStreamEngine._();
  SharedStreamEngine._();

  VideoPlayerController? controller;
  MediaItem? currentItem;
  bool _reconnecting = false;

  static const _userAgents = [
    "IPTVSmartersPlayer",
    "VLC/3.0.20 LibVLC/3.0.20",
    "Lavf/60.3.100",
    "XCIPTV",
    "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36",
  ];

  /// Normaliza a URL: remove espaços em branco, quebras de linha e
  /// garante codificação mínima para o ExoPlayer abrir sem "Source error".
  static String normalizeUrl(String raw) {
    var s = raw.trim().replaceAll(RegExp(r"\s+"), "");
    // Remove pipe headers residuais (já foram separados no parser, mas garante)
    final pipeIdx = s.indexOf("|");
    if (pipeIdx > 0) s = s.substring(0, pipeIdx);
    return s;
  }

  /// Abre um stream tentando headers em sequência. Retorna o controller
  /// inicializado ou lança exceção se todas as tentativas falharem.
  Future<VideoPlayerController> open(MediaItem item) async {
    await disposeCurrent();
    currentItem = item;
    final cleanUrl = normalizeUrl(item.url);
    final baseHeaders = Map<String, String>.from(item.headers);

    final attempts = <Map<String, String>>[];
    // 1. headers do item + UA conhecido (prioriza o que o servidor espera)
    for (final ua in _userAgents) {
      attempts.add({...baseHeaders, "User-Agent": ua});
    }
    // 2. apenas headers do item (sem UA forçado)
    attempts.add({...baseHeaders});
    // 3. sem headers específicos
    attempts.add({});

    Object? lastError;
    for (final h in attempts) {
      VideoPlayerController? c;
      try {
        c = VideoPlayerController.networkUrl(
          Uri.parse(cleanUrl),
          httpHeaders: h,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
        );
        final timeout = item.type == ContentType.live
            ? const Duration(seconds: 8)
            : const Duration(seconds: 15);
        await c.initialize().timeout(timeout);
        controller = c;
        _autoReconnectLive(c, item, cleanUrl, h);
        return c;
      } catch (e) {
        lastError = e;
        try {
          await c?.dispose();
        } catch (_) {}
      }
    }
    throw lastError ?? Exception("Não foi possível abrir o stream");
  }

  /// Reconexão silenciosa para canais ao vivo (até 5 tentativas com backoff).
  void _autoReconnectLive(
      VideoPlayerController c, MediaItem item, String url, Map<String, String> headers) {
    if (item.type != ContentType.live) return;
    c.addListener(() async {
      if (c.value.hasError && !_reconnecting) {
        _reconnecting = true;
        final delays = [1, 2, 4, 8];
        for (var i = 0; i < delays.length; i++) {
          await Future.delayed(Duration(seconds: delays[i]));
          try {
            final nc = VideoPlayerController.networkUrl(
              Uri.parse(url),
              httpHeaders: headers,
            );
            await nc.initialize().timeout(const Duration(seconds: 10));
            await c.dispose();
            controller = nc;
            await nc.play();
            _reconnecting = false;
            return;
          } catch (_) {
            // continua tentando
          }
        }
        _reconnecting = false;
      }
    });
  }

  Future<void> disposeCurrent() async {
    try {
      await controller?.dispose();
    } catch (_) {}
    controller = null;
    currentItem = null;
  }
}
