import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../core/models.dart';
import '../data/tmdb_service.dart';
import '../widgets/fast_image.dart';
import 'tv_focusable_item.dart';

/// Banner de recomendação JÁ RESOLVIDO contra o catálogo local.
/// Garantia: o conteúdo sempre existe no catálogo conectado.
class ResolvedBanner {
  final String kind; // "movie" ou "series"
  final MediaItem? movie; // definido se kind == "movie"
  final SeriesGroup? series; // definido se kind == "series"
  final TmdbInfo? tmdb; // metadados (backdrop, sinopse, ano, nota)
  final String displayName;
  const ResolvedBanner({
    required this.kind,
    required this.displayName,
    this.movie,
    this.series,
    this.tmdb,
  });
}

/// Banner rotativo de destaque com visual "liquid glass".
/// O painel de informações sobre o backdrop usa blur real (BackdropFilter)
/// com preenchimento translúcido e borda clara — estilo tvOS/visionOS.
class BannerRotator extends StatefulWidget {
  final List<ResolvedBanner> items;
  final void Function(ResolvedBanner) onSelect;
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
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (widget.items.isEmpty) return;
      _index = (_index + 1) % widget.items.length;
      if (_ctrl.hasClients) {
        _ctrl.animateToPage(_index,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic);
      }
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
        height: 260,
        decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        child: const Center(
            child: Text("Destaques em breve",
                style: TextStyle(color: AppTheme.textSecondary))),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => _BannerCard(
              data: widget.items[i],
              onSelect: widget.onSelect,
              autofocus: i == 0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.items.length, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppTheme.accent : Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final ResolvedBanner data;
  final void Function(ResolvedBanner) onSelect;
  final bool autofocus;
  const _BannerCard(
      {required this.data, required this.onSelect, this.autofocus = false});

  @override
  Widget build(BuildContext context) {
    final tmdb = data.tmdb;
    final backdrop = tmdb?.backdropUrl;
    final poster = tmdb?.posterUrl;
    final title = tmdb?.title ?? data.displayName;
    final overview = tmdb?.overview;
    final year = tmdb?.year;
    final rating = tmdb?.rating;
    final quality = data.movie?.quality;

    return TVFocusableItem(
      autofocus: autofocus,
      borderRadius: AppTheme.radiusLg,
      focusScale: 1.01,
      onTap: () => onSelect(data),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppTheme.surface),
            // Backdrop TMDB (preferido) ou logo do item
            if (backdrop != null && backdrop.isNotEmpty)
              FastImage(url: backdrop, fit: BoxFit.cover)
            else if (data.movie?.logo != null)
              FastImage(url: data.movie!.logo!, fit: BoxFit.cover)
            else if (data.series?.logo != null)
              FastImage(url: data.series!.logo!, fit: BoxFit.cover)
            else
              const DecoratedBox(
                  decoration: BoxDecoration(gradient: AppTheme.ambientGradient)),
            // Escurecimento para legibilidade
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xE605070D),
                    Color(0x9905070D),
                    Color(0x3305070D),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.35, 0.65, 1.0],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xCC05070D), Colors.transparent],
                  stops: [0.0, 0.5],
                ),
              ),
            ),
            // Painel de informações em VIDRO (liquid glass) — blur real
            Positioned(
              left: 24,
              bottom: 22,
              right: 240,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Badge: tipo + "EM DESTAQUE"
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: AppTheme.accentGradient,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                    color: AppTheme.accent.withOpacity(0.4),
                                    blurRadius: 10),
                              ],
                            ),
                            child: const Text(
                              "EM DESTAQUE",
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: 1.2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              data.kind == "series" ? "SÉRIE" : "FILME",
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white70,
                                  letterSpacing: 0.8),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.15,
                            shadows: [
                              Shadow(
                                  color: Colors.black54,
                                  blurRadius: 8,
                                  offset: Offset(0, 2))
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          if (year != null && year.isNotEmpty)
                            Text(year,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          if (rating != null && rating > 0) ...[
                            if (year != null && year.isNotEmpty)
                              const SizedBox(width: 14),
                            const Icon(Icons.star, color: AppTheme.gold, size: 15),
                            const SizedBox(width: 4),
                            Text(rating.toStringAsFixed(1),
                                style: const TextStyle(
                                    color: AppTheme.gold,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                          ],
                          if (quality != null && quality.isNotEmpty) ...[
                            const SizedBox(width: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(quality,
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ]),
                        if (overview != null && overview.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            overview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.35),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Pôster à direita (profundidade)
            if (poster != null && poster.isNotEmpty)
              Positioned(
                right: 22,
                top: 22,
                bottom: 22,
                width: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FastImage(
                      url: poster,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const SizedBox.shrink()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
