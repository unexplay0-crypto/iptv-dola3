import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../app_theme.dart';
import '../core/models.dart';
import 'tv_focusable_item.dart';

/// Banner rotativo de destaque (5 itens, 5s cada) — TMDB / recomendações.
class BannerRotator extends StatefulWidget {
  final List<MediaItem> items;
  final void Function(MediaItem) onSelect;
  const BannerRotator({super.key, required this.items, required this.onSelect});

  @override
  State<BannerRotator> createState() => _BannerRotatorState();
}

class _BannerRotatorState extends State<BannerRotator> {
  final PageController _ctrl = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (widget.items.isEmpty) return;
      _index = (_index + 1) % widget.items.length;
      if (_ctrl.hasClients) _ctrl.animateToPage(_index, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
        child: const Center(child: Text("Destaques em breve", style: TextStyle(color: AppTheme.textSecondary))),
      );
    }
    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: _ctrl,
        itemCount: widget.items.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) {
          final item = widget.items[i];
          return TVFocusableItem(
            autofocus: i == 0,
            onTap: () => widget.onSelect(item),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.logo != null)
                  CachedNetworkImage(imageUrl: item.logo!, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: AppTheme.surface))
                else
                  Container(color: AppTheme.surface),
                Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Colors.black87, Colors.black26, Colors.transparent]))),
                Positioned(left: 24, bottom: 20, right: 200, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(item.group, style: const TextStyle(color: AppTheme.accent, fontSize: 14)),
                ])),
                Positioned(left: 24, top: 16, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(4)), child: const Text("EM DESTAQUE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)))),
              ],
            ),
          );
        },
      ),
    );
  }
}
