import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../app_theme.dart';
import '../../core/storage.dart';
import '../../core/models.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/speed_test_service.dart';
import '../main_shell.dart';
import '../../widgets/tv_focusable_item.dart';

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
  bool _advanced = false;
  bool _loading = false;
  String _status = "";
  String _error = "";
  bool _testingSpeed = false;
  String _speedResult = "";

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
        m3uUrl: _advanced ? _m3uCtrl.text.trim() : null,
      );
      if (creds.dns.isEmpty && (creds.m3uUrl?.isEmpty ?? true)) {
        throw Exception("Informe o DNS ou um link M3U.");
      }
      await AppStorage.instance.saveCredentials(creds);
      final repo = ContentRepository();
      await repo.loadCatalog(onStatus: (s) => setState(() => _status = s));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll("Exception: ", "");
        _loading = false;
      });
    }
  }

  Future<void> _runSpeedTest() async {
    setState(() {
      _testingSpeed = true;
      _speedResult = "Medindo...";
    });
    try {
      final dns = _dnsCtrl.text.trim().isNotEmpty
          ? _dnsCtrl.text.trim()
          : "https://speed.cloudflare.com";
      final result = await SpeedTestService.run(dns);
      setState(() {
        _speedResult =
            "Ping: ${result.pingMs.toStringAsFixed(0)}ms • Jitter: ${result.jitterMs.toStringAsFixed(0)}ms • ${result.downloadMbps.toStringAsFixed(1)} Mbps (${result.classification})";
      });
    } catch (e) {
      setState(() => _speedResult = "Erro no teste: $e");
    } finally {
      setState(() => _testingSpeed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.overscan),
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_circle_fill, size: 64, color: AppTheme.accent),
                    const SizedBox(height: 8),
                    const Text("UNEX PLAY", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text("Entre com seu DNS, usuário e senha", style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 24),
                    _field("DNS (ex: http://servidor.com:8080)", _dnsCtrl, TextInputType.url),
                    const SizedBox(height: 12),
                    _field("Usuário", _userCtrl, TextInputType.text),
                    const SizedBox(height: 12),
                    _field("Senha", _passCtrl, TextInputType.visiblePassword, obscure: true),
                    const SizedBox(height: 16),
                    if (_advanced) ...[
                      _field("Link M3U (opcional / fallback)", _m3uCtrl, TextInputType.url),
                      const SizedBox(height: 16),
                    ],
                    if (_loading) ...[
                      const CircularProgressIndicator(color: AppTheme.accent),
                      const SizedBox(height: 8),
                      Text(_status, style: const TextStyle(color: AppTheme.textSecondary)),
                    ] else ...[
                      TVFocusableItem(
                        autofocus: true,
                        onTap: _login,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          color: AppTheme.accent,
                          alignment: Alignment.center,
                          child: const Text("ENTRAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: TVFocusableItem(
                            onTap: _testingSpeed ? null : _runSpeedTest,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              color: AppTheme.surface,
                              alignment: Alignment.center,
                              child: Text(_testingSpeed ? "Testando..." : "Testar Velocidade", style: const TextStyle(fontSize: 14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TVFocusableItem(
                            onTap: () => setState(() => _advanced = !_advanced),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              color: AppTheme.surface,
                              alignment: Alignment.center,
                              child: Text(_advanced ? "Modo Simples" : "Link M3U / Código", style: const TextStyle(fontSize: 14)),
                            ),
                          ),
                        ),
                      ]),
                      if (_speedResult.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(_speedResult, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.accent, fontSize: 13)),
                      ],
                      // QR Code para login pelo celular (pareamento)
                      const SizedBox(height: 16),
                      QrImageView(
                        data: "unexplay://pair?dns=${Uri.encodeComponent(_dnsCtrl.text)}",
                        version: QrVersions.auto,
                        size: 120,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.white),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      const Text("Escaneie com o celular para entrar mais rápido", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(_error, style: const TextStyle(color: AppTheme.danger), textAlign: TextAlign.center),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, TextInputType type, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.surface,
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.accent, width: 2), borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!), borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
