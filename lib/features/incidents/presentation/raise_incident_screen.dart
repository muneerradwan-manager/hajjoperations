import 'package:flutter/material.dart';

import '../../../core/attachments/attachment_picker.dart';
import '../../../core/l10n/error_text.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/responsive.dart';
import '../application/incidents_cubit.dart';
import '../domain/incident.dart';

/// Reporting something that cannot wait.
///
/// Almost nothing on this screen, and the emptiness is the design. There is no
/// category to choose, no severity to rate, no file to pick, nothing marked
/// required but the one line of text. Every field added here is a second added
/// between a man deciding to report and the report arriving, and at some number
/// of seconds he stops and telephones somebody instead — which is the outcome
/// this screen exists to prevent.
///
/// Where he is, who he is and which file he belongs to are attached by the app
/// without asking. A photograph is offered and never required: it uploads
/// AFTER the alarm has already gone (see IncidentsRepository.raise), so it can
/// never delay the thing that matters.
class RaiseIncidentScreen extends StatefulWidget {
  const RaiseIncidentScreen({super.key, this.moduleId, this.nodeId});

  final String? moduleId;
  final String? nodeId;

  @override
  State<RaiseIncidentScreen> createState() => _RaiseIncidentScreenState();
}

class _RaiseIncidentScreenState extends State<RaiseIncidentScreen> {
  final _body = TextEditingController();
  final _added = <PendingAttachment>[];
  bool _busy = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _attach() async {
    final picked = await pickAttachment(context);
    if (picked != null) setState(() => _added.add(picked));
  }

  Future<void> _send() async {
    final body = _body.text.trim();
    if (body.isEmpty) return;

    setState(() => _busy = true);
    final outcome = await RaiseIncident.send(
      PendingIncident(
        body: body,
        moduleId: widget.moduleId,
        nodeId: widget.nodeId,
        attachments: _added,
      ),
    );
    if (!mounted) return;

    switch (outcome) {
      case IncidentOutcome.sent:
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(context.l10n.incidentSent)));
      case IncidentOutcome.waitingForNetwork:
        // A dialog, not a snack bar, and it does not close the screen. This is
        // the one message in the app that must be READ: his report is kept but
        // NOBODY HAS BEEN TOLD, and a line that slides away in four seconds
        // would leave him believing help is coming.
        setState(() => _busy = false);
        await _sayNobodyWasTold();
      case IncidentOutcome.failed:
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(friendlyError(context, null))),
          );
    }
  }

  Future<void> _sayNobodyWasTold() async {
    final l = context.l10n;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          AppIcons.warning,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: Text(l.incidentNotDeliveredTitle),
        content: Text(l.incidentNotDeliveredBody),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(context).pop(true);
            },
            child: Text(l.commonOk),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.incidentTitle),
        backgroundColor: scheme.errorContainer,
        foregroundColor: scheme.onErrorContainer,
      ),
      // A form, so it stops narrower than a reading column would: an emergency
      // typed into a text box a metre wide is harder to write, not easier.
      // The bottom padding comes from `scrollPadding`, which clears the
      // Android 15 gesture bar that the send button would otherwise sit under.
      body: ResponsivePage(
        width: PageWidth.form,
        builder: (context, size) => SinglePaneLayout(
          gutter: size.gutter,
          keyboardDismiss: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
          Text(l.incidentHint, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _body,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: l.incidentBodyHint,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final attachment in _added)
            PendingAttachmentRow(
              attachment: attachment,
              onRemove: () => setState(() => _added.remove(attachment)),
            ),
          TextButton.icon(
            onPressed: _busy ? null : _attach,
            icon: const Icon(AppIcons.camera, size: 18),
            label: Text(l.incidentAttach),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: (_busy || _body.text.trim().isEmpty) ? null : _send,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(AppIcons.warning),
            label: Text(_busy ? l.incidentSending : l.incidentSend),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l.incidentWhatIsAttached,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          ],
        ),
      ),
    );
  }
}
