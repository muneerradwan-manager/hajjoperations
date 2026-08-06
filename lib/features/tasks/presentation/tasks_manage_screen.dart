import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/error_text.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/states.dart';
import '../../auth/application/session_cubit.dart';
import '../../modules/presentation/employee_picker_screen.dart';
import '../application/tasks_cubit.dart';
import '../data/tasks_repository.dart';
import '../domain/personal_task.dart';
import 'tasks_screen.dart';

/// Assigning tasks and following them up — the authority half of the tasks
/// system, behind `tasks.assign` (the router guards the door).
///
/// Deliberately a different page from «مهامي»: that one is a person's own
/// work and belongs to everybody; this one writes onto OTHER people's lists.
/// Each card below is one person and their share, with the full pen — edit,
/// withdraw, and read how it is going.
class TasksManageScreen extends StatelessWidget {
  const TasksManageScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TasksCubit(TasksRepository(), manage: true),
    child: const _View(),
  );
}

class _View extends StatelessWidget {
  const _View();

  /// Assigning: name the people first, then write the task once.
  ///
  /// The mission's own roster page — the same one postings are made on — and
  /// deliberately so: choosing who a duty is for is decided against what each
  /// candidate already carries, and that page is the only one that shows it
  /// (the files they serve in this season), along with the search and the
  /// filters by post, by city and by internal/external.
  ///
  /// SEVERAL people at once, because that is how a duty is actually handed
  /// out: «استلام كشوف الحجاج» goes to six supervisors in one decision, not in
  /// six visits to this screen. Each gets a row of their own from there.
  ///
  /// The assigner is kept off the list: a task pointed back at its own author
  /// is by definition not an assignment, and it would land on «مهامي» and
  /// vanish from this page — reading exactly like a failure.
  Future<void> _assign(BuildContext context) async {
    final cubit = context.read<TasksCubit>();
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

    await showTaskEditorSheet(
      context,
      cubit,
      assignTo: [
        for (final p in people) (p.profile.id, p.profile.fullName),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      appBar: GlassAppBar(title: Text(l.tasksManageTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _assign(context),
        icon: const Icon(AppIcons.add),
        label: Text(l.tasksAssign),
      ),
      body: SafeArea(
        child: BlocBuilder<TasksCubit, TasksState>(
          builder: (context, state) {
            final cubit = context.read<TasksCubit>();

            if (state.status == TasksStatus.loading) {
              return ResponsivePage(
                maxWidth: 900,
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

            final assigned = state.assignedByMe;
            if (assigned.isEmpty) {
              return EmptyState(
                icon: AppIcons.tasks,
                title: l.tasksManageEmpty,
                message: l.tasksManageEmptyHint,
              );
            }

            // One card per person, in the order their newest task arrived —
            // the same list merged would let one man's unfinished work hide
            // behind another's ticks.
            final byOwner = <String, List<PersonalTask>>{};
            for (final task in assigned) {
              (byOwner[task.profileId] ??= []).add(task);
            }

            return ResponsivePage(
              maxWidth: 900,
              builder: (context, size) => RefreshIndicator(
                onRefresh: cubit.load,
                child: ListView(
                  padding: context.scrollPadding(
                    horizontal: size.gutter,
                    bottom: AppSpacing.xl * 2,
                  ),
                  children: [
                    for (final tasks in byOwner.values)
                      TaskGroupCard(
                        title:
                            tasks.first.ownerName ?? l.taskPickPerson,
                        subtitle: l.tasksIAssignedHint,
                        icon: AppIcons.myProfile,
                        tasks: tasks,
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
