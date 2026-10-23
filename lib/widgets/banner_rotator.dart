import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../app_theme.dart';
import '../core/models.dart';
import '../data/tmdb_service.dart';
import 'tv_focusable_item.dart';

/// Banner rotativo de destaque com backdrop do TMDB.
/// Usa gradientes sobrepostos para camuflar defeitos de imagens de baixa
/// qualidade e garantir legibilidade do texto. Aceita itens enriquecidos
/// ({item: MediaItem, tmdb: TmdbInfo?}).
class BannerRotator extends StatefulWidget {
  final List<Map<String, dynamic>> items; // {"item": MediaItem, "tmdb": TmdbInfo?}
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
          height: 280,
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
        // Indicadores de página
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
  final Map<String, dynamic> data;
  final void Function(MediaItem) onSelect;
  final bool autofocus;
  const _BannerCard(
      {required this.data, required this.onSelect, this.autofocus = false});

  @override
  Widget build(BuildContext context) {
    final item = data["item"] as MediaItem;
    final tmdb = data["tmdb"] as TmdbInfo?;
    final backdrop = tmdb?.backdropUrl;
    final title = tmdb?.title ?? item.name;
    final overview = tmdb?.overview;
    final year = tmdb?.year;
    final rating = tmdb?.rating;

    return TVFocusableItem(
      autofocus: autofocus,
      borderRadius: AppTheme.radiusLg,
      focusScale: 1.01,
      onTap: () => onSelect(item),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fundo sólido (camufla bordas / falhas da imagem)
            Container(color: AppTheme.surface),
            // Imagem de fundo: backdrop TMDB (preferido) ou logo do item
            if (backdrop != null && backdrop.isNotEmpty)
              CachedNetworkImage(
                imageUrl: backdrop,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _fallbackImage(item),
              )
            else
              _fallbackImage(item),
            // Gradiente sobreposto ESQUERDA → DIREITA (escurece para texto)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xDD0A0F1A),
                    Color(0x880A0F1A),
                    Color(0x220A0F1A),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.35, 0.65, 1.0],
                ),
              ),
            ),
            // Gradiente sobreposto INFERIOR (escurece base para legibilidade)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xCC0A0F1A), Colors.transparent],
                  stops: [0.0, 0.5],
                ),
              ),
            ),
            // Conteúdo textual
            Positioned(
              left: 28,
              right: 260,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge EM DESTAQUE
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accent.withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Text(
                      "EM DESTAQUE",
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 1.2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Título
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 30,
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
                  // Ano + avaliação
                  Row(
                    children: [
                      if (year != null && year.isNotEmpty)
                        Text(year,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      if (rating != null && rating > 0) ...[
                        if (year != null && year.isNotEmpty)
                          const SizedBox(width: 14),
                        const Icon(Icons.star,
                            color: AppTheme.gold, size: 16),
                        const SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1),
                            style: const TextStyle(
                                color: AppTheme.gold,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ],
                      if (item.quality != null) ...[
                        const SizedBox(width: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(item.quality!,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  if (overview != null && overview.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      overview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.35),
                    ),
                  ],
                ],
              ),
            ),
            // Pôster à direita (se disponível) — adiciona profundidade
            if (tmdb?.hasPoster ?? false)
              Positioned(
                right: 24,
                top: 24,
                bottom: 24,
                width: 170,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: tmdb!.posterUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackImage(MediaItem item) {
    if (item.logo != null && item.logo!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: item.logo!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(color: AppTheme.surface),
      );
    }
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.ambientGradient),
      child: const Center(
          child: Icon(Icons.movie_rounded,
              size: 64, color: AppTheme.textMuted)),
    );
  }
}
