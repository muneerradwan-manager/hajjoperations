import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/glass_tokens.dart';
import '../../domain/personal_task.dart';

/// The colour of a state, one place, so the dot and the chip cannot disagree.
Color taskStateColor(ColorScheme scheme, TaskState state) => switch (state) {
  TaskState.notStarted => scheme.onSurfaceVariant,
  TaskState.inProgress => scheme.tertiary,
  TaskState.done => scheme.primary,
};

String taskStateLabel(BuildContext context, TaskState state) => switch (state) {
  TaskState.notStarted => context.l10n.taskStateNotStarted,
  TaskState.inProgress => context.l10n.taskStateInProgress,
  TaskState.done => context.l10n.taskStateDone,
};

/// Three shapes, not three colours: an empty ring, a half-filled ring and a
/// tick. Colour alone would say nothing to a reader who cannot tell tertiary
/// from primary, and these are read at twelve pixels down a list of thirty.
class TaskStateDot extends StatelessWidget {
  const TaskStateDot({super.key, required this.state});

  final TaskState state;

  @override
  Widget build(BuildContext context) {
    final color = taskStateColor(Theme.of(context).colorScheme, state);
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

class TaskStateChip extends StatelessWidget {
  const TaskStateChip({super.key, required this.state});

  final TaskState state;

  @override
  Widget build(BuildContext context) {
    final color = taskStateColor(Theme.of(context).colorScheme, state);
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
        taskStateLabel(context, state),
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: color, height: 1.4),
      ),
    );
  }
}

/// "٤/٧" — how much of a list is behind it. Coloured only when it is all of it:
/// a green pill over four of seven would be a congratulation nobody earned.
class TaskProgressPill extends StatelessWidget {
  const TaskProgressPill({super.key, required this.done, required this.total});

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
        context.l10n.taskProgress(done, total),
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: color, height: 1.4),
      ),
    );
  }
}
