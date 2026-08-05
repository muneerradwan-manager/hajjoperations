import 'package:flutter/material.dart';

import '../../../core/l10n/error_text.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../application/check_in_cubit.dart';
import '../domain/check_in.dart';
import 'scan_check_in_screen.dart';

/// Reporting an arrival: scan the code, or just say you are here.
///
/// Two buttons and a note, and the order is the argument. Scanning is offered
/// first because it is the stronger record — it says which gate — and "I am
/// here" is offered at all because a node with no code printed yet still has
/// people arriving at it, and a register that could not hold that would have
/// holes in exactly the places nobody got round to preparing.
///
/// Neither path can fail for want of a network: both go through the outbox.
Future<void> showCheckInSheet(
  BuildContext context, {
  required String moduleId,
  String? nodeId,
}) => showAppSheet<void>(
  context: context,
  builder: (sheetContext) =>
      _CheckInSheet(moduleId: moduleId, nodeId: nodeId),
);

class _CheckInSheet extends StatefulWidget {
  const _CheckInSheet({required this.moduleId, this.nodeId});

  final String moduleId;
  final String? nodeId;

  @override
  State<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<_CheckInSheet> {
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final code = await Navigator.of(context).push<CheckInCode>(
      MaterialPageRoute(builder: (_) => const ScanCheckInScreen()),
    );
    if (code == null || !mounted) return;

    // A code from another file is a mistake worth naming. It happens: the
    // sheets for two files are printed in one batch and end up in one hand.
    if (code.moduleId != widget.moduleId) {
      _say(context.l10n.checkInWrongFile);
      return;
    }

    await _record(CheckInMethod.qr, nodeId: code.nodeId ?? widget.nodeId);
  }

  Future<void> _here() =>
      _record(CheckInMethod.manual, nodeId: widget.nodeId);

  Future<void> _record(CheckInMethod method, {String? nodeId}) async {
    setState(() => _busy = true);
    final l = context.l10n;

    // `manual` is upgraded to `gps` inside `CheckIn.arrive` when the phone
    // actually gives a fix — the method recorded is what the evidence supports,
    // not what the button was called.
    final outcome = await CheckIn.arrive(
      moduleId: widget.moduleId,
      nodeId: nodeId,
      method: method,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    if (!mounted) return;

    if (!outcome.ok) {
      setState(() => _busy = false);
      _say(friendlyErrorL(l, outcome.error));
      return;
    }
    Navigator.of(context).pop();
    _say(outcome.queued ? l.checkInQueued : l.checkInDone);
  }

  void _say(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.checkInTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _note,
            enabled: !_busy,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: l.checkInNoteHint),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _busy ? null : _scan,
            icon: const Icon(AppIcons.qrCode),
            label: Text(l.checkInScan),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _busy ? null : _here,
            icon: const Icon(AppIcons.checkIn),
            label: Text(l.checkInHere),
          ),
        ],
      ),
    );
  }
}
