import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/strings.dart';
import '../services/app_state.dart';

/// Ab "Payment Done" nahi — ek real request banegi jo admin verify karega.
Future<void> showPaymentRequestDialog({
  required BuildContext context,
  required AppState app,
  required S s,
  required String method,
  required String number,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => _PaymentRequestDialog(
      app: app,
      s: s,
      method: method,
      number: number,
    ),
  );
}

class _PaymentRequestDialog extends StatefulWidget {
  final AppState app;
  final S s;
  final String method;
  final String number;

  const _PaymentRequestDialog({
    required this.app,
    required this.s,
    required this.method,
    required this.number,
  });

  @override
  State<_PaymentRequestDialog> createState() => _PaymentRequestDialogState();
}

class _PaymentRequestDialogState extends State<_PaymentRequestDialog> {
  final TextEditingController _reference = TextEditingController();
  final TextEditingController _note = TextEditingController();
  XFile? _screenshot;
  bool _sending = false;

  @override
  void dispose() {
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file != null) setState(() => _screenshot = file);
  }

  Future<void> _submit() async {
    final s = widget.s;
    final messenger = ScaffoldMessenger.of(context);

    if (widget.app.user == null) {
      messenger.showSnackBar(SnackBar(content: Text(s.t('login'))));
      return;
    }
    if (_reference.text.trim().isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(s.t('reference'))));
      return;
    }

    setState(() => _sending = true);
    try {
      await widget.app.submitPaymentRequest(
        method: widget.method,
        accountNumber: widget.number,
        reference: _reference.text,
        screenshot: _screenshot,
        note: _note.text,
      );
      if (mounted) Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(s.t('request_sent'))));
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(s.t('request_failed'))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return AlertDialog(
      title: Text('${s.t(widget.method)} ${s.t('payment_request')}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.t('monthly_fee')),
            const SizedBox(height: 10),
            Text(s.t('payment_instructions')),
            const SizedBox(height: 4),
            Text(s.t('send_payment_to')),
            const SizedBox(height: 4),
            SelectableText(
              widget.number.isEmpty ? '-' : widget.number,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(s.t('after_payment')),
            const SizedBox(height: 14),
            TextField(
              controller: _reference,
              decoration: InputDecoration(labelText: s.t('reference')),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickScreenshot,
              icon: const Icon(Icons.image_outlined),
              label: Text(
                _screenshot == null ? s.t('screenshot') : '✓ ${s.t('screenshot')}',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: InputDecoration(labelText: s.t('about')),
            ),
            const SizedBox(height: 10),
            Text(
              s.t('demo_note'),
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.t('close')),
        ),
        FilledButton(
          onPressed: _sending ? null : _submit,
          child: _sending
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(s.t('send_request')),
        ),
      ],
    );
  }
}
