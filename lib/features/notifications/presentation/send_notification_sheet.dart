import 'package:flutter/material.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../data/notifications_repository.dart';

/// Compose + send a notification to a single recipient.
Future<void> showSendNotificationSheet(
  BuildContext context, {
  required String recipientId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _Form(recipientId: recipientId),
    ),
  );
}

class _Form extends StatefulWidget {
  const _Form({required this.recipientId});
  final String recipientId;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _repo = NotificationsRepository();
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await _repo.send(
        recipientId: widget.recipientId,
        title: _title.text.trim(),
        body: _body.text.trim().isEmpty ? null : _body.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.notificationSent)));
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.notificationSend,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              decoration: InputDecoration(
                labelText: l.notificationTitleField,
                prefixIcon: const Icon(AppIcons.notifications),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l.commonRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _body,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l.notificationBodyField,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy ? null : _send,
              icon: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(AppIcons.send),
              label: Text(l.notificationSend),
            ),
          ],
        ),
      ),
    );
  }
}
