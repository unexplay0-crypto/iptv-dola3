import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'core/device_config.dart';
import 'core/storage.dart';
import 'data/trending_service.dart';
import 'widgets/fast_image.dart';
import 'presentation/login/login_screen.dart';
import 'presentation/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Otimização de miniaturas: cache maior + decode em tamanho de exibição +
  // conexões HTTP com keep-alive. Aplica ANTES de qualquer imagem carregar.
  await ImagePerfConfig.apply();
  await AppStorage.instance.init();
  runApp(const UnexPlayApp());
  // Atualização IMPERCEPTÍVEL de recomendações (trending) em background.
  if (AppStorage.instance.isLoggedIn) {
    TrendingService.instance.refreshIfStale();
  }
}

class UnexPlayApp extends StatefulWidget {
  const UnexPlayApp({super.key});

  @override
  State<UnexPlayApp> createState() => _UnexPlayAppState();
}

class _UnexPlayAppState extends State<UnexPlayApp> {
  /// null = detecção nativa em andando (usa fallback por tamanho, imediato).
  bool? _isTv;

  @override
  void initState() {
    super.initState();
    _detectDevice();
  }

  /// Detecção automática TV vs celular, sem qualquer intervenção do usuário.
  /// Usa primeiro o fallback por tamanho (síncrono, sem atraso) e, quando o
  /// canal nativo responde, atualiza se o resultado diferir.
  Future<void> _detectDevice() async {
    final view = PlatformDispatcher.instance.views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    final isTv = await DeviceDetector.isTv(size);
    if (mounted) setState(() => _isTv = isTv);
  }

  @override
  Widget build(BuildContext context) {
    final view = PlatformDispatcher.instance.views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    // Fallback imediato enquanto o canal nativo não responde (≈1 frame).
    final isTv = _isTv ?? DeviceDetector.isTvBySize(size);

    return MaterialApp(
      title: "UNEX PLAY",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // builder aplica DeviceConfig + escala de texto a TODAS as rotas.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final cfg = DeviceConfig.fromSize(
          mq.size,
          isTv,
          child ?? const SizedBox.shrink(),
        );
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(cfg.textScale),
          ),
          child: cfg,
        );
      },
      home: AppStorage.instance.isLoggedIn
          ? const MainShell()
          : const LoginScreen(),
      routes: {
        "/login": (_) => const LoginScreen(),
        "/home": (_) => const MainShell(),
      },
    );
  }
}
