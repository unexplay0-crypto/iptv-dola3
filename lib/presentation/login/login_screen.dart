import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../core/device_config.dart';
import '../../core/storage.dart';
import '../../core/models.dart';
import '../../data/repositories/content_repository.dart';
import '../main_shell.dart';
import '../../widgets/tv_focusable_item.dart';
import '../../widgets/virtual_keyboard.dart';
import 'm3u_login_screen.dart';

/// Tela de login em painel de vidro (liquid glass).
/// O teclado virtual do app SÓ abre quando o usuário seleciona (toca / dá OK)
/// em um campo de digitação. Cada campo é readOnly (nunca abre o teclado do
/// sistema). O teclado virtual edita o controlador do campo ativo.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _dnsCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  TextEditingController? _active; // campo com teclado aberto
  bool _loading = false;
  String _status = "";
  String _error = "";

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = "";
      _status = "Iniciando...";
      _active = null;
    });
    try {
      final creds = AppCredentials(
        dns: _dnsCtrl.text.trim(),
        username: _userCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      if (creds.dns.isEmpty || creds.username.isEmpty || creds.password.isEmpty) {
        throw Exception("Informe DNS, usuário e senha.");
      }
      await AppStorage.instance.saveCredentials(creds);
      final repo = ContentRepository();
      await repo.loadCatalog(onStatus: (s) {
        if (mounted) setState(() => _status = s);
      });
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()));
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll("Exception: ", "");
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ===== Painel de vidro (logo + campos) =====
                      GlassContainer(
                        opacity: 0.10,
                        blur: 22,
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: AppTheme.accentGradient,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.accent.withValues(alpha: 0.45),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.play_arrow_rounded,
                                  color: Colors.black, size: 40),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              "UNEX PLAY",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Conecte-se com sua lista",
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 14),
                            ),
                            const SizedBox(height: 28),
                            // Campos adaptativos: na TV abrem o teclado
                            // virtual do app; no celular, o teclado nativo.
                            AdaptiveInputField(
                              controller: _dnsCtrl,
                              label: "DNS (ex: http://servidor.com:8080)",
                              hint: "http://",
                              keyboardType: TextInputType.url,
                              active: _active == _dnsCtrl,
                              onSelect: () => setState(() => _active = _dnsCtrl),
                            ),
                            const SizedBox(height: 14),
                            AdaptiveInputField(
                              controller: _userCtrl,
                              label: "Usuário",
                              active: _active == _userCtrl,
                              onSelect: () => setState(() => _active = _userCtrl),
                            ),
                            const SizedBox(height: 14),
                            AdaptiveInputField(
                              controller: _passCtrl,
                              label: "Senha",
                              obscureText: true,
                              active: _active == _passCtrl,
                              onSelect: () => setState(() => _active = _passCtrl),
                            ),
                            const SizedBox(height: 22),
                            if (_loading) ...[
                              const CircularProgressIndicator(
                                  color: AppTheme.accent),
                              const SizedBox(height: 12),
                              Text(_status,
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13)),
                            ] else ...[
                              TVFocusableItem(
                                autofocus: true,
                                borderRadius: AppTheme.radiusMd,
                                onTap: _login,
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.accentGradient,
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMd),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.accent
                                            .withValues(alpha: 0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "CONECTAR",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        letterSpacing: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const M3ULoginScreen())),
                                child: const Text(
                                  "Usar lista M3U",
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                      decoration: TextDecoration.underline),
                                ),
                              ),
                            ],
                            if (_error.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.danger.withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusMd),
                                  border: Border.all(
                                      color: AppTheme.danger
                                          .withValues(alpha: 0.4)),
                                ),
                                child: Text(_error,
                                    style: const TextStyle(
                                        color: AppTheme.danger, fontSize: 13),
                                    textAlign: TextAlign.center),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // ===== Teclado virtual SÓ na TV (no celular usa o nativo) =====
                      if (_active != null && DeviceConfig.of(context).isTv)
                        VirtualKeyboard(
                          controller: _active!,
                          obscureText: _active == _passCtrl,
                          onClose: () => setState(() => _active = null),
                          onSubmit: () => setState(() => _active = null),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
