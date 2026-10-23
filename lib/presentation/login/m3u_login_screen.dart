import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../core/storage.dart';
import '../../core/models.dart';
import '../../data/repositories/content_repository.dart';
import '../main_shell.dart';
import '../../widgets/tv_focusable_item.dart';

/// Tela exclusiva para login via link M3U (apenas o campo de URL).
/// Carrega o catálogo M3U e navega para o app. Funciona exatamente como
/// o login por DNS/usuário/senha, mas aceita apenas a lista M3U.
class M3ULoginScreen extends StatefulWidget {
  const M3ULoginScreen({super.key});

  @override
  State<M3ULoginScreen> createState() => _M3ULoginScreenState();
}

class _M3ULoginScreenState extends State<M3ULoginScreen> {
  final _m3uCtrl = TextEditingController();
  bool _loading = false;
  String _status = "";
  String _error = "";

  Future<void> _connect() async {
    final url = _m3uCtrl.text.trim();
    if (url.isEmpty) {
      setState(() => _error = "Cole o link da sua lista M3U.");
      return;
    }
    setState(() {
      _loading = true;
      _error = "";
      _status = "Baixando lista M3U...";
    });
    try {
      final creds = AppCredentials(m3uUrl: url);
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
                      // Voltar
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TVFocusableItem(
                          borderRadius: 20,
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.surface.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.glassBorder),
                            ),
                            child: const Icon(Icons.arrow_back,
                                color: AppTheme.textPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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
                        child: const Icon(Icons.link_rounded,
                            color: Colors.black, size: 44),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Lista M3U",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Cole o link completo da sua lista",
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _m3uCtrl,
                        keyboardType: TextInputType.url,
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 15),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              "http://servidor.com/get.php?username=...&password=...&type=m3u_plus",
                          hintStyle: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 13),
                          filled: true,
                          fillColor: AppTheme.surface.withValues(alpha: 0.8),
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                              borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                              borderSide: const BorderSide(
                                  color: AppTheme.accent, width: 1.5)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                              borderSide: BorderSide(
                                  color:
                                      Colors.white.withValues(alpha: 0.08))),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_loading) ...[
                        const CircularProgressIndicator(color: AppTheme.accent),
                        const SizedBox(height: 12),
                        Text(_status,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13)),
                      ] else ...[
                        TVFocusableItem(
                          autofocus: true,
                          borderRadius: AppTheme.radiusMd,
                          onTap: _connect,
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
}
