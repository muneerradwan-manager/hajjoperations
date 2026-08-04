import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/glass_tokens.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/info_section.dart';
import '../../domain/evaluation.dart';
import 'evaluation_labels.dart';
import 'score_bar.dart';

/// One evaluation as a row in either register.
///
/// A finished sheet leads with its mark; an unfinished one leads with how far
/// through it is. The two are never both shown, because a running total on a
/// half-filled form is a score somebody would quote.
class EvaluationCard extends StatelessWidget {
  const EvaluationCard({
    super.key,
    required this.evaluation,
    this.onOpen,
    this.onDelete,
    this.showEvaluator = false,
  });

  final Evaluation evaluation;
  final VoidCallback? onOpen;

  /// Null where deleting is not this reader's to do — a person's own list of
  /// errands, where withdrawing the work is not the same as doing it.
  final VoidCallback? onDelete;

  /// Whether to name who is filling it. True in the register, false in a
  /// person's own list — where the evaluator is the reader.
  final bool showEvaluator;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final subject = (evaluation.targetLabel ?? '').trim().isEmpty
        ? evaluationTargetLabel(l, evaluation.target)
        : evaluation.targetLabel!;

    return GlassCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                evaluationTargetIcon(evaluation.target),
                color: evaluation.isOverdue ? scheme.error : scheme.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject, style: text.titleMedium),
                    const SizedBox(height: 2),
                    // The form's name second, in the smaller type: two sheets on
                    // the same subject differ by their paper, but it is the
                    // subject a reader scans the list for.
                    Text(
                      evaluation.templateTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                PopupMenuButton<int>(
                  icon: const Icon(AppIcons.more),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 0, child: Text(l.evaluationDelete)),
                  ],
                  onSelected: (_) => onDelete!(),
                )
              else
                const NavChevron(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (evaluation.isSubmitted)
            ScoreBar(
              score: evaluation.score ?? 0,
              total: evaluation.maxScore ?? 0,
              dense: true,
            )
          else
            _Progress(evaluation: evaluation),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              GlassBadge(
                label: evaluationTargetLabel(l, evaluation.target),
                icon: evaluationTargetIcon(evaluation.target),
                dense: true,
              ),
              GlassBadge(
                label: evaluation.isSubmitted
                    ? l.evaluationStatusSubmitted
                    : l.evaluationStatusDraft,
                icon: evaluation.isSubmitted
                    ? AppIcons.approve
                    : AppIcons.pending,
                color: evaluation.isSubmitted ? scheme.primary : scheme.tertiary,
                dense: true,
              ),
              if (evaluation.isOverdue)
                GlassBadge(
                  label: l.evaluationOverdue,
                  icon: AppIcons.warning,
                  color: scheme.error,
                  dense: true,
                )
              else if (evaluation.dueOn != null && !evaluation.isSubmitted)
                GlassBadge(
                  label: l.evaluationDueOn(formatDate(evaluation.dueOn)),
                  icon: AppIcons.seasons,
                  dense: true,
                ),
              if (showEvaluator && evaluation.evaluatorName != null)
                GlassBadge(
                  label: evaluation.evaluatorName!,
                  icon: AppIcons.employees,
                  dense: true,
                ),
              GlassBadge(
                label: evaluation.isSubmitted
                    ? l.evaluationSubmittedOn(formatDate(evaluation.submittedAt))
                    : l.evaluationOpenedOn(formatDate(evaluation.createdAt)),
                dense: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// How far through an unfinished sheet is — answered out of asked, and never a
/// mark. What a half-filled form adds up to is not information about anything.
class _Progress extends StatelessWidget {
  const _Progress({required this.evaluation});
  final Evaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l.evaluationProgress(
            evaluation.answeredCount,
            evaluation.questionCount,
          ),
          style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: evaluation.progress,
            minHeight: 5,
            backgroundColor: scheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            valueColor: AlwaysStoppedAnimation(
              evaluation.isOverdue ? scheme.error : scheme.secondary,
            ),
          ),
        ),
      ],
    );
  }
}
