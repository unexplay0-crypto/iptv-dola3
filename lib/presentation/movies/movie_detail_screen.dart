import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../core/device_config.dart';
import '../../core/models.dart';
import '../../widgets/fast_image.dart';
import '../../widgets/tv_focusable_item.dart';
import '../player/player_screen.dart';

/// Tela de detalhes do filme (aberta antes da reprodução).
/// Mostra pôster, nome, ano, qualidade, grupo e botão grande "Reproduzir".
/// Layout adaptativo: TV → pôster à esquerda + info à direita;
/// celular → pôster acima + info abaixo (Column), sem overflow.
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
    final posterWidth = isPhone ? 140.0 : 220.0;
    final titleSize = isPhone ? 22.0 : 30.0;

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          movie.name,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          if (_year != null)
            Text(_year!,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          if (movie.quality != null && movie.quality!.isNotEmpty) ...[
            if (_year != null) const SizedBox(width: 12),
            AppTheme.qualityBadge(movie.quality),
          ],
          if (movie.group.isNotEmpty) ...[
            const SizedBox(width: 12),
            Flexible(
              child: Text(movie.group,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 13)),
            ),
          ],
        ]),
        const SizedBox(height: 16),
        // Sinopse — sem TMDB por item no catálogo; mostra texto informativo.
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: Colors.white10),
          ),
          child: const Text(
            "Sinopse indisponível para este título. Pressione Reproduzir para assistir agora — o stream começa em poucos segundos.",
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(height: 20),
        // Botão grande de reproduzir — adaptativo (largura total no celular).
        SizedBox(
          width: isPhone ? double.infinity : 260,
          child: TVFocusableItem(
            autofocus: true,
            borderRadius: AppTheme.radiusMd,
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
                      color: AppTheme.accent.withOpacity(0.4), blurRadius: 16),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.black, size: 26),
                  SizedBox(width: 8),
                  Text("REPRODUZIR",
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1)),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    final poster = ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusPoster),
      child: movie.logo != null && movie.logo!.isNotEmpty
          ? FastImage(
              url: movie.logo!,
              width: posterWidth,
              height: posterWidth * 1.5,
              fit: BoxFit.cover,
              httpHeaders: movie.headers.isEmpty ? null : movie.headers,
            )
          : Container(
              width: posterWidth,
              height: posterWidth * 1.5,
              color: AppTheme.surface,
              child: const Icon(Icons.movie_rounded,
                  size: 56, color: AppTheme.textMuted),
            ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.ambientGradient),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(DeviceConfig.of(context).overscan / 2),
            child: Center(
              child: SingleChildScrollView(
                child: isPhone
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          poster,
                          const SizedBox(height: 20),
                          info,
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          poster,
                          const SizedBox(width: 32),
                          Expanded(child: info),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
