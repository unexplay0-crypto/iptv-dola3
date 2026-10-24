import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../core/device_config.dart';
import '../../core/models.dart';
import '../../widgets/fast_image.dart';
import '../../widgets/tv_focusable_item.dart';
import '../player/player_screen.dart';

/// Tela de detalhes do filme — estilo Google TV:
///  - Fundo: pôster do filme desfocado em tela cheia (com escurecimento).
///  - Esquerda: pôster em alta qualidade (miniatura).
///  - Direita: nome, ano, qualidade, grupo, sinopse e botão grande Reproduzir.
class MovieDetailScreen extends StatelessWidget {
  final MediaItem movie;
  const MovieDetailScreen({super.key, required this.movie});

  String? get _year {
    final m = RegExp(r"\((\d{4})\)").firstMatch(movie.name);
    return m?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = DeviceConfig.of(context).isPhone;
    final posterUrl = movie.logo;
    final hasPoster = posterUrl != null && posterUrl.isNotEmpty;
    final posterWidth = isPhone ? 150.0 : 240.0;

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          movie.name,
          style: TextStyle(
            fontSize: isPhone ? 24 : 34,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            height: 1.15,
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 2))
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          if (_year != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(_year!,
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          if (movie.quality != null && movie.quality!.isNotEmpty) ...[
            const SizedBox(width: 10),
            AppTheme.qualityBadge(movie.quality),
          ],
          if (movie.group.isNotEmpty) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(movie.group,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 12)),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 18),
        // Sinopse em painel de vidro
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: Colors.white10),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: AppTheme.accent, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Pressione Reproduzir para assistir agora — o stream começa em poucos segundos. A qualidade se adapta automaticamente à sua conexão.",
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13, height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Botão grande Reproduzir (estilo Google TV)
        SizedBox(
          width: isPhone ? double.infinity : 300,
          child: TVFocusableItem(
            autofocus: true,
            borderRadius: AppTheme.radiusMd,
            focusScale: 1.03,
            onTap: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => PlayerScreen(item: movie)),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.accent.withOpacity(0.45), blurRadius: 20),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.black, size: 28),
                  SizedBox(width: 10),
                  Text("REPRODUZIR",
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.2)),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    final poster = ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusPoster),
      child: hasPoster
          ? FastImage(
              url: posterUrl,
              width: posterWidth,
              height: posterWidth * 1.5,
              fit: BoxFit.cover,
              httpHeaders: movie.headers.isEmpty ? null : movie.headers,
              errorWidget: (_, __, ___) => _posterPlaceholder(posterWidth),
            )
          : _posterPlaceholder(posterWidth),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fundo desfocado (estilo Google TV): pôster em tela cheia + blur.
          if (hasPoster)
            FastImage(
              url: posterUrl,
              fit: BoxFit.cover,
              httpHeaders: movie.headers.isEmpty ? null : movie.headers,
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            )
          else
            const DecoratedBox(
                decoration: BoxDecoration(gradient: AppTheme.ambientGradient)),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.black.withOpacity(0.55)),
          ),
          // Conteúdo
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(DeviceConfig.of(context).overscan / 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TVFocusableItem(
                    borderRadius: 20,
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: AppTheme.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: isPhone
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  poster,
                                  const SizedBox(height: 24),
                                  info,
                                ],
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  poster,
                                  const SizedBox(width: 40),
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 520),
                                    child: info,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _posterPlaceholder(double w) => Container(
        width: w,
        height: w * 1.5,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusPoster),
        ),
        child: const Icon(Icons.movie_rounded, size: 56, color: AppTheme.textMuted),
      );
}
