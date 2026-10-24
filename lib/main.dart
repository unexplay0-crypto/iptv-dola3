import 'package:flutter/material.dart';
import 'app_theme.dart';
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
  // Roda sem await, sem spinner, sem bloquear a UI. Se o cache tiver menos de
  // 48h, é no-op instantânea. Se estiver vencido, baixa e compara com o
  // catálogo local em segundo plano.
  if (AppStorage.instance.isLoggedIn) {
    TrendingService.instance.refreshIfStale();
  }
}

class UnexPlayApp extends StatelessWidget {
  const UnexPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "UNEX PLAY",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
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
