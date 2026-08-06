import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/error_text.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/states.dart';
import '../../seasons/data/seasons_repository.dart';
import '../application/reports_cubit.dart';
import '../data/reports_repository.dart';
import '../domain/report.dart';
import 'report_detail_screen.dart';

/// عام ← التقارير.
///
/// Everything published, in one list, whatever kind it is. The reader is never
/// shown the notion of a report TYPE — only the reports — but the type is a way
/// of narrowing a list that will get long, so it appears as a filter under a
/// plain name.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ReportsCubit(ReportsRepository(), SeasonsRepository()),
    child: const _View(),
  );
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      appBar: GlassAppBar(title: Text(l.navReports)),
      body: SafeArea(
        child: BlocBuilder<ReportsCubit, ReportsState>(
          builder: (context, state) {
            final cubit = context.read<ReportsCubit>();

            if (state.status == ReportsStatus.loading) {
              // The same grid the list uses — 380 wide, two columns at most,
              // inside the same 1200 page — so the cards do not jump when the
              // real ones arrive.
              return ResponsivePage(
                maxWidth: 1200,
                builder: (context, size) => SkeletonList(
                  minTileWidth: 380,
                  maxColumns: 2,
                  height: 108,
                  padding: context.scrollPadding(
                    horizontal: size.gutter,
                    bottom: AppSpacing.xl,
                  ),
                ),
              );
            }
            if (state.status == ReportsStatus.error) {
              return EmptyState(
                icon: AppIcons.reports,
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
                ReportsFilterBar(state: state),
                Expanded(
                  child: visible.isEmpty
                      ? EmptyState(
                          icon: AppIcons.reports,
                          // "Nothing matches" and "nothing has been published"
                          // are different failures and read differently.
                          title: state.isNarrowed
                              ? l.reportsNoMatches
                              : l.reportsEmpty,
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
                              // Cap the cascade so a row first built deep in the scroll doesn't
                              // sit invisible for seconds (same rule as the directory).
                              delay: Duration(milliseconds: 25 * (i < 8 ? i : 8)),
                              child: ReportCard(report: visible[i]),
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

/// Search, "this season / general", and the kinds present — shared by the
/// reader's list and the office's, because the two show the same rows and
/// narrowing them is the same question.
class ReportsFilterBar extends StatefulWidget {
  const ReportsFilterBar({super.key, required this.state});
  final ReportsState state;

  @override
  State<ReportsFilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<ReportsFilterBar> {
  late final _controller = TextEditingController(text: widget.state.query);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cubit = context.read<ReportsCubit>();
    final s = widget.state;

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
                  hintText: l.reportsSearchHint,
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
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final scope in ReportScope.values)
                  ChoiceChip(
                    label: Text(switch (scope) {
                      ReportScope.all => l.reportsScopeAll,
                      ReportScope.seasonal => l.reportsScopeSeasonal,
                      ReportScope.general => l.reportsScopeGeneral,
                    }),
                    selected: s.scope == scope,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => cubit.setScope(scope),
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
        ),
      ),
    );
  }
}

/// One report as a row in either list.
///
/// [trailing] is what the office puts there — its overflow menu. عام passes
/// nothing and gets the chevron, which is the honest affordance for a card that
/// only opens.
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.report,
    this.onOpen,
    this.trailing,
  });

  final Report report;
  final VoidCallback? onOpen;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return GlassCard(
      onTap:
          onOpen ??
          () => Navigator.of(context).push(
            fadeThroughRoute((_) => ReportDetailScreen(reportId: report.id)),
          ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.reports, color: scheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.title, style: text.titleMedium),
                if (report.typeName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    report.typeName!.of(context),
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    // First, because it is what the reader is sorting by
                    // without being asked to: a قرار binds him and a تعميم
                    // tells him something. In one undifferentiated list he
                    // reads past everything he merely needs to know to find
                    // what he must do (0102).
                    GlassBadge(
                      label: report.kind == DecisionKind.circular
                          ? l.reportKindCircular
                          : l.reportKindDecision,
                      icon: report.kind == DecisionKind.circular
                          ? AppIcons.send
                          : AppIcons.file,
                      color: report.kind == DecisionKind.circular
                          ? scheme.tertiary
                          : scheme.primary,
                      dense: true,
                    ),
                    // Which of the two it is, said plainly — a reader looking
                    // at a meal timetable needs to know whether it is THIS
                    // year's.
                    GlassBadge(
                      label: report.isSeasonal
                          ? l.seasonHijriYear(report.seasonHijriYear ?? 0)
                          : l.reportsScopeGeneral,
                      icon: report.isSeasonal
                          ? AppIcons.seasons
                          : AppIcons.reports,
                      color: report.isSeasonal
                          ? scheme.secondary
                          : scheme.tertiary,
                      dense: true,
                    ),
                    // Beside the year, because a reader looking for '3190' is
                    // looking for exactly that.
                    if ((report.number ?? '').isNotEmpty)
                      GlassBadge(
                        label: l.reportNumberBadge(report.number!),
                        icon: AppIcons.document,
                        dense: true,
                      ),
                    if (!report.isPublished)
                      GlassBadge(
                        label: l.reportsDraft,
                        icon: AppIcons.pending,
                        color: scheme.error,
                        dense: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
          trailing ?? const NavChevron(),
        ],
      ),
    );
  }
}
