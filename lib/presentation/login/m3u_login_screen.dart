import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../core/storage.dart';
import '../../core/models.dart';
import '../../data/repositories/content_repository.dart';
import '../main_shell.dart';
import '../../widgets/tv_focusable_item.dart';
import '../../widgets/virtual_keyboard.dart';

/// Login via link M3U — painel de vidro + teclado virtual (atalho http://).
class M3ULoginScreen extends StatefulWidget {
  const M3ULoginScreen({super.key});
  @override
  State<M3ULoginScreen> createState() => _M3ULoginScreenState();
}

class _M3ULoginScreenState extends State<M3ULoginScreen> {
  final _m3uCtrl = TextEditingController();
  TextEditingController? _active;
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
      _active = null;
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
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlassContainer(
                        opacity: 0.10,
                        blur: 22,
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TVFocusableItem(
                                borderRadius: 20,
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border:
                                        Border.all(color: AppTheme.glassBorder),
                                  ),
                                  child: const Icon(Icons.arrow_back,
                                      color: AppTheme.textPrimary),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: AppTheme.accentGradient,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.accent.withValues(alpha: 0.4),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.link_rounded,
                                  color: Colors.black, size: 40),
                            ),
                            const SizedBox(height: 14),
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
                            const SizedBox(height: 24),
                            GlassInputField(
                              controller: _m3uCtrl,
                              label: "Link da lista M3U",
                              hint: "http://servidor.com/get.php?...",
                              maxLines: 3,
                              active: _active == _m3uCtrl,
                              onSelect: () => setState(() => _active = _m3uCtrl),
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
                            ] else
                              TVFocusableItem(
                                autofocus: true,
                                borderRadius: AppTheme.radiusMd,
                                onTap: _connect,
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
                      if (_active != null)
                        VirtualKeyboard(
                          controller: _active!,
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
