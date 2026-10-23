import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../core/storage.dart';
import 'tv_focusable_item.dart';

/// Diálogo de PIN parental (navegável por controle remoto).
/// Retorna true se o PIN correto foi digitado.
class PinDialog extends StatefulWidget {
  final String title;
  const PinDialog({super.key, this.title = "Digite o PIN parental"});

  static Future<bool> request(BuildContext context, {String title = "Digite o PIN parental"}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PinDialog(title: title),
    );
    return result ?? false;
  }

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  String _pin = "";
  String _error = "";

  void _press(String digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += digit;
      _error = "";
    });
    if (_pin.length == 4) _validate();
  }

  void _backspace() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _validate() {
    final expected = AppStorage.instance.pin;
    if (_pin == expected) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _error = "PIN incorreto";
        _pin = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppTheme.accent : Colors.transparent,
                    border: Border.all(color: AppTheme.accent, width: 2),
                  ),
                );
              }),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_error, style: const TextStyle(color: AppTheme.danger)),
            ],
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 1.8,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                ...["1", "2", "3", "4", "5", "6", "7", "8", "9"].map(
                  (d) => TVFocusableItem(
                    onTap: () => _press(d),
                    child: Container(
                      color: AppTheme.background,
                      alignment: Alignment.center,
                      child: Text(d, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                ),
                TVFocusableItem(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Container(color: AppTheme.background, alignment: Alignment.center, child: const Text("Cancelar")),
                ),
                TVFocusableItem(
                  onTap: () => _press("0"),
                  child: Container(color: AppTheme.background, alignment: Alignment.center, child: const Text("0", style: TextStyle(fontSize: 22))),
                ),
                TVFocusableItem(
                  onTap: _backspace,
                  child: Container(color: AppTheme.background, alignment: Alignment.center, child: const Text("⌫")),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
