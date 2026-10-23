# UNEX PLAY

Aplicativo de IPTV para **Android TV** (compatível com Android mobile) feito em **Flutter / Dart**.

- Login por **DNS + Usuário + Senha** (API Xtream Codes / `player_api.php`) com fallback para lista **M3U** e código de ativação de 6 dígitos.
- Abas: **Início** (recomendações, continuar assistindo, histórico, canais mais assistidos), **TV Ao Vivo** (categorias + canais + zapping), **Filmes** (por gênero), **Séries** (agrupadas por temporada/episódio), **Favoritos**, **Histórico**, **Configurações**.
- **Controle parental** com PIN padrão `0000`.
- **Teste de velocidade** embutido.
- Player baseado em **ExoPlayer/Media3** (via `video_player`) com buffer trifásico, reconexão automática e User-Agent customizável.
- Parser M3U em **Isolate** (stream linha a linha, máquina de estados) + cache em **SQLite** (sqflite) com bulk insert e paginação.
- Navegação 100% por **controle remoto** (D-Pad) com gestão de foco (memória de foco, wrap-around, zero perda de foco).

## Compilar via GitHub Actions

O workflow em `.github/workflows/build.yml` compila o APK automaticamente a cada push na `main` e em tags de release.

1. Faça push deste repositório para o GitHub.
2. Acesse a aba **Actions** → o build iniciará.
3. Ao concluir, baixe o APK em **Artifacts** (ou no GitHub Releases se usar tag).

### Assinatura de release (opcional)
Para APKs release assinados, configure no GitHub Secrets:
- `KEYSTORE_BASE64` (conteúdo base64 do seu .jks)
- `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`

## Compilar localmente
```bash
flutter pub get
flutter build apk --release
# APK em: build/app/outputs/flutter-apk/app-release.apk
```

## Estrutura
- `lib/core/` — modelos, motor de player, armazenamento
- `lib/data/` — cliente Xtream, parser M3U, speed test, TMDB, repositórios
- `lib/db/` — banco SQLite (sqflite)
- `lib/presentation/` — telas (login, início, tv, filmes, séries, player, configurações)
- `lib/widgets/` — componentes reutilizáveis (foco TV, PIN, banners, skeleton)
- `android/` — configuração nativa (Android TV / leanback)
