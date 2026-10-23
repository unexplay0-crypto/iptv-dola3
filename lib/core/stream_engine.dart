import 'dart:async';
import 'package:video_player/video_player.dart';
import 'models.dart';

/// Motor de reprodução singleton (SharedStreamEngine).
/// Tenta múltiplas estratégias de headers em sequência e gerencia
/// reconexão automática para streams ao vivo.
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
  ];

  /// Abre um stream tentando headers em sequência. Retorna o controller
  /// inicializado ou lança exceção se todas as tentativas falharem.
  Future<VideoPlayerController> open(MediaItem item) async {
    await disposeCurrent();
    currentItem = item;

    final baseHeaders = Map<String, String>.from(item.headers);
    final attempts = <Map<String, String>>[];
    // 1. headers do item + UA padrão
    for (final ua in _userAgents) {
      attempts.add({...baseHeaders, "User-Agent": ua});
    }
    // 2. sem headers específicos
    attempts.add({});

    Object? lastError;
    for (final h in attempts) {
      try {
        final c = VideoPlayerController.networkUrl(
          Uri.parse(item.url),
          httpHeaders: h,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
        );
        final timeout = item.type == ContentType.live
            ? const Duration(seconds: 6)
            : const Duration(seconds: 12);
        await c.initialize().timeout(timeout);
        controller = c;
        _autoReconnectLive(c, item);
        return c;
      } catch (e) {
        lastError = e;
        try {
          c.dispose();
        } catch (_) {}
      }
    }
    throw lastError ?? Exception("Não foi possível abrir o stream");
  }

  /// Reconexão silenciosa para canais ao vivo (até 5 tentativas com backoff).
  void _autoReconnectLive(VideoPlayerController c, MediaItem item) {
    if (item.type != ContentType.live) return;
    c.addListener(() async {
      if (c.value.hasError && !_reconnecting) {
        _reconnecting = true;
        final delays = [1, 2, 4, 8];
        for (var i = 0; i < delays.length; i++) {
          await Future.delayed(Duration(seconds: delays[i]));
          try {
            final nc = VideoPlayerController.networkUrl(
              Uri.parse(item.url),
              httpHeaders: {"User-Agent": _userAgents.first},
            );
            await nc.initialize().timeout(const Duration(seconds: 8));
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
    await controller?.dispose();
    controller = null;
    currentItem = null;
  }
}
