import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/constants/permission_codes.dart';
import '../../../core/l10n/error_text.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/states.dart';
import '../../auth/application/session_cubit.dart';
import '../application/evaluations_cubit.dart';
import '../data/evaluations_repository.dart';
import '../domain/evaluation.dart';
import 'evaluation_sheet_screen.dart';
import 'widgets/evaluation_card.dart';
import 'widgets/evaluation_labels.dart';

/// The register, asked one of two ways.
///
/// [EvaluationsScope.mine] is عام ← التقييمات and is everybody's: it lists the
/// errands this person was given, and nothing else — being allowed to read every
/// evaluation does not make every evaluation yours to fill.
/// [EvaluationsScope.all] is الإدارة ← سجل التقييمات and asks for
/// `evaluations.view`; the server refuses the wider question to anyone who may
/// not ask it, so the screen does not have to be trusted to hide it.
///
/// What was written ABOUT this person is in neither list. That is on their own
/// profile, because it is the one place a man looks for what is being said about
/// him — and because it is read through the one function that redacts.
///
/// And neither list OPENS one. There is no button here to hand out an errand,
/// in either scope: a register is a record of what was done, and a screen that
/// both records the work and issues it is two rooms with one door. Opening an
/// evaluation happens in إدارة التقييم, standing on the form it will be filled
/// on — which is also the order the act really has, since the form settles what
/// kind of thing may be named next.
class EvaluationsScreen extends StatelessWidget {
  const EvaluationsScreen({
    super.key,
    this.scope = EvaluationsScope.mine,
    this.templateId,
    this.title,
  });

  final EvaluationsScope scope;

  /// Opened from one form, showing only what was issued on it. This is the way
  /// out of the dead end deleting a form used to be: the database refuses while
  /// sheets exist, and until now there was nowhere to go and look at them.
  final String? templateId;

  /// Overrides the app-bar title — the form's name, when opened from a form.
  final String? title;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => EvaluationsCubit(
      EvaluationsRepository(),
      scope: scope,
      templateId: templateId,
    ),
    child: _View(scope: scope, title: title),
  );
}

class _View extends StatelessWidget {
  const _View({required this.scope, this.title});
  final EvaluationsScope scope;
  final String? title;

  Future<void> _delete(BuildContext context, Evaluation evaluation) async {
    final l = context.l10n;
    final cubit = context.read<EvaluationsCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(evaluation.targetLabel ?? evaluation.templateTitle),
        content: Text(l.evaluationDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final error = await cubit.delete(evaluation.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            error == null ? l.evaluationDeleted : friendlyErrorL(l, error),
          ),
        ),
      );
  }

  Future<void> _open(
    BuildContext context,
    Evaluation evaluation,
    bool canReopen,
  ) async {
    final cubit = context.read<EvaluationsCubit>();
    await Navigator.of(context).push(
      fadeThroughRoute(
        (_) => EvaluationSheetScreen(
          evaluationId: evaluation.id,
          canReopen: canReopen,
        ),
      ),
    );
    // Always, rather than on a returned flag: a sheet can be saved, submitted
    // or reopened in there, and each of the three changes the row behind it.
    await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = context.watch<SessionCubit>().state;
    final mine = scope == EvaluationsScope.mine;
    // Still read, and only for the one thing this screen still does with it:
    // sending a finished sheet back is an act ON a record, so it belongs to the
    // screen that holds the records.
    final canReopen = session.can(PermissionCodes.evaluationsAssign);
    // Deleting a sheet. Drawn for whoever holds the code; the database also
    // lets whoever ISSUED one withdraw it while it is untouched, and that
    // narrower right is left to the server to answer — a card that offers the
    // action and is refused says more than one that silently omits it.
    final canDelete =
        session.can(PermissionCodes.evaluationsDelete) ||
        session.can(PermissionCodes.evaluationsAssign);

    return Scaffold(
      appBar: GlassAppBar(
        title: Text(
          title ?? (mine ? l.evaluationsMineTitle : l.evaluationsTitle),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<EvaluationsCubit, EvaluationsState>(
          builder: (context, state) {
            final cubit = context.read<EvaluationsCubit>();

            if (state.status == EvaluationsStatus.loading) {
              return ResponsivePage(
                maxWidth: 1200,
                builder: (context, size) => SkeletonList(
                  minTileWidth: 380,
                  maxColumns: 2,
                  height: 168,
                  padding: context.scrollPadding(
                    horizontal: size.gutter,
                    bottom: AppSpacing.xl,
                  ),
                ),
              );
            }
            if (state.status == EvaluationsStatus.error) {
              return EmptyState(
                icon: AppIcons.evaluations,
                title: friendlyError(context, state.error),
                action: FilledButton(
                  onPressed: cubit.load,
                  child: Text(l.commonRetry),
                ),
              );
            }

            final visible = state.visible;
            return Column(
              children: [
                _FilterBar(state: state),
                Expanded(
                  child: visible.isEmpty
                      ? EmptyState(
                          icon: AppIcons.evaluations,
                          title: state.isNarrowed
                              ? l.evaluationsNoMatches
                              : (mine
                                    ? l.evaluationsEmpty
                                    : l.evaluationsEmptyAll),
                          // No way in from here either. An empty register is
                          // answered in إدارة التقييم, on the form the first
                          // evaluation will be opened against.
                          message: !mine && !state.isNarrowed
                              ? l.evaluationsOpenFromForms
                              : null,
                        )
                      : ResponsivePage(
                          maxWidth: 1200,
                          builder: (context, size) => AdaptiveGridView(
                            padding: EdgeInsets.fromLTRB(
                              size.gutter,
                              AppSpacing.sm,
                              size.gutter,
                              AppSpacing.xl +
                                  MediaQuery.viewPaddingOf(context).bottom,
                            ),
                            onRefresh: cubit.load,
                            minTileWidth: 380,
                            maxColumns: 2,
                            spacing: AppSpacing.md,
                            itemCount: visible.length,
                            itemBuilder: (context, i) => FadeSlideIn(
                              delay: Duration(
                                milliseconds: 25 * (i < 8 ? i : 8),
                              ),
                              child: EvaluationCard(
                                evaluation: visible[i],
                                showEvaluator: !mine,
                                onOpen: () =>
                                    _open(context, visible[i], canReopen),
                                onDelete: !mine && canDelete
                                    ? () => _delete(context, visible[i])
                                    : null,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterBar extends StatefulWidget {
  const _FilterBar({required this.state});
  final EvaluationsState state;

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  late final _controller = TextEditingController(text: widget.state.query);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cubit = context.read<EvaluationsCubit>();
    final scheme = Theme.of(context).colorScheme;
    final s = widget.state;

    // Only the kinds actually present. Offering all seven over a list of two
    // sheets is a menu of dead ends.
    final kinds = <EvaluationTarget>{for (final e in s.evaluations) e.target};

    return ResponsivePage(
      maxWidth: 1200,
      builder: (context, size) => Padding(
        padding: EdgeInsets.fromLTRB(
          size.gutter,
          AppSpacing.sm,
          size.gutter,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onChanged: cubit.search,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l.evaluationsSearchHint,
                  prefixIcon: const Icon(AppIcons.search, size: 20),
                  suffixIcon: s.query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(AppIcons.reject, size: 18),
                          onPressed: () {
                            _controller.clear();
                            cubit.search('');
                          },
                        ),
                ),
              ),
            ),
            // What is still owed, said once and above the filters — it is the
            // reason somebody opened this screen, and it must not be a number
            // they have to count off the cards.
            if (s.openCount > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  GlassBadge(
                    label: l.evaluationsOpenCount(s.openCount),
                    icon: AppIcons.pending,
                    color: scheme.tertiary,
                    dense: true,
                  ),
                  if (s.overdueCount > 0)
                    GlassBadge(
                      label: l.evaluationsOverdueCount(s.overdueCount),
                      icon: AppIcons.warning,
                      color: scheme.error,
                      dense: true,
                    ),
                ],
              ),
            ],
            if (kinds.length > 1 || s.isNarrowed) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ChoiceChip(
                    label: Text(l.evaluationsFilterAll),
                    selected: s.target == null && s.filterStatus == null,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => cubit.clearFilters(),
                  ),
                  ChoiceChip(
                    label: Text(l.evaluationStatusDraft),
                    selected: s.filterStatus == EvaluationStatus.draft,
                    visualDensity: VisualDensity.compact,
                    onSelected: (on) =>
                        cubit.setStatus(on ? EvaluationStatus.draft : null),
                  ),
                  ChoiceChip(
                    label: Text(l.evaluationStatusSubmitted),
                    selected: s.filterStatus == EvaluationStatus.submitted,
                    visualDensity: VisualDensity.compact,
                    onSelected: (on) =>
                        cubit.setStatus(on ? EvaluationStatus.submitted : null),
                  ),
                  for (final kind in EvaluationTarget.values)
                    if (kinds.contains(kind))
                      ChoiceChip(
                        label: Text(evaluationTargetLabel(l, kind)),
                        selected: s.target == kind,
                        visualDensity: VisualDensity.compact,
                        onSelected: (on) => cubit.setTarget(on ? kind : null),
                      ),
                  if (s.isNarrowed)
                    TextButton.icon(
                      onPressed: () {
                        _controller.clear();
                        cubit.clearFilters();
                      },
                      icon: const Icon(AppIcons.reject, size: 16),
                      label: Text(l.moduleRosterClear),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
