# GlassVision IPTV — Liquid Glass Edition

Clone do **UNEX Vision IPTV** com o motor de reprodução e catálogo **100% preservados**, mas com toda a interface redesennada no estilo **Liquid Glass** (vidro líquido), inspirado na nova linguagem de design da Apple (iOS 26 / visionOS).

## O que mudou

| Camada | Original (UNEX Vision) | GlassVision |
|---|---|---|
| Motor / Engine | Xtream Codes API + M3U, player multi-engine | **Idêntico** (core.dart preservado) |
| Reprodução | ExoPlayer com fallback de decoder + redirects | **Idêntico** (patch no workflow) |
| Catálogo | Live TV, Filmes (VOD), Séries, EPG, Favoritos, Recentes, Continue Watching | **Idêntico** |
| Controle parental | PIN padrão 0000 | **Idêntico** |
| Compatibilidade | Android TV (Leanback) + Celular | **Idêntico** |
| **Visual** | Tema escuro plano ciano/roxo, cards opacos | **Liquid Glass**: blur de fundo, superfícies translúcidas, bordas especulares, fundo Aurora animado, brilho no foco, física de mola |

## Estrutura

```
lib/
├── core.dart            # Motor: modelos, XtreamCatalogService, SharedStreamEngine, AppStorage (preservado)
├── glass.dart           # NOVO: sistema de design Liquid Glass (GlassSurface, GlassButton, GlassTextField, AuroraBackground, GlassDialog, GlassChip, GradientText, tema)
├── widgets.dart         # Widgets reutilizáveis (reescritos em vidro: TVFocusableItem, cartazes, teclado virtual, PIN parental)
├── main.dart            # App, boot, login (Xtream/M3U), dashboard (tema vidro + fundo Aurora)
├── mobile_screen.dart   # Dashboard modo celular (estilo vidro)
├── tv_screen.dart       # Dashboard modo Android TV com foco D-pad (estilo vidro)
└── player_screen.dart   # Player adaptativo com OSD (estilo vidro)
.github/workflows/build.yml  # Pipeline de build no GitHub Actions (gera APK release)
pubspec.yaml
PLANO_DE_DESENVOLVIMENTO.md  # Análise detalhada + plano de desenvolvimento
```

## Como compilar (upload para o GitHub)

1. Crie um repositório no GitHub (ex.: `glassvision-iptv`).
2. Faça upload de **todo o conteúdo** desta pasta (mantendo a estrutura `lib/` e `.github/`).
3. Faça push para a branch `main`.
4. Acesse a aba **Actions** — o workflow `Build GlassVision IPTV Release APK` inicia automaticamente.
5. Ao terminar, baixe o APK em **Artifacts** (`glassvision-iptv-release-apk`).

> O workflow gera automaticamente o `pubspec.yaml`, a pasta `android/`, o `MainActivity.kt` (ponte nativa), a política de rede HTTP, o patch do ExoPlayer para TV e compila o APK release. Nenhuma configuração adicional é necessária.

## Compilar localmente (opcional)

```bash
flutter create --platforms=android --project-name glassvision --org com.glass.vision .
flutter pub get
flutter build apk --release --target-platform android-arm,android-arm64
```

## Login

- **Modo Xtream**: DNS do servidor + Usuário + Senha
- **Modo M3U direto**: link completo da lista M3U Plus

PIN de controle parental padrão: **0000** (alterável em Configurações).

## Créditos

Motor de reprodução e catálogo baseado no projeto UNEX Vision IPTV. Visual Liquid Glass redesenhado do zero.
