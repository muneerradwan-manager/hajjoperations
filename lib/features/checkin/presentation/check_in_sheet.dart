import 'package:flutter/material.dart';

import '../../../core/l10n/error_text.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../application/check_in_cubit.dart';
import '../data/check_in_repository.dart';
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

  /// What this file offers as an answer to "where are you", when the sheet was
  /// opened without a place already known.
  ///
  /// Null while they are still being fetched, which is a different thing from
  /// an empty list: the first means "wait", the second means "this file has
  /// nothing to name", and the button below reads them differently.
  List<({String id, String name})>? _places;

  /// Which of them the person says he is at.
  String? _picked;

  @override
  void initState() {
    super.initState();
    if (widget.nodeId == null) _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    try {
      final places = await CheckInRepository().fetchCheckInTargets(
        widget.moduleId,
      );
      if (mounted) setState(() => _places = places);
    } catch (error, stack) {
      // A list that would not load must not stop a man reporting that he
      // arrived: the code and the position both still work without it. But it
      // is reported rather than swallowed — an empty picker and a failed fetch
      // look identical on the screen, and the first time this happened it cost
      // a round of guessing to tell them apart.
      AppLogger.error('check-in', 'places would not load', error, stack);
      if (mounted) setState(() => _places = const []);
    }
  }

  /// The place this check-in would name, if any.
  String? get _nodeId => widget.nodeId ?? _picked;

  /// Whether "I am here" can produce a record worth keeping.
  ///
  /// It cannot when the file has something to name and nothing has been chosen:
  /// with no code scanned and no place named, all that would be sent is the
  /// file itself, and the server refuses that now — rightly, since such a row is
  /// invisible on the map and uncounted on the board (0094).
  ///
  /// A file with no nodes at all leaves the button live, because there the
  /// position is the only thing that can carry the check-in and the phone
  /// should be allowed to try.
  bool get _canReportHere =>
      _nodeId != null || (_places != null && _places!.isEmpty);

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

  Future<void> _here() => _record(CheckInMethod.manual, nodeId: _nodeId);

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
          // Offered only when the sheet was opened without a place already
          // known — from the file page rather than from a tower. Scanning a
          // code makes it unnecessary, which is why it sits above the buttons
          // as a fallback rather than as a step.
          if (widget.nodeId == null && (_places?.isNotEmpty ?? false)) ...[
            DropdownButtonFormField<String>(
              initialValue: _picked,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.checkInWhichPlace),
              items: [
                for (final place in _places!)
                  DropdownMenuItem(
                    value: place.id,
                    child: Text(place.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: _busy ? null : (v) => setState(() => _picked = v),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
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
            onPressed: (_busy || !_canReportHere) ? null : _here,
            icon: const Icon(AppIcons.checkIn),
            label: Text(l.checkInHere),
          ),
          // Said under the disabled button rather than after pressing it. A
          // control that does nothing and explains nothing is the one thing
          // worse than a control that records nothing.
          if (!_canReportHere && !_busy)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                _places == null ? l.commonLoading : l.checkInPickAPlaceFirst,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
