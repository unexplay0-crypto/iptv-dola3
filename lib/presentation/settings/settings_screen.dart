import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../core/storage.dart';
import '../../data/speed_test_service.dart';
import '../../widgets/tv_focusable_item.dart';
import '../../widgets/pin_dialog.dart';
import '../login/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _speed = "";
  bool _testing = false;
  bool _uiSound = AppStorage.instance.uiSoundEnabled;
  bool _adultUnlocked = AppStorage.instance.adultUnlocked;

  Future<void> _testSpeed() async {
    setState(() {
      _testing = true;
      _speed = "Medindo...";
    });
    try {
      final dns = AppStorage.instance.credentials.dns;
      final r = await SpeedTestService.run(dns.isNotEmpty ? dns : "https://speed.cloudflare.com");
      setState(() => _speed = "${r.downloadMbps.toStringAsFixed(1)} Mbps • Ping ${r.pingMs.toStringAsFixed(0)}ms (${r.classification})");
    } catch (e) {
      setState(() => _speed = "Erro: $e");
    } finally {
      setState(() => _testing = false);
    }
  }

  Future<void> _changePin() async {
    final oldOk = await PinDialog.request(context, title: "PIN atual");
    if (!oldOk || !mounted) return;
    final newPin = await _askNewPin();
    if (newPin != null) {
      await AppStorage.instance.setPin(newPin);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PIN alterado com sucesso")));
    }
  }

  Future<String?> _askNewPin() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text("Novo PIN (4 dígitos)"),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, maxLength: 4, obscureText: true, decoration: const InputDecoration(hintText: "0000")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text("Salvar")),
        ],
      ),
    );
  }

  void _logout() {
    AppStorage.instance.clearCredentials();
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      _item("Testar Velocidade", _testing ? "Medindo..." : (_speed.isEmpty ? "Medir conexão com o servidor" : _speed), Icons.speed, _testing ? null : _testSpeed),
      _switch("Som de UI", _uiSound, (v) async {
        await AppStorage.instance.setUiSoundEnabled(v);
        setState(() => _uiSound = v);
      }),
      _switch("Desbloquear conteúdo adulto", _adultUnlocked, (v) async {
        if (v) {
          final ok = await PinDialog.request(context);
          if (!ok) return;
        }
        await AppStorage.instance.setAdultUnlocked(v);
        setState(() => _adultUnlocked = v);
      }),
      _item("Alterar PIN parental", "PIN atual: ${'•' * AppStorage.instance.pin.length}", Icons.lock, _changePin),
      _item("Sair / Trocar conta", "Limpa credenciais e volta ao login", Icons.logout, _logout),
      const SizedBox(height: 20),
      const Center(child: Text("UNEX PLAY v1.0.0", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
    ]);
  }

  Widget _item(String title, String subtitle, IconData icon, VoidCallback? onTap) {
    return TVFocusableItem(
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.accent),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _switch(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      activeColor: AppTheme.accent,
      onChanged: onChanged,
    );
  }
}
