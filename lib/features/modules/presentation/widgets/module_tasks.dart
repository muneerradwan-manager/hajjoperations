import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/attachments/attachment_picker.dart';
import '../../../../core/attachments/attachments_view.dart';
import '../../../../core/constants/permission_codes.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/glass_tokens.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/info_section.dart';
import '../../../../core/widgets/overflow_menu.dart';
import '../../../../core/widgets/selection_indicator.dart';
import '../../../../core/widgets/states.dart';
import '../../../auth/application/session_cubit.dart';
import '../../application/module_detail_cubit.dart';
import '../../domain/module_task.dart';
import '../../domain/module_type.dart';

/// The duties of a file, in the three levels the work is actually organised in
/// and in the order a member reads them:
///
///   1. مهام الملف       — the file's own, seen by everyone in it
///   2. مهام دوري        — the duties of each post he holds, at each place
///   3. مهامي الشخصية    — whatever was written for him by name
///
/// None of the three is reached through a person. A file duty belongs to the
/// file, a role duty to the post, and only the third names anybody — which is
/// why it is last and usually empty.
List<Widget> moduleTaskSections(
  BuildContext context,
  ModuleDetailState state, {
  required bool canManage,
}) {
  final l = context.l10n;
  final board = state.board;
  final type = state.type;
  if (type == null) return const [];

  final roleGroups = board.roleGroups;
  final personal = board.personalByProfile;
  final readingSomeoneElse = state.viewAsProfileId != null;

  return [
    const SizedBox(height: AppSpacing.lg),
    SectionHeader(
      l.moduleTasksSection,
      icon: AppIcons.tasks,
      trailing: _TasksToolbar(state: state, canManage: canManage),
    ),

    if (board.isEmpty)
      GlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          // Two different facts, and telling a man the file is empty when it is
          // merely not his is how he stops trusting the screen.
          state.showAllTasks ? l.moduleTasksNone : l.moduleTasksNoneMine,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),

    // 1 — the file's own.
    if (board.fileTasks.isNotEmpty)
      _TaskGroupCard(
        title: l.moduleTasksFile,
        subtitle: l.moduleTasksFileHint,
        icon: AppIcons.modules,
        type: type,
        tasks: board.fileTasks,
      ),

    // 2 — a post, once per place it is held at. "مشرف البرج — البرج/الفندق:
    // فندق الصفوة" and "…فندق النور" are two headings on purpose: the same man
    // owes the same duties twice over, and one merged list would let one of
    // them disappear behind the other.
    for (final group in roleGroups)
      _TaskGroupCard(
        title: _roleTitle(context, state, group, readingSomeoneElse),
        subtitle: l.moduleTasksRoleHint,
        place: state.placeOf(group.nodeId)?.of(context),
        icon: AppIcons.roles,
        type: type,
        tasks: group.tasks,
      ),

    // 3 — the exception.
    for (final entry in personal.entries)
      _TaskGroupCard(
        title: entry.key == state.focusProfileId && !state.showAllTasks
            ? l.moduleTasksPersonal
            : l.moduleTasksPersonalOf(
                state.nameOf(entry.key) ?? l.moduleTaskPersonLabel,
              ),
        subtitle: l.moduleTasksPersonalHint,
        icon: AppIcons.myProfile,
        type: type,
        tasks: entry.value,
      ),
  ];
}

String _roleTitle(
  BuildContext context,
  ModuleDetailState state,
  RoleTaskGroup group,
  bool readingSomeoneElse,
) {
  final l = context.l10n;
  final role = state.roleById(group.roleId);
  final name = role?.name.of(context);
  // "مهام دوري" only when it IS his. Reading a colleague's board, or the whole
  // file's, the possessive would be a lie.
  if (name == null) return l.moduleTasksRole;
  if (state.showAllTasks || readingSomeoneElse) {
    return l.moduleTasksRoleOf(name);
  }
  return '${l.moduleTasksRole} — $name';
}

/// The switch between "my duties here" and the whole file, and the button that
/// writes a new one. Both belong to whoever runs the file; a member gets a
/// header with nothing on the end of it.
class _TasksToolbar extends StatelessWidget {
  const _TasksToolbar({required this.state, required this.canManage});

  final ModuleDetailState state;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (!canManage) return const SizedBox.shrink();
    final module = state.module;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SegmentedButton<bool>(
          showSelectedIcon: false,
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          segments: [
            ButtonSegment(value: false, label: Text(l.moduleTasksMine)),
            ButtonSegment(value: true, label: Text(l.moduleTasksAll)),
          ],
          selected: {state.showAllTasks},
          onSelectionChanged: (v) =>
              context.read<ModuleDetailCubit>().setShowAllTasks(v.first),
        ),
        if (module != null)
          IconButton(
            tooltip: l.moduleTaskAdd,
            visualDensity: VisualDensity.compact,
            onPressed: () => showTaskEditorSheet(
              context,
              context.read<ModuleDetailCubit>(),
            ),
            icon: const Icon(AppIcons.add, size: 20),
          ),
      ],
    );
  }
}

/// One heading and the duties under it, in the stages the type divides its work
/// into, with what they add up to on the right.
class _TaskGroupCard extends StatelessWidget {
  const _TaskGroupCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
    required this.tasks,
    this.place,
  });

  final String title;
  final String subtitle;

  /// Where the post is held, for a role duty at a برج or a قطاع.
  final String? place;

  final IconData icon;
  final ModuleType type;
  final List<ModuleTaskLine> tasks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final (done, total) = ModuleTaskBoard.progressOf(tasks);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleSmall),
                      if (place != null)
                        Text(
                          place!,
                          style: text.labelSmall?.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                _ProgressPill(done: done, total: total),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            // The stages of the work, in the order it happens. A type with no
            // stages gets one unlabelled run, which is what [byStage] returns.
            for (final (stage, inStage) in type.groupByStage(
              tasks,
              (t) => t.groupId,
            )) ...[
              if (stage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    stage.name.of(context),
                    style: text.labelMedium?.copyWith(color: scheme.primary),
                  ),
                ),
              for (final task in inStage) _TaskRow(task: task),
              if (stage != null) const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }
}

/// "٤/٧" — how much of a list is behind it. Coloured only when it is all of it:
/// a green pill over four of seven would be a congratulation nobody earned.
class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final complete = total > 0 && done == total;
    final color = complete ? scheme.primary : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.l10n.moduleTasksProgress(done, total),
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: color, height: 1.4),
      ),
    );
  }
}

/// One duty: what it is, how it is going, and — when somebody has moved it —
/// who said so, when, and what they attached.
class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final ModuleTaskLine task;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final cubit = context.read<ModuleDetailCubit>();
    final note = task.note?.trim() ?? '';

    return InkWell(
      // Tappable even when it may not be changed: the note, the evidence and
      // who last touched it are worth reading whoever is looking, and a row
      // that does nothing on tap reads as a row that is broken.
      onTap: () => showTaskStateSheet(context, task: task),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _StateDot(state: task.state),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title.of(context),
                    style: text.bodyMedium?.copyWith(
                      height: 1.5,
                      // Struck through, not greyed: a finished duty is still
                      // part of the record and has to stay readable.
                      decoration: task.state.isDone
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (task.description != null)
                    Text(
                      task.description!.of(context),
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  if (task.dueOn != null)
                    Text(
                      l.moduleTaskDue(formatDate(task.dueOn)),
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  if (note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        note,
                        style: text.bodySmall?.copyWith(height: 1.4),
                      ),
                    ),
                  if (task.attachments.isNotEmpty)
                    AttachmentsView(
                      attachments: task.attachments,
                      signer: cubit.signAttachment,
                    ),
                  if (task.updatedByName != null && task.updatedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        l.moduleTaskUpdatedBy(
                          task.updatedByName!,
                          formatDate(task.updatedAt),
                        ),
                        style: text.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _StateChip(state: task.state),
          ],
        ),
      ),
    );
  }
}

/// The colour of a state, one place, so the dot and the chip cannot disagree.
Color stateColor(ColorScheme scheme, TaskState state) => switch (state) {
  TaskState.notStarted => scheme.onSurfaceVariant,
  TaskState.inProgress => scheme.tertiary,
  TaskState.done => scheme.primary,
};

String stateLabel(BuildContext context, TaskState state) => switch (state) {
  TaskState.notStarted => context.l10n.taskStateNotStarted,
  TaskState.inProgress => context.l10n.taskStateInProgress,
  TaskState.done => context.l10n.taskStateDone,
};

/// Three shapes, not three colours: an empty ring, a half-filled ring and a
/// tick. Colour alone would say nothing to a reader who cannot tell tertiary
/// from primary, and these are read at twelve pixels down a list of thirty.
class _StateDot extends StatelessWidget {
  const _StateDot({required this.state});

  final TaskState state;

  @override
  Widget build(BuildContext context) {
    final color = stateColor(Theme.of(context).colorScheme, state);
    return switch (state) {
      TaskState.done => Icon(AppIcons.selected, size: 16, color: color),
      TaskState.inProgress => Icon(AppIcons.pending, size: 16, color: color),
      TaskState.notStarted => Container(
        width: 14,
        height: 14,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.6), width: 1.4),
        ),
      ),
    };
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.state});

  final TaskState state;

  @override
  Widget build(BuildContext context) {
    final color = stateColor(Theme.of(context).colorScheme, state);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        stateLabel(context, state),
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: color, height: 1.4),
      ),
    );
  }
}

// ============================================================ setting a state

/// Moving one duty along: the three states, a note, and whatever evidence the
/// man wants filed with it.
///
/// Opened on a duty the reader may not touch, it shows the same thing with the
/// controls off — the note somebody else left and the photo he attached are
/// most of the value of the row, and hiding them from a colleague would make
/// every board a set of private lists again.
Future<void> showTaskStateSheet(
  BuildContext context, {
  required ModuleTaskLine task,
}) async {
  final cubit = context.read<ModuleDetailCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final label = context.l10n.moduleTaskStateSaved;
  final saved = await showAppSheet<bool>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _TaskStateSheet(task: task),
    ),
  );
  if (saved == true) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(label)));
  }
}

class _TaskStateSheet extends StatefulWidget {
  const _TaskStateSheet({required this.task});

  final ModuleTaskLine task;

  @override
  State<_TaskStateSheet> createState() => _TaskStateSheetState();
}

class _TaskStateSheetState extends State<_TaskStateSheet> {
  late TaskState _state = widget.task.state;
  late final _note = TextEditingController(text: widget.task.note ?? '');
  late final _kept = [...widget.task.attachments];
  final _removed = <StoredAttachment>[];
  final _added = <PendingAttachment>[];
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _attach() async {
    final picked = await pickAttachment(context);
    if (picked != null) setState(() => _added.add(picked));
  }

  bool _canManage(BuildContext context) =>
      context.read<SessionCubit>().state.can(PermissionCodes.modulesTasks);

  /// Closes this sheet and reopens the editor on the same duty. Two sheets
  /// stacked would leave a stale copy of the row underneath the one being
  /// corrected.
  Future<void> _edit() async {
    final cubit = context.read<ModuleDetailCubit>();
    final host = Navigator.of(context);
    host.pop();
    await showTaskEditorSheet(host.context, cubit, existing: widget.task);
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final id = widget.task.moduleTaskId;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.moduleTaskDelete),
        content: Text(l.moduleTaskDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final error = await context.read<ModuleDetailCubit>().deleteTask(id);
    if (!mounted) return;
    if (error != null) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop(false);
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final note = _note.text.trim();
    final outcome = await context.read<ModuleDetailCubit>().setTaskState(
      widget.task,
      _state,
      note: note.isEmpty ? null : note,
      attachments: _added,
      removed: _removed,
    );
    if (!mounted) return;
    if (!outcome.ok) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(outcome.error!)));
      return;
    }
    // Said plainly rather than passed over. The sheet closes either way and the
    // work is his either way, but a man who knows his phone had no signal is
    // owed the difference between "it is with them" and "it is with the app".
    if (outcome.queued) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.outboxSavedOffline)));
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final task = widget.task;
    final editable = task.canUpdate;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(task.title.of(context), style: text.titleLarge),
                ),
                // Correcting or withdrawing a duty, for whoever wrote it onto
                // the file. Absent — not disabled — for a catalog duty: that
                // one belongs to every season of the type, and offering an Edit
                // that would rewrite last year's file is worse than offering
                // none. See [OverflowMenu] on why the wrong person gets no
                // button rather than a grey one.
                if (task.isOwnedByFile && _canManage(context))
                  OverflowMenu(
                    actions: [
                      MenuAction(
                        icon: AppIcons.edit,
                        label: l.moduleTaskEdit,
                        onSelected: _edit,
                      ),
                      MenuAction(
                        icon: AppIcons.delete,
                        label: l.moduleTaskDelete,
                        isDestructive: true,
                        onSelected: _delete,
                      ),
                    ],
                  ),
              ],
            ),
            if (task.description != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                task.description!.of(context),
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (!editable) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(AppIcons.warning, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l.moduleTaskReadOnly,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),

            Text(
              l.moduleTaskState,
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final option in TaskState.values)
                  ChoiceChip(
                    label: Text(stateLabel(context, option)),
                    avatar: _StateDot(state: option),
                    selected: _state == option,
                    onSelected: !editable || _busy
                        ? null
                        : (_) => setState(() => _state = option),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),
            for (final attachment in _kept)
              _AttachmentRow(
                name: attachment.name,
                onRemove: !editable || _busy
                    ? null
                    : () => setState(() {
                        _kept.remove(attachment);
                        _removed.add(attachment);
                      }),
              ),
            for (var i = 0; i < _added.length; i++)
              PendingAttachmentRow(
                attachment: _added[i],
                onRemove: _busy ? null : () => setState(() => _added.removeAt(i)),
              ),
            if (editable)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: _busy ? null : _attach,
                  icon: const Icon(AppIcons.attach, size: 18),
                  label: Text(l.moduleTaskEvidence),
                ),
              ),

            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _note,
              maxLines: 3,
              enabled: editable && !_busy,
              decoration: InputDecoration(
                labelText: l.moduleTaskNote,
                helperText: l.moduleTaskNoteHint,
                alignLabelWithHint: true,
              ),
            ),

            if (editable) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _busy ? null : _save,
                icon: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Icon(AppIcons.approve),
                label: Text(l.moduleTaskUpdate),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// An attachment already filed, in the sheet that is editing it.
class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({required this.name, this.onRemove});

  final String name;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(AppIcons.attach, size: 18, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: context.l10n.commonDelete,
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            icon: const Icon(AppIcons.delete, size: 16),
          ),
        ],
      ),
    );
  }
}

// ============================================================ writing a duty

/// Writes a duty onto this file, or corrects one already written on it.
///
/// [existing] is null for a new one. A duty from the type's catalog never
/// reaches here: it belongs to every season of that type, and correcting it
/// from inside one file would rewrite the others.
///
/// The cubit is passed rather than read off [context]: this is reopened from
/// inside the state sheet, after that sheet has been popped, and the context
/// left standing at that moment is the Navigator's — which sits ABOVE the
/// provider and would find nothing.
Future<void> showTaskEditorSheet(
  BuildContext context,
  ModuleDetailCubit cubit, {
  ModuleTaskLine? existing,
}) async {
  await showAppSheet<bool>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _TaskEditorSheet(state: cubit.state, existing: existing),
    ),
  );
}

class _TaskEditorSheet extends StatefulWidget {
  const _TaskEditorSheet({required this.state, this.existing});

  final ModuleDetailState state;
  final ModuleTaskLine? existing;

  @override
  State<_TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<_TaskEditorSheet> {
  late TaskScope _scope = widget.existing?.scope ?? TaskScope.file;
  late String? _roleId = widget.existing?.roleId;
  late String? _profileId = widget.existing?.profileId;
  late String? _groupId = widget.existing?.groupId;
  late DateTime? _dueOn = widget.existing?.dueOn;
  late final _titleAr = TextEditingController(
    text: widget.existing?.title.ar ?? '',
  );
  late final _titleEn = TextEditingController(
    text: widget.existing?.title.en ?? '',
  );
  late final _description = TextEditingController(
    text: widget.existing?.description?.ar ?? '',
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _titleAr.dispose();
    _titleEn.dispose();
    _description.dispose();
    super.dispose();
  }

  /// Everyone posted anywhere in this file, for the personal scope. Duties are
  /// written for people who are IN the file — handing one to somebody who is
  /// not is a posting nobody made.
  List<(String id, String name)> get _people {
    final seen = <String, String>{};
    for (final m in [
      ...widget.state.members,
      for (final n in widget.state.nodes) ...n.members,
    ]) {
      seen[m.profileId] = m.profile?.fullName ?? '';
    }
    final people = seen.entries.map((e) => (e.key, e.value)).toList();
    people.sort((a, b) => a.$2.compareTo(b.$2));
    return people;
  }

  Future<void> _save() async {
    final l = context.l10n;
    final title = _titleAr.text.trim();
    if (title.isEmpty) {
      setState(() => _error = l.commonRequired);
      return;
    }
    if (_scope == TaskScope.role && _roleId == null) {
      setState(() => _error = l.moduleTaskPickRole);
      return;
    }
    if (_scope == TaskScope.personal && _profileId == null) {
      setState(() => _error = l.moduleTaskPickPerson);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final cubit = context.read<ModuleDetailCubit>();
    final id = widget.existing?.moduleTaskId;
    final error = id == null
        ? await cubit.createTask(
            scope: _scope,
            titleAr: title,
            titleEn: _titleEn.text.trim(),
            descriptionAr: _description.text.trim(),
            roleId: _roleId,
            profileId: _profileId,
            groupId: _groupId,
            dueOn: _dueOn,
          )
        : await cubit.updateTask(
            id: id,
            titleAr: title,
            titleEn: _titleEn.text.trim(),
            descriptionAr: _description.text.trim(),
            groupId: _groupId,
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
    final type = widget.state.type;
    final roles = type?.allRoles ?? const <ModuleRole>[];
    final stages = type?.taskGroups ?? const <TaskGroup>[];
    // The scope of a duty already written is fixed: moving one from a man to
    // the whole file is not an edit, it is a different duty, and the progress
    // recorded against the old one was recorded about something else.
    final isNew = widget.existing == null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isNew ? l.moduleTaskAdd : l.moduleTaskEdit,
              style: text.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),

            if (isNew) ...[
              Text(
                l.moduleTaskScope,
                style: text.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final option in TaskScope.values)
                SelectionRow(
                  label: switch (option) {
                    TaskScope.file => l.moduleTaskScopeFile,
                    TaskScope.role => l.moduleTaskScopeRole,
                    TaskScope.personal => l.moduleTaskScopePersonal,
                  },
                  // The hint is the whole of the choice: three words each, and
                  // between them the entire difference this redesign is about.
                  subtitle: switch (option) {
                    TaskScope.file => l.moduleTaskScopeFileHint,
                    TaskScope.role => l.moduleTaskScopeRoleHint,
                    TaskScope.personal => l.moduleTaskScopePersonalHint,
                  },
                  selected: _scope == option,
                  onTap: _busy ? () {} : () => setState(() => _scope = option),
                ),
              const SizedBox(height: AppSpacing.sm),

              if (_scope == TaskScope.role)
                DropdownButtonFormField<String>(
                  initialValue: _roleId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.moduleTaskRoleLabel),
                  items: [
                    for (final role in roles)
                      DropdownMenuItem(
                        value: role.id,
                        child: Text(role.name.of(context)),
                      ),
                  ],
                  onChanged: _busy ? null : (v) => setState(() => _roleId = v),
                ),

              if (_scope == TaskScope.personal)
                DropdownButtonFormField<String>(
                  initialValue: _profileId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l.moduleTaskPersonLabel,
                  ),
                  items: [
                    for (final (id, name) in _people)
                      DropdownMenuItem(value: id, child: Text(name)),
                  ],
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _profileId = v),
                ),
              const SizedBox(height: AppSpacing.md),
            ],

            TextField(
              controller: _titleAr,
              enabled: !_busy,
              decoration: InputDecoration(labelText: l.moduleTaskTitleLabel),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _titleEn,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: l.moduleTaskTitleEnLabel,
                helperText: l.commonOptional,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _description,
              enabled: !_busy,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l.moduleTaskDescriptionLabel,
                helperText: l.commonOptional,
                alignLabelWithHint: true,
              ),
            ),

            if (stages.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String?>(
                initialValue: _groupId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.moduleTaskStageLabel),
                items: [
                  DropdownMenuItem(value: null, child: Text(l.moduleTaskNoStage)),
                  for (final stage in stages)
                    DropdownMenuItem(
                      value: stage.id,
                      child: Text(stage.name.of(context)),
                    ),
                ],
                onChanged: _busy ? null : (v) => setState(() => _groupId = v),
              ),
            ],

            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickDue,
              icon: const Icon(AppIcons.seasons, size: 18),
              label: Text(
                _dueOn == null
                    ? l.moduleTaskNoDue
                    : l.moduleTaskDue(formatDate(_dueOn)),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: text.bodySmall?.copyWith(color: scheme.error),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(AppIcons.approve),
              label: Text(l.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}
