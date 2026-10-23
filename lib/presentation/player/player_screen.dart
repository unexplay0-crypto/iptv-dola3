import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../app_theme.dart';
import '../../core/models.dart';
import '../../core/storage.dart';
import '../../core/stream_engine.dart';
import '../../widgets/pin_dialog.dart';
import '../../widgets/tv_focusable_item.dart';

class PlayerScreen extends StatefulWidget {
  final MediaItem item;
  final List<MediaItem>? playlist; // para zapping / próximo episódio
  const PlayerScreen({super.key, required this.item, this.playlist});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final _engine = SharedStreamEngine.instance;
  VideoPlayerController? _ctrl;
  bool _loading = true;
  String _error = "";
  bool _osdVisible = true;
  Timer? _osdTimer;
  Timer? _progressTimer;

  bool get _isLive => widget.item.type == ContentType.live;
  bool get _isVod => !_isLive;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Controle parental
    if (widget.item.isAdult && !AppStorage.instance.adultUnlocked) {
      final ok = await PinDialog.request(context, title: "Conteúdo adulto — digite o PIN");
      if (!ok) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      await AppStorage.instance.setAdultUnlocked(true);
    }
    await _openStream();
  }

  Future<void> _openStream() async {
    setState(() {
      _loading = true;
      _error = "";
    });
    try {
      final c = await _engine.open(widget.item);
      _ctrl = c;
      // Retomar progresso (VOD)
      if (_isVod) {
        final pos = AppStorage.instance.progressFor(widget.item.id);
        if (pos != null && pos > 5000) {
          await c.seekTo(Duration(milliseconds: pos));
        }
        _progressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          if (c.value.isInitialized) {
            AppStorage.instance.saveProgress(widget.item.id, c.value.position.inMilliseconds);
          }
        });
      }
      await c.play();
      if (mounted) setState(() => _loading = false);
      _hideOsd();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = "Não foi possível abrir o stream. $e";
        });
      }
    }
  }

  void _showOsd() {
    setState(() => _osdVisible = true);
    _hideOsd();
  }

  void _hideOsd() {
    _osdTimer?.cancel();
    _osdTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _osdVisible = false);
    });
  }

  void _togglePlay() {
    final c = _ctrl;
    if (c == null) return;
    setState(() => c.value.isPlaying ? c.pause() : c.play());
    _showOsd();
  }

  void _seek(Duration delta) {
    final c = _ctrl;
    if (c == null || _isLive) return;
    final pos = c.value.position + delta;
    final target = pos < Duration.zero
        ? Duration.zero
        : (pos > c.value.duration ? c.value.duration : pos);
    c.seekTo(target);
    _showOsd();
  }

  // Back stack: 1 clique = fecha OSD; 2 cliques = sai do player
  DateTime? _lastBack;
  Future<bool> _onWillPop() async {
    if (_osdVisible) {
      setState(() => _osdVisible = false);
      return false;
    }
    final now = DateTime.now();
    if (_lastBack != null && now.difference(_lastBack!) < const Duration(milliseconds: 800)) {
      return true; // sai
    }
    _lastBack = now;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pressione Voltar novamente para sair"), duration: Duration(seconds: 1)));
    return false;
  }

  @override
  void dispose() {
    _osdTimer?.cancel();
    _progressTimer?.cancel();
    if (_isVod && _ctrl != null && _ctrl!.value.isInitialized) {
      AppStorage.instance.saveProgress(widget.item.id, _ctrl!.value.position.inMilliseconds);
    }
    _engine.disposeCurrent();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, __) async {
        if (didPop) return;
        if (await _onWillPop() && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            final label = event.logicalKey.keyLabel;
            if (label == "Select" || label == "Enter" || label == "Media Play Pause") {
              _togglePlay();
              return KeyEventResult.handled;
            }
            if (label == "Arrow Left") {
              _seek(const Duration(seconds: -10));
              return KeyEventResult.handled;
            }
            if (label == "Arrow Right") {
              _seek(const Duration(seconds: 10));
              return KeyEventResult.handled;
            }
            if (label == "Arrow Up" || label == "Arrow Down") {
              _showOsd();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: GestureDetector(
            onTap: _showOsd,
            child: Stack(children: [
              Center(
                child: _ctrl != null && _ctrl!.value.isInitialized
                    ? AspectRatio(aspectRatio: _ctrl!.value.aspectRatio, child: VideoPlayer(_ctrl!))
                    : Container(color: Colors.black),
              ),
              if (_loading) const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
              if (_error.isNotEmpty)
                Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error, style: const TextStyle(color: AppTheme.danger), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    TVFocusableItem(
                      autofocus: true,
                      onTap: _openStream,
                      child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), color: AppTheme.accent, child: const Text("Tentar novamente", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                    ),
                  ]),
                ),
              // OSD
              if (_osdVisible && _ctrl != null && _error.isEmpty)
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: Container(
                    decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black87, Colors.transparent])),
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(widget.item.group, style: const TextStyle(color: AppTheme.accent, fontSize: 13)),
                      const SizedBox(height: 12),
                      if (_isVod && _ctrl!.value.isInitialized)
                        Row(children: [
                          Text(_fmt(_ctrl!.value.position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          Expanded(
                            child: Slider(
                              value: _ctrl!.value.position.inMilliseconds.toDouble().clamp(0.0, _ctrl!.value.duration.inMilliseconds.toDouble()),
                              max: _ctrl!.value.duration.inMilliseconds.toDouble(),
                              activeColor: AppTheme.accent,
                              onChanged: (v) => _ctrl!.seekTo(Duration(milliseconds: v.toInt())),
                            ),
                          ),
                          Text(_fmt(_ctrl!.value.duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        _osdButton(Icons.replay_10, "Voltar 10s", _isVod ? () => _seek(const Duration(seconds: -10)) : null),
                        const SizedBox(width: 12),
                        _osdButton(_ctrl!.value.isPlaying ? Icons.pause : Icons.play_arrow, "Play/Pause", _togglePlay, primary: true),
                        const SizedBox(width: 12),
                        _osdButton(Icons.forward_10, "Avançar 10s", _isVod ? () => _seek(const Duration(seconds: 10)) : null),
                        const SizedBox(width: 12),
                        _osdButton(Icons.fullscreen, "Tela cheia", () {}),
                        const SizedBox(width: 12),
                        if (widget.item.type == ContentType.episode)
                          _osdButton(Icons.list, "Episódios", () {}),
                        if (_isLive) _osdButton(Icons.live_tv, "Canais", () {}),
                        const Spacer(),
                        _osdButton(Icons.close, "Sair", () => Navigator.of(context).pop()),
                      ]),
                    ]),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _osdButton(IconData icon, String tooltip, VoidCallback? onTap, {bool primary = false}) {
    return TVFocusableItem(
      onTap: onTap,
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(color: primary ? AppTheme.accent : Colors.white12, shape: BoxShape.circle),
        child: Icon(icon, color: primary ? Colors.black : Colors.white, size: 24),
      ),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, "0");
    final s = d.inSeconds.remainder(60).toString().padLeft(2, "0");
    return h > 0 ? "$h:$m:$s" : "$m:$s";
  }
}
