import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GuardedCallbackAction<T extends Intent> extends CallbackAction<T> {
  GuardedCallbackAction({required this.enabled, required super.onInvoke});

  final bool Function() enabled;

  @override
  bool isEnabled(T intent) => enabled();
}

class ApproveIntent extends Intent {
  const ApproveIntent();
}

class RejectIntent extends Intent {
  const RejectIntent();
}

class CancelIntent extends Intent {
  const CancelIntent();
}

class NewOrderIntent extends Intent {
  const NewOrderIntent();
}

class ClearSelectionIntent extends Intent {
  const ClearSelectionIntent();
}

class ShowShortcutsIntent extends Intent {
  const ShowShortcutsIntent();
}

const boardShortcuts = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.keyA): ApproveIntent(),
  SingleActivator(LogicalKeyboardKey.keyR): RejectIntent(),
  SingleActivator(LogicalKeyboardKey.keyX): CancelIntent(),
  SingleActivator(LogicalKeyboardKey.keyN): NewOrderIntent(),
  SingleActivator(LogicalKeyboardKey.escape): ClearSelectionIntent(),
  CharacterActivator('?'): ShowShortcutsIntent(),
};

const shortcutDescriptions = [
  ('↑  ↓', 'Kretanje kroz naloge'),
  ('Enter', 'Otvori nalog pod kursorom'),
  ('Esc', 'Zatvori detalj'),
  ('A', 'Odobri izabrani nalog'),
  ('R', 'Odbij izabrani nalog'),
  ('X', 'Otkaži izabrani nalog'),
  ('N', 'Novi radni nalog'),
  ('?', 'Pregled prečica'),
  ('Tab', 'Sledeća kontrola'),
];

Future<void> showShortcutsOverview(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Prečice'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (keys, description) in shortcutDescriptions)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(width: 72, child: Text(keys, style: Theme.of(context).textTheme.labelLarge)),
                Text(description),
              ],
            ),
          ),
      ],
    ),
    actions: [TextButton(autofocus: true, onPressed: () => Navigator.pop(context), child: const Text('Zatvori'))],
  ),
);
