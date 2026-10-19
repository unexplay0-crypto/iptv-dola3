# Plano de Desenvolvimento — GlassVision IPTV (Liquid Glass Edition)

## 1. Análise Detalhada do Repositório Original

**Repositório:** `unexplay0-crypto/IPTV-APP` (UNEX Vision v2.3.0)
**Stack:** Flutter / Dart 100% + Android ( APK release via GitHub Actions )
**Tamanho:** ~310 KB de código Dart, 25 commits.

### 1.1 Estrutura de arquivos

| Arquivo | Tamanho | Responsabilidade |
|---|---|---|
| `lib/core.dart` | 54 KB | **Motor do app** — modelos, engine de streaming, serviço de catálogo Xtream, armazenamento local |
| `lib/main.dart` | 85 KB | Entrypoint, tema, boot router, tela de login, dashboard principal |
| `lib/mobile_screen.dart` | 26 KB | Dashboard em layout celular (drawer + grades) |
| `lib/tv_screen.dart` | 59 KB | Dashboard em layout TV (navegação D-pad, foco, carrossel imersivo) |
| `lib/player_screen.dart` | 37 KB | Player adaptativo com OSD, brilho/volume por gesto |
| `lib/widgets.dart` | 36 KB | Widgets reutilizáveis (foco TV, cartazes, teclado virtual, PIN parental) |
| `.github/workflows/build.yml` | 12 KB | Pipeline completo de build (gera tudo e compila APK) |

> Observação crítica: o repositório **não contém** `pubspec.yaml`, pasta `android/` ou `MainActivity.kt`. O workflow do GitHub Actions **gera tudo em tempo de build**. Por isso o clone entregue segue o mesmo padrão: apenas `lib/` + workflow + `pubspec.yaml` (opcional, para build local).

### 1.2 Funcionalidades do motor (preservadas 100%)

- **Login dual:** Xtream Codes (DNS + usuário + senha) **ou** link M3U Plus direto.
- **Autenticação Xtream:** valida `user_info.auth`, status (expired/banned/disabled) e `exp_date`.
- **Catálogo:** `get_live_categories`, `get_live_streams`, `get_vod_categories`, `get_vod_streams`, `get_series_categories`, `get_series` (parsing em isolate via `compute`).
- **Parsing M3U avançado:** `parseM3UAdvanced` (tvg-id, tvg-logo, group-title).
- **Unificação de áudio:** filmes Dublado/Legendado mesclados em um único cartaz com seletor.
- **Conteúdo:** TV ao vivo, Filmes (VOD), Séries (com temporadas/episódios), EPG (agora/depois).
- **Player multi-engine:** 6 tentativas sequenciais (SURFACE / TEXTURE / NATIVO) com fallback automático, resolução de redirects 301/302, watchdog de stall, seek para live-edge.
- **ExoPlayer patch:** `setEnableDecoderFallback(true)` + `setAllowCrossProtocolRedirects(true)` (injetado no pub-cache durante o build).
- **Persistência:** sessão, favoritos, recentes, progresso VOD (continue watching), playlist offline (cache até 18k itens), PIN parental, modo do dispositivo.
- **Nativo (MethodChannel `unex.vision/native`):** detecção de Android TV (UiModeManager + Leanback + touchscreen), brilho, volume, abrir URL externa.
- **Extras:** busca textual, categorias com contagem, controle parental (+18, PIN padrão 0000), OTA update, atalhos de teclado/controle (select/enter/gameButtonA), Impeller desativado (melhor compatibilidade com video_player em TVs).

### 1.3 Visual original (a ser substituído)

- Tema escuro plano: fundo `#090B10`, painéis `#111520`/`#161B2A`, cards opacos com borda `white12`.
- Acentos: ciano `#00E5FF` + roxo `#7C4DFF`.
- Sem blur, sem profundidade real, sem animações de mola.

---

## 2. Pesquisa Profunda: Liquid Glass e Design de Vidro

### 2.1 Apple Liquid Glass (WWDC 2025 — iOS 26 / visionOS 2 / macOS Tahoe)

É um **material**, não um esquema de cores. Introduzido por Alan Dye ("maior atualização de design desde o iOS 7"). Princípios ópticos:
1. **Refração em tempo real** — o conteúdo abaixo é distorcido e desfocado através do vidro.
2. **Reflexão especular** — bordas com brilho direcional (specular highlights) que reagem ao movimento.
3. **Profundidade em camadas** — múltiplas superfícies translúcidas empilhadas com parallax.
4. **Fluidez responsiva** — micro-interações com física de mola (spring), o vidro "respira".
5. **Adaptação cromática** — a cor do vidro é informada pelo conteúdo ao redor (claro/escuro).

### 2.2 Implementação em Flutter (técnicas utilizadas)

| Efeito | Técnica em Flutter |
|---|---|
| Blur de fundo (refração) | `BackdropFilter` + `ImageFilter.blur(sigmaX/Y: 18–30)` |
| Preenchimento translúcido | `Colors.white.withOpacity(0.08–0.16)` ou `Color(0x14FFFFFF)` (const-safe) |
| Borda especular | `Border.all(color: white.withOpacity(0.2–0.3))` + gradiente superior brilhante |
| Brilho interno topo | `Positioned` superior com gradiente horizontal de `white55` |
| Sombra de profundidade | `BoxShadow` preto 25–35% com blur 24, offset vertical |
| Fundo colorido (o que o vidro refrata) | `AuroraBackground` — 3 blobs animados (ciano/violeta/rosa) sobre gradiente espacial profundo |
| Resposta fluida no foco | `AnimatedScale` (1.0→1.06) + `AnimatedContainer` com `Curves.easeOutCubic`, 250–300ms |
| Glow de foco | `BoxShadow` colorido (ciano+violeta) com blur 28–32 e spread 1.5–2 |
| Performance | Impeller desativado (herdado); blur limitado às superfícies principais; evitar `BackdropFilter` aninhados |

### 2.3 Pacotes estudados (não utilizados — zero dependências extras)

- `liquid_glass_widgets` — shader-free, BackdropFilter + matriz de saturação Rec.709 + rim specular.
- `liquid_glass_easy` — lentes com distorção/magnificação em tempo real (custo alto, evitado em TV).
- `cupertino_liquid_glass` — multi-layer CustomPainter + spring physics.
- **Decisão:** implementação nativa com `BackdropFilter` (zero dependências adicionais, mantendo o `pubspec` idêntico ao original para máxima compatibilidade de build).

---

## 3. Arquitetura do Clone

### 3.1 Separação clara: motor preservado × UI redesenhada

```
core.dart  ──►  MOTOR  (inalterado em lógica; apenas renomeado canal nativo e prefixos de arquivo)
glass.dart ──►  SISTEMA DE DESIGN LIQUID GLASS (novo)
widgets.dart / main.dart / mobile_screen / tv_screen / player ──► UI em vidro
```

### 3.2 Sistema de design (`lib/glass.dart`)

- `GlassColors` — paleta: accentCyan `#4DE8FF`, accentViolet `#B388FF`, accentRose, espaço profundo, fills de vidro em múltiplas opacidades.
- `GlassSurface` — o bloco base: `ClipRRect` → `BackdropFilter`(blur) → `Container`(fill translúcido + borda + sombra) → brilho especular superior.
- `GlassButton` — escala + brilho no hover/foco, variante accent com gradiente ciano→violeta.
- `GlassTextField` — campo com blur, borda accent no foco, glow.
- `AuroraBackground` — 3 blobs animados (ciano/violeta/rosa) com deriva lenta (24s, reverse), sobre gradiente espacial; aplicado via `MaterialApp.builder` (envolve todas as rotas).
- `GlassDialog`, `GlassChip`, `GradientText`, `buildGlassTheme()`.

### 3.3 Mudanças visuais aplicadas

1. **Fundo:** substituição do preto plano `#090B10` por `AuroraBackground` animado (transparência no scaffold).
2. **Painéis/cards:** cores sólidas escuras → tons translúcidos de branco (8–12% alpha, const-safe `0x14FFFFFF`/`0x1AFFFFFF`) — o vidro deixa a aurora transparecer.
3. **Cartazes de conteúdo (`buildStreamingPosterCard`):** reescritos com `BackdropFilter`, gradiente sobre o poster, badges de qualidade em vidro, indicador "AO VIVO" com gradiente accent, favorito em chip circular, barra de progresso VOD.
4. **Foco TV (`TVFocusableItem`):** escala 1.06 + glow duplo (ciano+violeta) com física `easeOutCubic`.
5. **Login:** cartão principal convertido para `GlassSurface` (blur 28, opacidade 14%, borda 30%).
6. **Diálogos (PIN parental, retomar VOD, teclado virtual):** todos via `GlassDialog` com blur.
7. **Acentos:** ciano `#00E5FF` → `#4DE8FF` (mais vibrante), roxo `#7C4DFF` → `#B388FF` (mais claro, glassy).
8. **Player (OSD):** controles `TVIconButton` em vidro circular com blur.

### 3.4 Compatibilidade de build (idêntica ao original)

- `pubspec.yaml` — mesmas dependências (`http`, `video_player`), SDK `>=3.0.0 <4.0.0`.
- Workflow `build.yml` — mesmo pipeline: Java 17, Flutter stable, gera `android/` via `flutter create`, política de rede HTTP (cleartext), AndroidManifest com Leanback + LargeHeap + Impeller off, `MainActivity.kt` com canal nativo **renomeado para `glass.vision/native`** (evita colisão com o app original), patch ExoPlayer, compila APK release armeabi/arm64.
- Organização Android: `com.glass.vision` / projeto `glassvision` / app label "GlassVision".

---

## 4. Roadmap de Evolução (próximos passos sugeridos)

| Fase | Entrega | Esforço |
|---|---|---|
| Já entregue | Clone funcional com visual Liquid Glass, compila via Actions | — |
| Fase 2 | Adotar `flutter_animate` para transições de rota em mola + parallax de cartazes | Baixo |
| Fase 3 | Ícone/splash screen personalizados (glassmorphic) via `flutter_launcher_icons` | Baixo |
| Fase 4 | Player com `media_kit` (melhor suporte a codecs em TV) substituindo video_player | Médio |
| Fase 5 | EPG completo com timeline (grelha de programação) em painéis de vidro | Médio |
| Fase 6 | Suporte a múltiplas listas/perfis + backup na nuvem | Alto |
| Fase 7 | Shader GLSL personalizado para refração real (distorção lente) no player OSD | Alto |

---

## 5. Validação

- Balanceamento de chaves/parênteses/colchetes: **0 em todos os arquivos**.
- Canal nativo `core.dart` ↔ `MainActivity.kt`: `glass.vision/native` (consistente).
- Assinaturas de widgets preservadas (TVFocusableItem, buildStreamingPosterCard, showParentalPinPrompt, etc.) — as telas compilam sem alterações de chamada.
- Nenhuma dependência nova adicionada — `flutter pub get` resolve exatamente como o original.
