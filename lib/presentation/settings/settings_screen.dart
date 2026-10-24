import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../core/storage.dart';
import '../../db/database.dart';
import '../../widgets/tv_focusable_item.dart';
import '../../widgets/pin_dialog.dart';
import '../login/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _uiSound = AppStorage.instance.uiSoundEnabled;
  bool _adultUnlocked = AppStorage.instance.adultUnlocked;

  Future<void> _changePin() async {
    final oldOk = await PinDialog.request(context, title: "PIN atual");
    if (!oldOk || !mounted) return;
    final newPin = await _askNewPin();
    if (newPin != null) {
      await AppStorage.instance.setPin(newPin);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("PIN alterado com sucesso")));
    }
  }

  Future<String?> _askNewPin() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text("Novo PIN (4 dígitos)"),
        content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: const InputDecoration(hintText: "0000")),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          TextButton(
              onPressed: () {
                final pin = ctrl.text.trim();
                if (pin.length != 4 || int.tryParse(pin) == null) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          "O PIN deve ter exatamente 4 dígitos numéricos.")));
                  return;
                }
                Navigator.pop(context, pin);
              },
              child: const Text("Salvar")),
        ],
      ),
    );
  }

  void _logout() async {
    await AppDatabase.instance.clearAll();
    await AppStorage.instance.clearCredentials();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(4, 0, 4, 14),
        child: Text("Configurações", style: AppTheme.titleH1),
      ),
      const SizedBox(height: 8),
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
      _item("Alterar PIN parental",
          "PIN atual: ${'•' * AppStorage.instance.pin.length}", Icons.lock,
          _changePin),
      _item("Sair / Trocar conta", "Limpa credenciais e volta ao login",
          Icons.logout, _logout),
      const SizedBox(height: 20),
      const Center(
          child: Text("UNEX PLAY v1.1.0",
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
    ]);
  }

  Widget _item(String title, String subtitle, IconData icon,
      VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TVFocusableItem(
        borderRadius: AppTheme.radiusMd,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: ListTile(
            leading: Icon(icon, color: AppTheme.accent),
            title:
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(subtitle,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right,
                color: AppTheme.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _switch(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface.withOpacity(0.6),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: SwitchListTile(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          value: value,
          activeThumbColor: AppTheme.accent,
          activeTrackColor: AppTheme.accent.withOpacity(0.4),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
