import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../core/device_config.dart';
import '../core/models.dart';
import '../data/tmdb_service.dart';
import '../widgets/fast_image.dart';
import 'tv_focusable_item.dart';

/// Banner de recomendação JÁ RESOLVIDO contra o catálogo local.
class ResolvedBanner {
  final String kind; // "movie" ou "series"
  final MediaItem? movie;
  final SeriesGroup? series;
  final TmdbInfo? tmdb;
  final String displayName;
  const ResolvedBanner({
    required this.kind,
    required this.displayName,
    this.movie,
    this.series,
    this.tmdb,
  });
}

/// Banner rotativo de destaque — layout estilo Google TV:
///  - Lado ESQUERDO: informações (título, ano, nota, sinopse) + botão Assistir.
///  - Lado DIREITO: imagem do filme/série na proporção ORIGINAL (sem distorção).
///  - Degradê da esquerda para a direita sobre a imagem, cobrindo a borda para
///    uma transição perfeita (sem linha acentuada entre texto e imagem).
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
          height: DeviceConfig.of(context).isPhone ? 210 : 320,
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
    final isPhone = DeviceConfig.of(context).isPhone;
    final tmdb = data.tmdb;
    final backdrop = tmdb?.backdropUrl;
    final poster = tmdb?.posterUrl ?? data.movie?.logo ?? data.series?.logo;
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
            // Fundo: backdrop escurecido (ou gradiente ambiente).
            Container(color: const Color(0xFF05070D)),
            if (backdrop != null && backdrop.isNotEmpty)
              FastImage(url: backdrop, fit: BoxFit.cover)
            else
              const DecoratedBox(
                  decoration: BoxDecoration(gradient: AppTheme.ambientGradient)),
            // Escurecimento geral para legibilidade.
            Container(color: Colors.black.withOpacity(0.35)),

            // ===== LADO DIREITO: imagem na proporção ORIGINAL (sem distorção)
            if (!isPhone && poster != null && poster.isNotEmpty)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 340,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: FastImage(
                      url: poster,
                      fit: BoxFit.contain, // proporção original, sem distorção
                      alignment: Alignment.centerRight,
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

            // ===== DEGRADÊ DE TRANSIÇÃO: da esquerda (sólido) para a direita
            // (transparente), cobrindo a borda esquerda da imagem — elimina a
            // linha acentuada e cria uma fusão perfeita entre texto e imagem.
            if (!isPhone && poster != null && poster.isNotEmpty)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: const [
                        Color(0xF205070D), // sólido no lado do texto
                        Color(0xD905070D),
                        Color(0x8005070D),
                        Color(0x3305070D),
                        Colors.transparent, // imagem totalmente visível
                      ],
                      stops: const [0.0, 0.35, 0.55, 0.72, 1.0],
                    ),
                  ),
                ),
              ),

            // ===== LADO ESQUERDO: informações + botão Assistir
            Positioned(
              left: 20,
              top: 0,
              bottom: 0,
              right: isPhone ? 20 : 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
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
                  const SizedBox(height: 12),
                  Text(
                    title,
                    maxLines: isPhone ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isPhone ? 22 : 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.15,
                      shadows: const [
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
                  if (overview != null && overview.isNotEmpty && !isPhone) ...[
                    const SizedBox(height: 10),
                    Text(
                      overview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13, height: 1.35),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Botão Assistir (estilo Google TV)
                  TVFocusableItem(
                    borderRadius: AppTheme.radiusMd,
                    focusScale: 1.04,
                    onTap: () => onSelect(data),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        boxShadow: [
                          BoxShadow(
                              color: AppTheme.accent.withOpacity(0.4),
                              blurRadius: 16),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded,
                              color: Colors.black, size: 22),
                          SizedBox(width: 8),
                          Text("Assistir",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
