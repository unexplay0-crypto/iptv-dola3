import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'models.dart';

/// Motor de reprodução singleton (SharedStreamEngine).
/// Expõe [controllerNotifier] para que a UI reconstrua o VideoPlayer quando
/// a reconexão automática troca o controller (antes a UI ficava com o
/// controller antigo descartado → tela preta).
class SharedStreamEngine {
  static final SharedStreamEngine instance = SharedStreamEngine._();
  SharedStreamEngine._();

  /// Notifica a UI sempre que o controller ativo muda (reconexão).
  final ValueNotifier<VideoPlayerController?> controllerNotifier =
      ValueNotifier(null);

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
    final baseHeaders = Map<String, String>.from(item.headers);

    final attempts = <Map<String, String>>[];
    for (final ua in _userAgents) {
      attempts.add({...baseHeaders, "User-Agent": ua});
    }
    attempts.add({...baseHeaders});
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
        controllerNotifier.value = c;
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
            controllerNotifier.value = nc; // UI rebuilda automaticamente
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
