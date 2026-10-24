import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Detecta automaticamente se o app roda em uma TV (Android TV / Google TV /
/// Fire TV) ou em um celular/tablet, e define uma escala de UI adaptativa.
///
/// Detecção (em ordem de confiabilidade):
///  1. MethodChannel nativo: PackageManager.FEATURE_LEANBACK ou
///     uiMode == UI_MODE_TYPE_TELEVISION (padrão oficial do Android).
///  2. Fallback por tamanho de tela: menor largura lógica >= 600dp E orientação
///     landscape => TV/set-top; caso contrário => celular.
///
/// A detecção é feita uma vez no startup e exposta via InheritedWidget —
/// sem diálogos, sem perguntas ao usuário, sem atraso perceptível.
class DeviceDetector {
  static const MethodChannel _channel = MethodChannel("com.unex.play/device");

  /// Retorna true se o dispositivo for uma TV. Nunca lança — em caso de erro
  /// no canal, usa o fallback por [size].
  static Future<bool> isTv(Size size) async {
    try {
      final result = await _channel.invokeMethod<bool>("isTv").timeout(
            const Duration(milliseconds: 800),
          );
      if (result != null) return result;
    } catch (_) {
      // canal indisponível (ex: teste em desktop) — usa fallback abaixo.
    }
    return isTvBySize(size);
  }

  /// Fallback heurístico: TVs e set-top boxes tipicamente reportam uma tela
  /// grande em landscape (>= 600dp de menor lado). Celulares ficam abaixo.
  static bool isTvBySize(Size size) {
    final shortest = size.shortestSide;
    final isLandscape = size.width >= size.height;
    return shortest >= 600 && isLandscape;
  }
}

/// Configuração de dispositivo exposta para a árvore de widgets.
class DeviceConfig extends InheritedWidget {
  final bool isTv;

  /// Verdadeiro em celular/tablet (oposto de isTv).
  bool get isPhone => !isTv;

  /// Fator de escala para texto (via MediaQuery.textScaler).
  /// TV: 1.0 (10-foot UI). Celular: menor, conforme a menor largura.
  final double textScale;

  /// Largura alvo de cada pôster em grid (dp). Usado por
  /// SliverGridDelegateWithMaxCrossAxisExtent para colunas adaptativas.
  final double posterWidth;

  /// Largura recomendada para sidebar/menu lateral (dp).
  final double sideMenuWidth;

  /// Largura recomendada para campos de busca (dp).
  final double searchWidth;

  /// Espaçamento base entre cards (dp).
  final double cardSpacing;

  const DeviceConfig({
    super.key,
    required this.isTv,
    required this.textScale,
    required this.posterWidth,
    required this.sideMenuWidth,
    required this.searchWidth,
    required this.cardSpacing,
    required super.child,
  }) : assert(textScale > 0);

  static DeviceConfig of(BuildContext context) {
    final cfg = context.dependOnInheritedWidgetOfExactType<DeviceConfig>();
    assert(cfg != null, "DeviceConfig não encontrado na árvore");
    return cfg!;
  }

  /// Constrói a configuração a partir do tamanho da tela e da detecção de TV.
  factory DeviceConfig.fromSize(Size size, bool isTv, Widget child) {
    final shortest = size.shortestSide;
    double textScale;
    double posterWidth;
    double sideMenuWidth;
    double searchWidth;
    double cardSpacing;
    if (isTv) {
      // TV: 10-foot UI — tamanhos generosos.
      textScale = 1.0;
      posterWidth = 168;
      sideMenuWidth = 210;
      searchWidth = 320;
      cardSpacing = 16;
    } else {
      // Celular: escala proporcional à menor largura.
      if (shortest < 340) {
        textScale = 0.74;
        posterWidth = 104;
        sideMenuWidth = 150;
        searchWidth = 180;
        cardSpacing = 10;
      } else if (shortest < 380) {
        textScale = 0.80;
        posterWidth = 112;
        sideMenuWidth = 165;
        searchWidth = 200;
        cardSpacing = 11;
      } else if (shortest < 420) {
        textScale = 0.86;
        posterWidth = 122;
        sideMenuWidth = 180;
        searchWidth = 220;
        cardSpacing = 12;
      } else {
        // Tablets grandes / celulares grandes.
        textScale = 0.92;
        posterWidth = 134;
        sideMenuWidth = 195;
        searchWidth = 250;
        cardSpacing = 14;
      }
    }
    return DeviceConfig(
      isTv: isTv,
      textScale: textScale,
      posterWidth: posterWidth,
      sideMenuWidth: sideMenuWidth,
      searchWidth: searchWidth,
      cardSpacing: cardSpacing,
      child: child,
    );
  }

  @override
  bool updateShouldNotify(DeviceConfig oldWidget) =>
      isTv != oldWidget.isTv || textScale != oldWidget.textScale;
}
