import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/attachments/attachment_picker.dart';
import '../../../core/attachments/attachments_view.dart';
import '../../../core/constants/permission_codes.dart';
import '../../../core/l10n/error_text.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/creator_page.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/info_section.dart';
import '../../../core/widgets/overflow_menu.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/saved_copy_banner.dart';
import '../../../core/widgets/states.dart';
import '../../auth/application/session_cubit.dart';
import '../application/tasks_cubit.dart';
import '../data/tasks_repository.dart';
import '../domain/personal_task.dart';
import 'task_editor_screen.dart';
import 'widgets/task_state_widgets.dart';

/// One person's task list, and nothing else's.
///
/// This screen has no relation to the operational files, and no
/// administration either. What is on it came from exactly two pens: the
/// viewer's own — tasks they wrote for themselves, theirs entirely — and the
/// pen of whoever holds `tasks.assign`, whose tasks arrive with a
/// notification and offer the viewer one verb: say how it is going.
///
/// Assigning and managing what was assigned live behind their own door —
/// [TasksManageScreen] — because that is authority, and this page is work.
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key, this.compose = false});

  /// Open the editor as soon as the screen is up.
  ///
  /// Set by the button on the home card. The composer needs this screen's
  /// cubit, so it cannot be opened from the card directly — the card asks for
  /// the screen AND the sheet, and the screen provides both in the right
  /// order. A person who pressed "new task" should not have to press it again
  /// on arrival.
  final bool compose;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TasksCubit(TasksRepository()),
    child: _View(compose: compose),
  );
}

class _View extends StatefulWidget {
  const _View({this.compose = false});

  final bool compose;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  @override
  void initState() {
    super.initState();
    // After the first frame, so the sheet has a Scaffold to sit in — and once,
    // because `initState` is the only place that is true of. Opening it in
    // `build` would reopen it on every rebuild the list causes.
    if (widget.compose) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _add();
      });
    }
  }

  /// One way in and one way back: the editor is a page above this list, it
  /// says what it wrote, and closing it lands here — see [CreatorPage]. The
  /// cubit reloads itself on a successful write, so there is nothing to do
  /// with the answer but let the list rebuild.
  Future<void> _add() =>
      openTaskEditor(context, context.read<TasksCubit>());

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      appBar: GlassAppBar(title: Text(l.tasksTitle)),
      floatingActionButton: CreateFab(
        label: l.tasksNew,
        onPressed: _add,
      ),
      body: SafeArea(
        child: BlocBuilder<TasksCubit, TasksState>(
          builder: (context, state) {
            final cubit = context.read<TasksCubit>();

            if (state.status == TasksStatus.loading) {
              return ResponsivePage(
                builder: (context, size) => SkeletonList(
                  height: 120,
                  padding: context.scrollPadding(
                    horizontal: size.gutter,
                    bottom: AppSpacing.xl,
                  ),
                ),
              );
            }
            if (state.status == TasksStatus.error) {
              return EmptyState(
                icon: AppIcons.tasks,
                title: friendlyError(context, state.error),
                action: FilledButton(
                  onPressed: cubit.load,
                  child: Text(l.commonRetry),
                ),
              );
            }

            final own = state.own;
            final assignedToMe = state.assignedToMe;
            if (own.isEmpty && assignedToMe.isEmpty) {
              // The banner rides above the empty state too, and that case is
              // the one that most needs it: "you have nothing to do" read off a
              // saved copy is the most confidently wrong sentence this screen
              // can say. Empty because it was empty an hour ago is not the same
              // fact as empty now.
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      0,
                    ),
                    child: SavedCopyBanner(savedAt: state.savedAt),
                  ),
                  Expanded(
                    child: EmptyState(
                      icon: AppIcons.tasks,
                      title: l.tasksEmpty,
                      message: l.tasksEmptyHint,
                    ),
                  ),
                ],
              );
            }

            return ResponsivePage(
              builder: (context, size) => RefreshIndicator(
                onRefresh: cubit.load,
                child: ListView(
                  padding: context.scrollPadding(
                    horizontal: size.gutter,
                    bottom: AppSpacing.xl * 2,
                  ),
                  children: [
                    // Draws nothing when the read was live.
                    SavedCopyBanner(savedAt: state.savedAt),

                    // 1 — the viewer's own notebook.
                    if (own.isNotEmpty)
                      TaskGroupCard(
                        title: l.tasksOwnSection,
                        subtitle: l.tasksOwnHint,
                        icon: AppIcons.myProfile,
                        tasks: own,
                      ),

                    // 2 — what arrived with somebody else's name on the pen.
                    if (assignedToMe.isNotEmpty)
                      TaskGroupCard(
                        title: l.tasksAssignedSection,
                        subtitle: l.tasksAssignedHint,
                        icon: AppIcons.approvals,
                        tasks: assignedToMe,
                        showAuthor: true,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One heading and the tasks under it, with what they add up to on the right.
/// Shared with [TasksManageScreen], where each card is one person's share.
class TaskGroupCard extends StatelessWidget {
  const TaskGroupCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tasks,
    this.showAuthor = false,
    this.showOwner = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<PersonalTask> tasks;

  /// Name who assigned it — for the "assigned to me" section.
  final bool showAuthor;

  /// Name whose list it is on — for the assigner's follow-up section.
  final bool showOwner;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final (done, total) = PersonalTask.progressOf(tasks);

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
                Expanded(child: Text(title, style: text.titleSmall)),
                TaskProgressPill(done: done, total: total),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final task in tasks)
              _TaskRow(
                task: task,
                showAuthor: showAuthor,
                showOwner: showOwner,
              ),
          ],
        ),
      ),
    );
  }
}

/// One task: what it is, how it is going, and — when somebody has moved it —
/// what they said and attached.
class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    this.showAuthor = false,
    this.showOwner = false,
  });

  final PersonalTask task;
  final bool showAuthor;
  final bool showOwner;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final cubit = context.read<TasksCubit>();
    final note = task.note?.trim() ?? '';

    return InkWell(
      onTap: () => showTaskSheet(context, task: task),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: TaskStateDot(state: task.state),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: text.bodyMedium?.copyWith(
                      height: 1.5,
                      // Struck through, not greyed: a finished task is still
                      // part of the record and has to stay readable.
                      decoration: task.state.isDone
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (showOwner && task.ownerName != null)
                    Text(
                      l.taskAssignedTo(task.ownerName!),
                      style: text.labelSmall?.copyWith(color: scheme.primary),
                    ),
                  if (showAuthor && task.authorName != null)
                    Text(
                      l.taskAssignedBy(task.authorName!),
                      style: text.labelSmall?.copyWith(color: scheme.primary),
                    ),
                  if (task.description != null)
                    Text(
                      task.description!,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  if (task.dueOn != null)
                    Text(
                      l.taskDue(formatDate(task.dueOn)),
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
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TaskStateChip(state: task.state),
          ],
        ),
      ),
    );
  }
}

// ============================================================ the task sheet

/// Whether the viewer holds the full pen over [task]: its author always, and
/// an assigner over any assigned task. Mirrors `can_edit_personal_task`
/// (0105) — the button is only ever the polite half of the database's answer.
bool _canEdit(BuildContext context, PersonalTask task) {
  final me = TasksCubit.viewerId;
  if (task.createdBy == me) return true;
  return task.isAssigned &&
      context.read<SessionCubit>().state.can(PermissionCodes.tasksAssign);
}

/// Opening a task: the three states, a note, the evidence — and, for whoever
/// holds the full pen, the way to correct or withdraw the task itself.
Future<void> showTaskSheet(
  BuildContext context, {
  required PersonalTask task,
}) async {
  final cubit = context.read<TasksCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final label = context.l10n.taskStateSaved;
  final saved = await showAppSheet<bool>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _TaskSheet(task: task),
    ),
  );
  if (saved == true) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(label)));
  }
}

class _TaskSheet extends StatefulWidget {
  const _TaskSheet({required this.task});

  final PersonalTask task;

  @override
  State<_TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<_TaskSheet> {
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

  /// Closes this sheet and opens the editor on the same task. The sheet goes
  /// first: leaving it open under the editor page would leave a stale copy of
  /// the row behind the correction being made to it.
  Future<void> _edit() async {
    final cubit = context.read<TasksCubit>();
    final host = Navigator.of(context);
    host.pop();
    await openTaskEditor(host.context, cubit, existing: widget.task);
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.taskDelete),
        content: Text(l.taskDeleteConfirm),
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
    final error = await context.read<TasksCubit>().delete(widget.task);
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
    final outcome = await context.read<TasksCubit>().setTaskState(
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
    // Said plainly rather than passed over: a person who knows their phone had
    // no signal is owed the difference between "it is with them" and "it is
    // with the app".
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
    final canEdit = _canEdit(context, task);

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
                Expanded(child: Text(task.title, style: text.titleLarge)),
                // Correcting or withdrawing the task itself, for whoever holds
                // the full pen. Absent — not disabled — for its assignee: the
                // task is not theirs to rewrite, and a grey button would say
                // "yours, but broken". See [OverflowMenu].
                if (canEdit)
                  OverflowMenu(
                    actions: [
                      MenuAction(
                        icon: AppIcons.edit,
                        label: l.taskEdit,
                        onSelected: _edit,
                      ),
                      MenuAction(
                        icon: AppIcons.delete,
                        label: l.taskDelete,
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
                task.description!,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (task.isAssigned && task.authorName != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l.taskAssignedBy(task.authorName!),
                style: text.labelSmall?.copyWith(color: scheme.primary),
              ),
            ],
            if (task.isAssigned && !canEdit) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    AppIcons.warning,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l.taskReadOnly,
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
              l.taskState,
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final option in TaskState.values)
                  ChoiceChip(
                    label: Text(taskStateLabel(context, option)),
                    avatar: TaskStateDot(state: option),
                    selected: _state == option,
                    onSelected: _busy
                        ? null
                        : (_) => setState(() => _state = option),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),
            for (final attachment in _kept)
              _AttachmentRow(
                name: attachment.name,
                onRemove: _busy
                    ? null
                    : () => setState(() {
                        _kept.remove(attachment);
                        _removed.add(attachment);
                      }),
              ),
            for (var i = 0; i < _added.length; i++)
              PendingAttachmentRow(
                attachment: _added[i],
                onRemove: _busy
                    ? null
                    : () => setState(() => _added.removeAt(i)),
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _busy ? null : _attach,
                icon: const Icon(AppIcons.attach, size: 18),
                label: Text(l.taskEvidence),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _note,
              maxLines: 3,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: l.taskNote,
                helperText: l.taskNoteHint,
                alignLabelWithHint: true,
              ),
            ),

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
              label: Text(l.taskUpdate),
            ),
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
