# ESCOPO DE CRIAÇÃO — APLICATIVO IPTV UNEX PLAY (Flutter / Dart)

> Documento mestre de escopo. Consolida: (1) documento de funcionamento lógico do UNEX PLAY, (2) engenharia comercial de players IPTV (TiviMate / IPTV Smarters / XCIPTV / SmartOne) e (3) requisitos do produto definidos pelo cliente. Serve de base para implementação, testes e CI/CD via GitHub Actions.

---

## 1. IDENTIFICAÇÃO DO PROJETO

| Item | Definição |
|---|---|
| Nome do produto | UNEX PLAY |
| Plataforma alvo principal | **Android TV** (set-top boxes, Fire TV, TV com Android TV) |
| Plataforma secundária | Android mobile (compatibilidade temporária) |
| Stack | **Flutter 3.x / Dart 3.x** |
| Repositório | GitHub (branch `main` → builds via **GitHub Actions**) |
| Entrega | Código-fonte + workflow de CI que compila APK(s) e disponibiliza como artefato/release |
| Modelo de entrada do usuário | **DNS (host) + Usuário + Senha** (padrão Xtream Codes), com fallback para link M3U e código de ativação de 6 dígitos |

---

## 2. OBJETIVO DO PRODUTO

Aplicativo reprodutor de IPTV que:
1. Recebe credenciais do usuário (DNS + user + pass), valida e carrega o catálogo.
2. Processa listas grandes (até ~150.000 itens) **sem travar a UI**.
3. Separa o conteúdo em **Canais ao Vivo, Filmes e Séries** de forma estrita e única.
4. Reproduz streams instáveis/variados com **decodificação por hardware** e tolerância a falhas.
5. Oferece **início (recomendações + histórico + mais assistidos)**, **controle parental (PIN padrão 0000)** e **teste de velocidade embutido**.

---

## 3. REQUISITOS FUNCIONAIS OBRIGATÓRIOS

### 3.1 Tela de Login / Ativação
- Campos: **DNS (ex: `http://servidor.com:8080`)**, **Usuário**, **Senha**.
- Botão "Entrar" + link "Testar velocidade da conexão" (abre o speed test).
- Opção avançada: entrar por **link M3U direto** ou **código de ativação de 6 dígitos** (valida em endpoint externo que retorna a URL M3U).
- Ao validar: extrai host/user/pass e **tenta primeiro a API Xtream Codes** (`player_api.php`); se 404/erro, cai para download/parse da lista M3U (fallback inteligente).
- Credenciais salvas localmente de forma segura (flutter_secure_storage) para abertura automática futura.
- Tratamento de falha: mensagem amigável + botão "Tentar novamente"; nunca fica em loading infinito.

### 3.2 Teste de Velocidade Embutido (Speed Test)
- Mede **latência (ping)**, **jitter** e **velocidade de download** (Mbps) contra o próprio DNS do usuário ou servidor de referência.
- Tela dedicada com medidor animado; resultado exibido em Mbps + classificação (Ruim / Razoável / Boa / Excelente).
- Acessível na tela de login (antes de entrar) e no menu de configurações.
- Recomendação automática: se velocidade < limite sugerido, avisa o usuário sobre possível instabilidade nos canais HD/4K.

### 3.3 Controle Parental
- **PIN padrão: `0000`** (usuário pode alterar nas configurações).
- Itens adultos (`isAdult=true`, detectado por palavra-chave no grupo/nome) ficam ocultos/marcados e só abrem após digitar o PIN.
- Sessão de desbloqueio adulto: após desbloquear uma vez, permanece liberado por tempo de sessão configurável; trava novamente ao sair do app.
- Tela de diálogo PIN estilizada para TV (navegável por controle remoto).

### 3.4 Abas Principais (menu lateral na TV)

#### Aba 1 — INÍCIO (Home / Dashboard)
- **Recomendações em destaque**: banner rotativo (5 itens, 5s cada) com base em TMDB (match fuzzy com a lista do usuário, cache 24h).
- **Histórico de canais**: últimos canais ao vivo assistidos (com horário).
- **Canais mais assistidos**: ranking por frequência de visualização (top N).
- **Continuar assistindo**: filmes/séries VOD com progresso salvo (retomada).
- Atalhos: "Canais favoritos", "Últimos filmes adicionados".

#### Aba 2 — TV AO VIVO
- Coluna lateral de **categorias/grupos** (Esportes, Notícias, Infantil, Filmes e Séries, Documentários, etc.).
- Grid/lista de canais com logo (`tvg-logo`), nome, número (opcional) e qualidade.
- Favoritos (coração) e busca por nome de canal.
- Ao abrir: player em **modo ao vivo** (sem seek, zapping com ↑/↓).

#### Aba 3 — FILMES
- Divididos por **gênero/categoria** (Lançamentos, Ação, Comédia, Terror, etc.).
- Cada filme: poster, título (com ano entre parênteses quando disponível), qualidade (HD/FHD/4K extraída do nome).
- Tela de detalhes: poster ampliado, sinopse (via TMDB quando disponível), ano, duração, nota, botão "Assistir".
- Player em **modo VOD** (seek, avanço/retrocesso, retomada de progresso). **Sem botão "Episódios".**

#### Aba 4 — SÉRIES (organização rigorosa)
- Cada série é **UM ÚNICO item** na lista (não um ícone por episódio).
- Agrupamento por: **Série → Temporada (S01, S02...) → Episódio (E01, E02...)**.
- Detecção por regex no título: `S(\d+)E(\d+)` e `T(\d+)E(\d+)`.
- Capa da série = logo **mais frequente** entre os episódios (evita capa aleatória).
- Tela de detalhes: poster, sinopse, abas de temporada, lista de episódios com nome/número.
- Player VOD com **botão "Episódios"** (navega sem sair do player) e sugestão automática do próximo episódio ao final.

#### Abas auxiliares
- **Favoritos**: canais/filmes/séries marcados (apenas referenciam itens já classificados).
- **Histórico**: últimos assistidos + progresso de VOD.
- **Configurações**: alterar PIN parental, teste de velocidade, limpar cache, escolha de player (Hardware/Software/Nativo), sair/ trocar conta.

---

## 4. REGRAS DE OURO DE ORGANIZAÇÃO (não negociáveis)

1. A **URL do stream define o tipo**: `/live/` ou `.ts` = SEMPRE canal ao vivo. Padrão Xtream: `/movie/` = Filme, `/series/` = Série. Extensões `.mp4/.mkv/.avi` = VOD.
2. Um item tem **UM ÚNICO tipo** e aparece em **UMA ÚNICA aba principal**.
3. Séries agrupadas por temporada/episódio; filmes e canais são itens individuais.
4. O player comporta-se diferente por tipo: ao vivo = zapping (sem seek); VOD = seek.
5. O botão **"Episódios" só existe em séries**.
6. **Cache sempre presente**: app abre rápido mesmo sem internet no momento.
7. Todo comando do controle remoto tem resposta; **nunca existe estado sem foco**.
8. Itens adultos sempre protegidos por PIN (padrão `0000`).

---

## 5. ARQUITETURA TÉCNICA

### 5.1 Gerenciamento de estado e camadas
- State management: **Riverpod** (ou Bloc, a definir) — separação clara entre UI / Domain / Data.
- Camadas:
  - `data/` — parser M3U, cliente Xtream API, repositórios, banco local.
  - `domain/` — modelos (`StreamItem`, `SeriesGroup`, `ContentType`, `Channel`, `Movie`, `Serie`, `Episode`).
  - `presentation/` — telas, widgets navegáveis por controle remoto (foco), OSD do player.

### 5.2 Parser M3U (robusto, nível comercial)
- **Leitura por stream linha a linha** (BufferedReader) dentro de **Isolate** — nunca `response.text()` integral (evita OOM em listas de 15–50 MB / 50k–150k linhas).
- **Máquina de estados** (sem regex pesado por linha):
  - `#EXTM3U` → extrai `x-tvg-url`/`url-tvg` (EPG).
  - `#EXTINF:` → extrai `tvg-id`, `tvg-name`, `tvg-logo`, `group-title`, `catchup`/`catchup-days`, nome de exibição (após última vírgula).
  - `#EXTVLCOPT` / `#KODIPROP` → acumula headers HTTP / chaves DRM (Widevine/ClearKey).
  - Linha `http/rtmp` → associa URL ao item; separa **pipe headers** (`|User-Agent=...&Referer=...`) da URL limpa; classifica; salva em lote (batch).
- **Classificação**: URL como fonte da verdade → fallback por grupo ("filme"/"série") → heurística de nome.
- **Agrupamento de séries**: regex `S(\d+)E(\d+)` / `T(\d+)E(\d+)` no título → consolida em `SeriesGroup`.
- **Persistência indexada**: Bulk Insert de 1.000 em 1.000 em **Isar / Drift (SQLite)**. UI consulta com paginação (`LIMIT 50 OFFSET 0`) → abertura instantânea até em TV Box com 1 GB RAM. Capacidade alvo: ~18.000–150.000 itens.

### 5.3 Integração Xtream Codes API (prioritária)
- Ao receber `get.php?username=...&password=...` ou credenciais DNS+user+pass, tenta `player_api.php`:
  - `get_live_categories`, `get_live_streams`, `get_vod_streams`, `get_series`.
  - Episódios carregados **sob demanda** (`get_series_info&series_id=X`) ao abrir a série.
- Vantagens: ~10x mais rápido, JSON já separado por tipo, com sinopse/IMDb/capa HD/elenco/trailer.
- **Fallback**: 404/erro → parser M3U em stream.

### 5.4 Motor de Reprodução (Player)
- Engine principal: **Media3 (ExoPlayer)** via `video_player` ou `media_kit` (libmpv/FFmpeg) — padrão-ouro em Flutter para IPTV.
- Fallback: **LibVLC/ijkplayer (FFmpeg)** para `.ts` brutos com pacotes corrompidos ou codecs raros (AC3/E-AC3/DTS, HEVC/H.265).
- **Tentativa em sequência de headers**: HLS → VLC → XCIPTV → sem headers. Timeouts: ~6s (ao vivo), ~12s (VOD).
- **Estratégias críticas obrigatórias**:
  - **A. Redirect 302 / cross-protocol**: `setAllowCrossProtocolRedirects(true)` (HTTPS↔HTTP).
  - **B. Buffer "Fast Zapping + Deep Buffer"**: `minBufferForPlayback` 1,0–1,5s (abertura instantânea); `bufferForPlaybackAfterRebuffer` 3–5s; `maxBufferMs` 15–30s.
  - **C. Reconexão silenciosa automática** (modo Live): em EOF/erro 500/502/timeout → congela último frame, spinner pequeno, retenta 3–5x com backoff progressivo (1s, 2s, 4s), recarregando URL do zero (novo token de load balancer) — sem tela de erro imediata.
  - **D. User-Agent spoofing**: padrão conhecido (`IPTVSmartersPlayer`, `VLC/3.0.20 LibVLC/3.0.20`, `Lavf/60.3.100`), sobrescrevível pelo `|User-Agent=` da linha M3U.
- **Roteador de mídia por formato**: `.m3u8`→engine HLS; `.ts`→TsExtractor/media_kit; `.mp4/.mkv`→modo seekable com salvamento de progresso.

### 5.5 Controles do Player (OSD + remoto)
- OK/Enter → Play/Pause (ou abre OSD).
- ←/→ curto → ±10s (só VOD).
- ←/→ segurar → avanço exponencial 10→20→40→80→160s (overlay de tempo).
- ↑/↓ → volume (barra na tela); em canais ao vivo = **zapping** (troca de canal).
- VOLTAR 1 toque → fecha OSD; 2 toques → sai do player (filme/série volta aos detalhes; canal volta à lista).
- OSD auto-esconde em 3–5s; botões navegáveis por foco: Voltar, Retroceder, Play/Pause, Avançar, Tela cheia, Escala (Original/Zoom/Esticar), "Canais" (ao vivo) ou "Episódios" (séries).

### 5.6 Armazenamento Local
- Credenciais (secure storage), lista parseada (Isar/Drift), favoritos (IDs), histórico + progresso VOD, PIN parental (padrão `0000`) + estado de desbloqueio, modo dispositivo (TV), banners TMDB (5 + timestamp, validade 24h), ranking de canais mais assistidos (contador de visualizações).

### 5.7 Teste de Velocidade (implementação)
- Módulo `speed_test`: ping repetido ao DNS (latência média + jitter), download de payload de tamanho conhecido (ou arquivo de teste do próprio servidor) medido em chunks → cálculo de Mbps em tempo real.
- UI: medidor circular animado, resultado final com classificação e dica de qualidade recomendada (SD/HD/FHD/4K).

---

## 6. ESTRUTURA DE PASTAS (SUGERIDA)

```
lib/
├── main.dart                    # bootstrap, tema, rotas
├── app_theme.dart               # tokens: área segura (overscan), foco TV
├── core/
│   ├── models.dart              # StreamItem, SeriesGroup, ContentType...
│   ├── stream_engine.dart       # SharedStreamEngine (player singleton)
│   └── storage.dart             # AppStorage + secure storage
├── data/
│   ├── xtream_api_client.dart   # player_api.php + fallback
│   ├── m3u_parser.dart          # máquina de estados em Isolate
│   ├── m3u_stream_reader.dart   # leitura linha a linha
│   ├── speed_test_service.dart  # teste de velocidade
│   ├── tmdb_service.dart        # banners/sinopse (cache 24h)
│   └── repositories/            # canais, filmes, séries, favoritos, histórico
├── db/
│   └── database.dart            # Isar/Drift (bulk insert + paginação)
├── presentation/
│   ├── login/                   # DNS+user+pass, speed test, opções M3U/código
│   ├── home/                    # Início: recomendações, histórico, mais assistidos
│   ├── live_tv/                 # Categorias + grid de canais
│   ├── movies/                  # Gêneros + detalhes do filme
│   ├── series/                  # Lista de séries + temporadas + episódios
│   ├── player/                  # Tela cheia, OSD, gaveta episódios/canais
│   ├── favorites/ + history/
│   └── settings/                # PIN parental, speed test, cache, player
└── widgets/
    ├── tv_focusable_item.dart   # item navegável por remoto
    ├── pin_dialog.dart          # diálogo PIN parental (TV)
    └── banner_rotator.dart      # destaque TMDB (5 itens, 5s)
```

---

## 7. CI/CD — GITHUB ACTIONS

- Workflow em `.github/workflows/build.yml`:
  - Trigger: push em `main` / tag de release.
  - Steps: checkout → setup Flutter (`subosito/flutter-action`) → `flutter pub get` → `flutter analyze` → `flutter test` → `flutter build apk --release` (e `--split-per-abi` opcional).
  - Upload do APK como **artefato** e, em tag de release, publicação no GitHub Releases.
  - Assinatura: keystore via GitHub Secrets (nunca versionar o `.jks`).

---

## 8. FASES DE ENTREGA (ROADMAP MVP)

| Fase | Entrega |
|---|---|
| **F1 — Base** | Projeto Flutter, tema TV, tela login (DNS+user+pass), Xtream API + fallback M3U, parser em Isolate, banco local |
| **F2 — Catálogo** | Abas TV Ao Vivo (categorias+canais), Filmes (gêneros), Séries (agrupamento temporada/episódio), Favoritos/Histórico |
| **F3 — Player** | ExoPlayer/media_kit, OSD, controles remoto, buffer trifásico, reconexão automática, UA spoofing, progresso VOD |
| **F4 — Início** | Recomendações TMDB (banner), histórico de canais, canais mais assistidos, continuar assistindo |
| **F5 — Extras** | Controle parental (PIN 0000), teste de velocidade, configurações, CI/CD GitHub Actions |

---

## 9. CRITÉRIOS DE ACEITE (resumo)

- [ ] Login com DNS+usuário+senha funciona e persiste sessão.
- [ ] Lista com 50.000+ itens carrega sem travar a UI (parse em Isolate + banco indexado).
- [ ] Conteúdo estritamente separado: cada item em uma única aba.
- [ ] Séries agrupadas corretamente por temporada/episódio (um ícone por série).
- [ ] Player abre canal ao vivo em <2s, suporta zapping, e reconecta sozinho em queda.
- [ ] Filmes/séries VOD retomam de onde pararam.
- [ ] Conteúdo adulto bloqueado por PIN (padrão `0000`).
- [ ] Teste de velocidade presente e funcional na tela de login e configurações.
- [ ] Aba Início mostra recomendações, histórico e canais mais assistidos.
- [ ] `flutter build apk --release` gera APK válido via GitHub Actions.
- [ ] **Usabilidade TV**: memória de foco preservada ao voltar de detalhes; sem perda de foco em modais/listas; wrap-around em listas de canais.
- [ ] **Login sem atrito**: QR Code/código curto disponível; busca instantânea por voz e teclado compacto (resultados a cada letra).
- [ ] **TV ao vivo**: zapping com ↑/↓ em 1–2 cliques, guia sobreposto sem interromper áudio, recall de último canal, entrada numérica direta, segurar OK para favoritar.
- [ ] **VOD**: "Continuar Assistindo" retoma do segundo exato, pular abertura com foco automático, autoplay próximo episódio (contagem 5s), gaveta de episódios dentro do player, memória de áudio/legenda.
- [ ] **Back Stack previsível**: 1 clique Voltar = fecha OSD; 2 cliques = sai do player; Voltar no menu = confirma saída com foco em [Não].
- [ ] **Performance percebida**: skeleton screens com foco navegável durante carga, debounce de 1,2s em pré-visualizações, UI a 60fps em TV Box modesto.

---

## 10. USABILIDADE PARA ANDROID TV (LEAN-BACK EXPERIENCE)

> Princípio-base: o usuário está no sofá (postura relaxada) e interage de forma **sequencial e indireta** pelo controle remoto. O app deve ser 100% operável com 6 botões básicos (D-Pad + OK + Voltar + Play/Pause) e aproveitar botões extras (CH+/CH-, numéricos 0-9) quando presentes em controles de TV (Samsung/LG/TCL/Sony/Philips). Regra de ouro: o movimento na tela corresponde exatamente à direção física pressionada.

### 10.1 Gestão Inteligente de Foco (coração da navegação)
- **Memória de foco (Focus Restoration)**: ao entrar em detalhes e voltar, o foco retorna exatamente ao item/celular anterior (ex: 5º filme da 3ª fileira) — nunca reinicia no topo.
- **Geometria previsível**: botões e cards em **grades ortogonais** rigorosamente alinhadas; quando necessário, definir `nextFocusUp/Down/Left/Right` explicitamente para evitar saltos diagonais.
- **Zero perda de foco (Focus Loss Prevention)**: ao fechar modal, carregar lista ou remover item (ex: desfavoritar), o foco é transferido imediatamente para o item vizinho — nunca fica tela sem foco.
- **Loop infinito inteligente (Wrap-around)**: em listas de canais, categorias e abas de temporada, ao chegar no fim e apertar ↓ o foco volta ao primeiro item (e vice-versa).
- **Key-Repeat Throttling**: ao segurar seta para rolar rápido, limitar a ~150–200ms por card e **pausar carregamento de imagens pesadas/Hero** até soltar o botão (evita foco disparado e travamento).
- **Zona de foco estática (Fixed Scroll Anchor)**: ao navegar para a direita numa fileira, o quadro de foco permanece parado na primeira posição à esquerda, e a fita de pôsteres desliza por baixo (olho fixo num único ponto).

### 10.2 Eliminação do Atrito de Digitação (Login, Busca, PIN)
- **Autenticação sem remoto (QR Code / código curto)**: na tela de login, exibir QR Code grande (alto contraste preto/branco) + código curto (ex: `A4F-92B`); usuário escaneia com o celular, faz login no smartphone e a TV entra automaticamente via pareamento em nuvem. (Mantém login DNS+user+pass como alternativa.)
- **Teclado próprio compacto**: na busca, teclado minimalista em grade compacta 6x6 (ou linha A-Z + 0-9) no canto esquerdo, mantendo resultados visíveis à direita em tempo real — evitar teclado padrão do sistema que cobre 50% da tela.
- **Busca instantânea (Zero-Click Search)**: resultados de canais/filmes/séries atualizados a cada letra, sem botão "Pesquisar"; com 2–3 letras o conteúdo já aparece a um clique para a direita.
- **Atalhos de edição**: botões dedicados nas extremidades do teclado para "Espaço" e "Apagar tudo" em um clique.
- **Busca por voz (Speech-to-Text)**: ícone de microfone como **primeiro elemento focável** da tela de busca, acionando reconhecimento de voz nativo do controle Android TV.

### 10.3 Usabilidade Específica para TV Ao Vivo
- **Troca direta com setas verticais**: em tela cheia (menu oculto), ↑/↓ troca imediatamente de canal (zapping) ou abre lista rápida já posicionada no canal vizinho — troca em 1–2 cliques.
- **Guia sobreposto transparente (In-Player Mini-EPG)**: ao apertar ← ou OK durante canal ao vivo, abre gaveta lateral translúcida (preto/branco) com categorias e canais, **sem interromper vídeo/áudio**; só troca ao confirmar OK.
- **Último canal (Recall / Back-Swap)**: atalho no player (duplo-clique ou botão dedicado) alterna instantaneamente entre canal atual e último assistido.
- **Entrada numérica direta**: se o controle tiver números, digitar `1 0 5` vai direto ao canal 105; para controles minimalistas, botão `[123]` no guia abre mini-teclado numérico para pular ao número desejado.
- **Segurar OK para favoritar**: segurar OK ~1s sobre qualquer canal adiciona/remove de Favoritos (ícone estrela/coração), sem entrar em menus.

### 10.4 Usabilidade no Catálogo e Player de Filmes/Séries (VOD)
- **Trilho "Continuar Assistindo"**: sempre a **primeira fileira** da tela inicial (abaixo do destaque); clicar no item **inicia o vídeo direto do segundo exato** onde parou, sem abrir tela de sinopse.
- **Automação de maratona (Binge-Watching)**:
  - Botão "Pular Abertura/Recapitulação" (alto contraste) surge no canto inferior direito e **já recebe foco automaticamente** (basta OK).
  - **Transição de episódio**: nos últimos 15s dos créditos, reduz vídeo a quadro menor ou exibe card com contagem regressiva de 5s para iniciar o próximo episódio automaticamente.
- **Trickplay com miniaturas**: ←/→ curto = ±10s; segurar = acelera progressivamente (2x/4x/8x) com **miniatura da cena** acima da barra de progresso branca.
- **Memória de áudio/legenda**: se o usuário escolheu "Dublado" ou ativou legenda no Ep. 1, preferência salva automaticamente para todos os episódios seguintes da série (e globalmente no perfil).
- **Seletor de episódios dentro do player**: apertar ↓ durante reprodução revela gaveta horizontal com os demais episódios — sem sair do player.

### 10.5 Fluxo do Botão Voltar (Back Stack) e Prevenção de Erros
- **Escada de retorno previsível**:
  - Player com OSD aberto → 1º clique em Voltar **só esconde os controles** (continua reproduzindo); 2º clique fecha o vídeo e volta ao catálogo/lista.
  - Em fileira profunda do catálogo → Voltar leva o foco de volta suavemente ao **Topo da Página / Menu Principal** (atalho de retorno ao topo), não fecha o app.
  - No Menu Principal → Voltar exibe modal centralizado ("Deseja sair? [Sim] [Não]") com foco inicial padrão em **[Não]** (ou saída com segundo clique rápido + aviso na tela).
- **Tratamento elegante de falhas no player**: oscilação de sinal/internet por ~3s → reconectar silenciosamente (até 3x) com indicador discreto; se falhar definitivamente, manter usuário no player permitindo ↑/↓ para trocar ao próximo canal funcional — sem mensagem de erro que trave o foco.

### 10.6 Feedback Sensorial e Performance Percebida
- **UI Audio Ticks**: sons curtos, graves e secos ao mover o foco; som ligeiramente distinto ao confirmar com OK. **Opção de desativar nas configurações.**
- **Skeleton Screens monocromáticos**: durante carregamento, exibir estrutura dos cards em cinza escuro (`#1A1A1A`) com shimmer suave (`#262626`) e **permitir navegação pelo foco imediatamente** — nunca roda giratória bloqueante no centro.
- **Debounce de pré-visualização (1,2–1,5s)**: ao parar sobre um filme (trailer/metadados pesados ao fundo), aguardar 1,2s de inatividade antes de disparar — garante **60fps constantes** mesmo em TV Boxes de hardware modesto.

---

## 11. RESUMO DO ESCOPO

O **UNEX PLAY** é um app Flutter/Dart para Android TV com login por **DNS + usuário + senha** (padrão Xtream, com fallback para M3U/código de 6 dígitos), **teste de velocidade embutido** e **controle parental com PIN padrão 0000**. Após o login, o usuário encontra 4 abas principais: **Início** (recomendações TMDB em banner, histórico de canais, canais mais assistidos e continuar assistindo), **TV Ao Vivo** (categorias laterais + grid de canais com zapping), **Filmes** (divididos por gênero, com tela de detalhes e player VOD) e **Séries** (rigorosamente agrupadas em série → temporada → episódio, com botão "Episódios" no player). Tecnicamente, adota parser M3U por stream em Isolate + máquina de estados (sem regex pesado), persistência indexada em Isar/Drift com bulk insert e paginação, integração prioritária com API Xtream Codes, player baseado em Media3/ExoPlayer (com fallback LibVLC/FFmpeg), buffer trifásico "fast zapping + deep buffer", reconexão automática com backoff progressivo, User-Agent spoofing e suporte a headers por pipe/DRM. O código é entregue pronto para GitHub com workflow de **GitHub Actions** que compila e assina o APK automaticamente. Em **usabilidade (lean-back)**, o app é 100% operável com 6 botões do controle remoto e adota gestão inteligente de foco (memória de foco, zero perda de foco, wrap-around, throttle de repetição, âncora de rolagem fixa), eliminação de atrito de digitação (QR Code/código curto no login, busca instantânea por voz/teclado compacto), recursos de TV ao vivo (zapping em 1–2 cliques, guia sobreposto sem interromper áudio, recall de último canal, entrada numérica, segurar OK para favoritar), automação de VOD (continuar assistindo retoma do segundo exato, pular abertura com foco automático, autoplay de próximo episódio, gaveta de episódios dentro do player, memória de áudio/legenda), back stack previsível do botão Voltar e performance percebida (skeleton screens com foco navegável, debounce de 1,2s, UI a 60fps). O escopo está completo e alinhado com o padrão comercial de players como TiviMate, IPTV Smarters e XCIPTV.
