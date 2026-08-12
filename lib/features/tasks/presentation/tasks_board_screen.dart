import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/constants/permission_codes.dart';
import '../../../core/l10n/error_text.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/offline/save_outcome.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/creator_page.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/states.dart';
import '../../auth/application/session_cubit.dart';
import '../../modules/presentation/employee_picker_screen.dart';
import '../application/tasks_board_cubit.dart';
import '../data/tasks_repository.dart';
import '../domain/personal_task.dart';
import 'task_detail_screen.dart';
import 'task_editor_screen.dart';
import 'widgets/task_batch_sheet.dart';
import 'widgets/task_card.dart';
import 'widgets/task_state_widgets.dart';

/// Assigning tasks and following them up — the authority half of the tasks
/// system, behind `tasks.assign` (the router guards the door).
///
/// Deliberately a different page from «مهامي»: that one is a person's own work
/// and belongs to everybody; this one writes onto OTHER people's lists.
///
/// It is the one screen in this system that earns COLUMNS, and the reason is
/// posture: its reader is sitting at a desk deciding what to do about six
/// people's work, not standing in a camp doing their own. «مهامي» stays a list
/// for the same reason.
///
/// Three views over one read (0118): by state, by decision, by person. The last
/// is 0105's behaviour, kept — "what is سعد carrying?" is still a real question
/// — and the first two are the two it could not answer.
class TasksBoardScreen extends StatelessWidget {
  const TasksBoardScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TasksBoardCubit(TasksRepository()),
    child: const _View(),
  );
}

class _View extends StatelessWidget {
  const _View();

  /// Assigning: name the people first, then write the task once.
  ///
  /// The mission's own roster page — the same one postings are made on — and
  /// deliberately so: choosing who a duty is for is decided against what each
  /// candidate already carries, and that page is the only one that shows it.
  ///
  /// SEVERAL people at once, because that is how a duty is actually handed out:
  /// «استلام كشوف الحجاج» goes to six supervisors in one decision. Since 0118
  /// that decision leaves ONE thing behind — a batch — instead of six rows that
  /// forget they were ever related.
  ///
  /// The assigner is kept off the list: a task pointed back at its own author
  /// is by definition not an assignment, and it would land on «مهامي» and
  /// vanish from this page — reading exactly like a failure.
  Future<void> _assign(BuildContext context) async {
    final cubit = context.read<TasksBoardCubit>();
    final me = context.read<SessionCubit>().state.profile?.id;
    final seasonId = cubit.state.seasonId;
    if (seasonId == null) return;

    final people = await showMultiEmployeePicker(
      context,
      title: context.l10n.tasksAssign,
      seasonId: seasonId,
      selected: const [],
      exclude: {?me},
    );
    if (people == null || people.isEmpty || !context.mounted) return;

    if (!context.mounted) return;
    await openTaskEditor(
      context,
      assignTo: [for (final p in people) (p.profile.id, p.profile.fullName)],
      // Never queued: an assignment that arrives six hours late is worse than
      // one that visibly failed to send.
      onSubmit: (draft) async {
        final error = await cubit.assign(
          title: draft.title,
          description: draft.description,
          dueOn: draft.dueOn,
          profileIds: {for (final p in people) p.profile.id},
          priority: draft.priority,
          kind: draft.kind,
          steps: draft.steps,
        );
        return error == null
            ? const SaveOutcome.sent()
            : SaveOutcome.failed(error);
      },
    );
  }

  Future<void> _open(BuildContext context, PersonalTask task) async {
    final cubit = context.read<TasksBoardCubit>();
    await Navigator.of(
      context,
    ).push(fadeThroughRoute((_) => TaskDetailScreen(taskId: task.id)));
    await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final canSeeAll = context.select<SessionCubit, bool>(
      (c) => c.state.can(PermissionCodes.tasksViewAll),
    );

    return Scaffold(
      appBar: GlassAppBar(title: Text(l.tasksBoardTitle)),
      floatingActionButton: CreateFab(
        label: l.tasksAssign,
        onPressed: () => _assign(context),
      ),
      body: SafeArea(
        child: BlocBuilder<TasksBoardCubit, TasksBoardState>(
          builder: (context, state) {
            final cubit = context.read<TasksBoardCubit>();

            if (state.status == BoardStatus.loading) {
              return ResponsivePage(
                builder: (context, size) => SkeletonList(
                  height: 132,
                  padding: context.scrollPadding(
                    horizontal: size.gutter,
                    bottom: AppSpacing.xl,
                  ),
                ),
              );
            }
            if (state.status == BoardStatus.error) {
              return EmptyState(
                icon: AppIcons.tasks,
                title: friendlyError(context, state.error),
                action: FilledButton(
                  onPressed: cubit.load,
                  child: Text(l.commonRetry),
                ),
              );
            }

            return ResponsivePage(
              builder: (context, size) => Column(
                children: [
                  _Bar(state: state, canSeeAll: canSeeAll),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: cubit.load,
                      child: switch (state.view) {
                        BoardView.board => _BoardView(
                          state: state,
                          gutter: size.gutter,
                          onOpen: (task) => _open(context, task),
                        ),
                        BoardView.batches => _BatchesView(
                          state: state,
                          gutter: size.gutter,
                        ),
                        BoardView.people => _PeopleView(
                          state: state,
                          gutter: size.gutter,
                          onOpen: (task) => _open(context, task),
                        ),
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The three views, and the switch between "what I assigned" and "the mission".
class _Bar extends StatelessWidget {
  const _Bar({required this.state, required this.canSeeAll});

  final TasksBoardState state;
  final bool canSeeAll;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cubit = context.read<TasksBoardCubit>();
    final scheme = Theme.of(context).colorScheme;
    final review = state.review.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (view, label) in [
                        (BoardView.board, l.tasksBoardView),
                        (BoardView.batches, l.tasksBatchesView),
                        (BoardView.people, l.tasksPeopleView),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.sm),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: state.view == view,
                            onSelected: (_) => cubit.setView(view),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Offered only to whoever holds the wider grant. Absent, not
              // disabled: a switch that says "the whole mission" and refuses is
              // an advertisement for a permission.
              if (canSeeAll)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(
                      state.everyone ? l.tasksScopeAll : l.tasksScopeMine,
                    ),
                    selected: state.everyone,
                    onSelected: cubit.setEveryone,
                  ),
                ),
            ],
          ),

          // The queue that is a JOB. Above the views rather than inside one,
          // because it is the reason this page is opened and it must not be
          // something the reader has to go and find in a column.
          if (review > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            GlassCard(
              onTap: () => cubit.setView(BoardView.board),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              tint: scheme.secondary,
              child: Row(
                children: [
                  Icon(AppIcons.send, size: 16, color: scheme.secondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l.tasksReviewQueue,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TaskProgressPill(done: review, total: review),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The columns.
///
/// Stacked rather than side by side, and that is not a compromise: five columns
/// abreast on a telephone are five columns nobody can read, and this page is
/// opened on a telephone as often as on a laptop. Each state is a band with its
/// count, and the bands are in the order 0118 sorts by — what is wrong first.
class _BoardView extends StatelessWidget {
  const _BoardView({
    required this.state,
    required this.gutter,
    required this.onOpen,
  });

  final TasksBoardState state;
  final double gutter;
  final void Function(PersonalTask task) onOpen;

  static const _columns = [
    TaskState.submitted,
    TaskState.blocked,
    TaskState.returned,
    TaskState.inProgress,
    TaskState.notStarted,
    TaskState.done,
  ];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final padding = context.scrollPadding(
      horizontal: gutter,
      bottom: AppSpacing.xl * 2,
    );

    if (state.tasks.isEmpty) {
      return _empty(context, padding);
    }

    return ListView(
      padding: padding,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        for (final column in _columns)
          if (state.inState(column) case final tasks when tasks.isNotEmpty) ...[
            _Band(
              label: taskStateLabel(context, column),
              count: tasks.length,
              state: column,
            ),
            for (final task in tasks)
              TaskCard(
                task: task,
                showOwner: true,
                onTap: () => onOpen(task),
              ),
          ],
        if (state.inState(TaskState.cancelled) case final gone
            when gone.isNotEmpty) ...[
          _Band(
            label: l.taskStateCancelled,
            count: gone.length,
            state: TaskState.cancelled,
          ),
          for (final task in gone)
            TaskCard(task: task, showOwner: true, onTap: () => onOpen(task)),
        ],
      ],
    );
  }

  Widget _empty(BuildContext context, EdgeInsets padding) => ListView(
    padding: padding,
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      const SizedBox(height: AppSpacing.xl),
      EmptyState(
        icon: AppIcons.tasks,
        title: context.l10n.tasksManageEmpty,
        message: context.l10n.tasksManageEmptyHint,
      ),
    ],
  );
}

class _Band extends StatelessWidget {
  const _Band({
    required this.label,
    required this.count,
    required this.state,
  });

  final String label;
  final int count;
  final TaskState state;

  @override
  Widget build(BuildContext context) {
    final colour = taskStateColor(Theme.of(context).colorScheme, state);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          TaskStateDot(state: state, size: 14),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colour,
              ),
            ),
          ),
          Text(
            '$count',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colour,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// One decision per card, with what it adds up to — the screen 0105 could not
/// draw, because there was nothing in the data that knew six rows were one act.
class _BatchesView extends StatelessWidget {
  const _BatchesView({required this.state, required this.gutter});

  final TasksBoardState state;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final padding = context.scrollPadding(
      horizontal: gutter,
      bottom: AppSpacing.xl * 2,
    );

    if (state.batches.isEmpty) {
      return ListView(
        padding: padding,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: AppSpacing.xl),
          EmptyState(
            icon: AppIcons.taskBatch,
            title: l.tasksBatchesEmpty,
            message: l.tasksBatchesEmptyHint,
          ),
        ],
      );
    }

    return ListView(
      padding: padding,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        for (final batch in state.batches)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: GlassCard(
              onTap: () => showTaskBatchSheet(context, batch: batch),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        AppIcons.taskBatch,
                        size: 16,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(batch.title, style: text.titleSmall),
                      ),
                      TaskProgressPill(done: batch.done, total: batch.total),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TaskProgressBar(value: batch.progress),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Text(
                        l.taskBatchCarriers(batch.total),
                        style: text.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      // The three numbers worth naming out of eight. Each is a
                      // different job: accept these, chase those, worry about
                      // the last.
                      if (batch.submitted > 0)
                        _Count(
                          label: l.taskStateSubmitted,
                          count: batch.submitted,
                          colour: scheme.secondary,
                        ),
                      if (batch.blocked > 0)
                        _Count(
                          label: l.taskStateBlocked,
                          count: batch.blocked,
                          colour: scheme.error,
                        ),
                      if (batch.overdue > 0)
                        _Count(
                          label: l.taskViewOverdue,
                          count: batch.overdue,
                          colour: scheme.error,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({
    required this.label,
    required this.count,
    required this.colour,
  });

  final String label;
  final int count;
  final Color colour;

  @override
  Widget build(BuildContext context) => Text(
    '$label $count',
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: colour,
      fontWeight: FontWeight.w700,
    ),
  );
}

/// 0105's screen, kept whole: one card per person and their share.
class _PeopleView extends StatelessWidget {
  const _PeopleView({
    required this.state,
    required this.gutter,
    required this.onOpen,
  });

  final TasksBoardState state;
  final double gutter;
  final void Function(PersonalTask task) onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final padding = context.scrollPadding(
      horizontal: gutter,
      bottom: AppSpacing.xl * 2,
    );
    final grouped = state.byPerson;

    if (grouped.isEmpty) {
      return ListView(
        padding: padding,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: AppSpacing.xl),
          EmptyState(
            icon: AppIcons.tasks,
            title: l.tasksManageEmpty,
            message: l.tasksManageEmptyHint,
          ),
        ],
      );
    }

    return ListView(
      padding: padding,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        for (final tasks in grouped.values) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(AppIcons.myProfile, size: 16, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    tasks.first.ownerName ?? l.taskPickPerson,
                    style: text.titleSmall,
                  ),
                ),
                TaskProgressPill(
                  done: PersonalTask.progressOf(tasks).$1,
                  total: PersonalTask.progressOf(tasks).$2,
                ),
              ],
            ),
          ),
          for (final task in tasks)
            TaskCard(task: task, onTap: () => onOpen(task)),
        ],
      ],
    );
  }
}
