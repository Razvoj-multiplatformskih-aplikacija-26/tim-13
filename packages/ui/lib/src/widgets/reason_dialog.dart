import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../text/domain_errors.dart';

Future<ReasonText?> showReasonDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? description,
}) => showDialog<ReasonText>(
  context: context,
  builder: (context) => _ReasonDialog(title: title, confirmLabel: confirmLabel, description: description),
);

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.title, required this.confirmLabel, this.description});

  final String title;
  final String confirmLabel;
  final String? description;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    switch (ReasonText.parse(_controller.text)) {
      case Success(:final value):
        Navigator.pop(context, value);
      case Failure(:final error):
        setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final description = widget.description;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description != null) ...[Text(description), const SizedBox(height: 16)],
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(labelText: 'Razlog', errorText: _error),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Odustani')),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
