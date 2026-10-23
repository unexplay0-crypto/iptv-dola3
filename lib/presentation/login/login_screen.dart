import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../core/storage.dart';
import '../../core/models.dart';
import '../../data/repositories/content_repository.dart';
import '../main_shell.dart';
import '../../widgets/tv_focusable_item.dart';

/// Tela de login simplificada e limpa.
/// Logo + nome no topo, 3 campos (DNS, usuário, senha), botão Conectar
/// e um botão discreto "Usar lista M3U" que expande o campo de link M3U.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _dnsCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _m3uCtrl = TextEditingController();
  bool _showM3u = false;
  bool _loading = false;
  String _status = "";
  String _error = "";

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = "";
      _status = "Iniciando...";
    });
    try {
      final creds = AppCredentials(
        dns: _dnsCtrl.text.trim(),
        username: _userCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        m3uUrl: _showM3u ? _m3uCtrl.text.trim() : null,
      );
      if (creds.dns.isEmpty && (creds.m3uUrl?.isEmpty ?? true)) {
        throw Exception("Informe o DNS ou um link M3U.");
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
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.ambientGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo + nome (topo central)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withValues(alpha: 0.4),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.black, size: 44),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "UNEX PLAY",
                        style: TextStyle(
                          fontSize: 34,
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
                      const SizedBox(height: 32),
                      // Campos
                      _field("DNS (ex: http://servidor.com:8080)", _dnsCtrl,
                          TextInputType.url),
                      const SizedBox(height: 14),
                      _field("Usuário", _userCtrl, TextInputType.text),
                      const SizedBox(height: 14),
                      _field("Senha", _passCtrl, TextInputType.visiblePassword,
                          obscure: true),
                      const SizedBox(height: 14),
                      // Campo M3U (expansível)
                      if (_showM3u) ...[
                        _field("Link M3U", _m3uCtrl, TextInputType.url),
                        const SizedBox(height: 14),
                      ],
                      if (_loading) ...[
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(color: AppTheme.accent),
                        const SizedBox(height: 12),
                        Text(_status,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13)),
                      ] else ...[
                        // Botão Conectar
                        TVFocusableItem(
                          autofocus: true,
                          borderRadius: AppTheme.radiusMd,
                          onTap: _login,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: AppTheme.accentGradient,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppTheme.accent.withValues(alpha: 0.35),
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
                        const SizedBox(height: 14),
                        // Botão discreto: usar lista M3U
                        TextButton(
                          onPressed: () =>
                              setState(() => _showM3u = !_showM3u),
                          child: Text(
                            _showM3u
                                ? "Voltar ao modo DNS"
                                : "Usar lista M3U",
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(
                                color: AppTheme.danger.withValues(alpha: 0.4)),
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, TextInputType type,
      {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.surface.withValues(alpha: 0.8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: const BorderSide(color: AppTheme.accent, width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
    );
  }
}
