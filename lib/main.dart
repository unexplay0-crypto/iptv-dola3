import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'core/storage.dart';
import 'presentation/login/login_screen.dart';
import 'presentation/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStorage.instance.init();
  runApp(const UnexPlayApp());
}

class UnexPlayApp extends StatelessWidget {
  const UnexPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "UNEX PLAY",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: AppStorage.instance.isLoggedIn ? const MainShell() : const LoginScreen(),
      routes: {
        "/login": (_) => const LoginScreen(),
        "/home": (_) => const MainShell(),
      },
    );
  }
}
