import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'models.dart';

/// Motor de reprodução singleton (SharedStreamEngine).
/// Expõe [controllerNotifier] para que a UI reconstrua o VideoPlayer quando
/// a reconexão automática troca o controller. Também expõe [statusNotifier]
/// para feedback de carregamento em tempo real (evita a impressão de
/// "carregamento infinito" — o usuário vê em qual tentativa está).
class SharedStreamEngine {
  static final SharedStreamEngine instance = SharedStreamEngine._();
  SharedStreamEngine._();

  final ValueNotifier<VideoPlayerController?> controllerNotifier =
      ValueNotifier(null);

  /// Status textual do carregamento atual ("Conectando...", "Tentativa 2/3...").
  final ValueNotifier<String> statusNotifier = ValueNotifier("Conectando...");

  VideoPlayerController? get controller => controllerNotifier.value;
  MediaItem? currentItem;
  bool _reconnecting = false;

  static const _userAgents = [
    "IPTVSmartersPlayer",
    "VLC/3.0.20 LibVLC/3.0.20",
    "Lavf/60.3.100",
    "XCIPTV",
    "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36",
  ];

  static String normalizeUrl(String raw) {
    var s = raw.trim().replaceAll(RegExp(r"\s+"), "");
    final pipeIdx = s.indexOf("|");
    if (pipeIdx > 0) s = s.substring(0, pipeIdx);
    return s;
  }

  Future<VideoPlayerController> open(MediaItem item) async {
    await disposeCurrent();
    currentItem = item;
    final cleanUrl = normalizeUrl(item.url);
    if (cleanUrl.isEmpty) {
      statusNotifier.value = "URL inválida";
      throw Exception("URL do stream está vazia ou inválida.");
    }
    final baseHeaders = Map<String, String>.from(item.headers);

    // VOD: menos tentativas e timeout mais curto (falha rápido se a URL for
    // inválida, em vez de parecer "carregamento infinito").
    final isLive = item.type == ContentType.live;
    final maxAttempts = isLive ? 4 : 3;
    final timeout = isLive
        ? const Duration(seconds: 8)
        : const Duration(seconds: 10);

    final attempts = <Map<String, String>>[];
    for (var i = 0; i < maxAttempts && i < _userAgents.length; i++) {
      attempts.add({...baseHeaders, "User-Agent": _userAgents[i]});
    }
    attempts.add({...baseHeaders});
    attempts.add({});

    Object? lastError;
    var attempt = 0;
    for (final h in attempts) {
      attempt++;
      statusNotifier.value = "Conectando... (tentativa $attempt/${attempts.length})";
      VideoPlayerController? c;
      try {
        c = VideoPlayerController.networkUrl(
          Uri.parse(cleanUrl),
          httpHeaders: h,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
        );
        await c.initialize().timeout(timeout);
        controllerNotifier.value = c;
        statusNotifier.value = "Conectado";
        _autoReconnectLive(c, item, cleanUrl, h);
        return c;
      } catch (e) {
        lastError = e;
        try {
          await c?.dispose();
        } catch (_) {}
      }
    }
    statusNotifier.value = "Falha na conexão";
    throw lastError ?? Exception("Não foi possível abrir o stream");
  }

  void _autoReconnectLive(VideoPlayerController c, MediaItem item, String url,
      Map<String, String> headers) {
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
            try {
              await c.dispose();
            } catch (_) {}
            controllerNotifier.value = nc;
            await nc.play();
            _reconnecting = false;
            return;
          } catch (_) {}
        }
        _reconnecting = false;
      }
    });
  }

  Future<void> disposeCurrent() async {
    try {
      await controllerNotifier.value?.dispose();
    } catch (_) {}
    controllerNotifier.value = null;
    currentItem = null;
  }
}
