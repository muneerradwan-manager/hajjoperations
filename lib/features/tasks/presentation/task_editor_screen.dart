import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/creator_page.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/info_section.dart';
import '../application/tasks_cubit.dart';
import '../domain/personal_task.dart';

/// Writes a task, or corrects one the caller holds the full pen over.
///
/// [existing] is null for a new one. [assignTo] names other people's lists —
/// the assigners' door, and a LIST because one duty is routinely handed to
/// several people in one decision; empty writes onto the caller's own.
///
/// Returns true when something was written, so the list that pushed it knows to
/// reload. A page rather than the sheet this used to be — see [CreatorPage] for
/// why every "new record" in the app is now a place you go to.
///
/// The cubit is passed rather than read off [context]: this is reopened from
/// inside the task sheet, after that sheet has been popped, and the context
/// left standing at that moment is the Navigator's — which sits ABOVE the
/// provider and would find nothing.
Future<bool> openTaskEditor(
  BuildContext context,
  TasksCubit cubit, {
  PersonalTask? existing,
  List<(String id, String name)> assignTo = const [],
}) async {
  final saved = await Navigator.of(context).push<bool>(
    fadeThroughRoute(
      (_) => BlocProvider.value(
        value: cubit,
        child: TaskEditorScreen(existing: existing, assignTo: assignTo),
      ),
    ),
  );
  return saved == true;
}

class TaskEditorScreen extends StatefulWidget {
  const TaskEditorScreen({
    super.key,
    this.existing,
    this.assignTo = const [],
  });

  final PersonalTask? existing;
  final List<(String id, String name)> assignTo;

  @override
  State<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends State<TaskEditorScreen> {
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _description = TextEditingController(
    text: widget.existing?.description ?? '',
  );
  late DateTime? _dueOn = widget.existing?.dueOn;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = l.commonRequired);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final cubit = context.read<TasksCubit>();
    final existing = widget.existing;
    final error = existing == null
        ? await cubit.create(
            title: title,
            description: _description.text.trim(),
            dueOn: _dueOn,
            profileIds: {for (final (id, _) in widget.assignTo) id},
          )
        : await cubit.update(
            id: existing.id,
            title: title,
            description: _description.text.trim(),
            dueOn: _dueOn,
          );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    // Said here rather than by the list: this page knows WHAT was written, and
    // the messenger it speaks to belongs to the app, not to this route — the
    // line stays up over the list it returns to.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.taskSaved)));
    Navigator.of(context).pop(true);
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueOn ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => _dueOn = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isNew = widget.existing == null;
    final assignTo = widget.assignTo;

    return CreatorPage(
      title: isNew
          ? (assignTo.isEmpty ? l.tasksNew : l.tasksAssign)
          : l.taskEdit,
      submitLabel: l.commonSave,
      busy: _busy,
      onSubmit: _save,
      maxWidth: 640,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Every name, not a count: whoever is about to hand out a duty is
              // owed the chance to notice the wrong man in the list BEFORE six
              // people are notified, and "6 employees" gives him nothing to
              // notice with.
              if (assignTo.isNotEmpty) ...[
                Text(
                  l.tasksAssign,
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final (_, name) in assignTo)
                      GlassBadge(
                        label: name,
                        icon: AppIcons.myProfile,
                        dense: true,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              TextField(
                controller: _title,
                enabled: !_busy,
                autofocus: isNew,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l.taskTitleLabel),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _description,
                enabled: !_busy,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l.taskDescriptionLabel,
                  helperText: l.commonOptional,
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickDue,
                icon: const Icon(AppIcons.seasons, size: 18),
                label: Text(
                  _dueOn == null ? l.taskNoDue : l.taskDue(formatDate(_dueOn)),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: text.bodySmall?.copyWith(color: scheme.error),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
