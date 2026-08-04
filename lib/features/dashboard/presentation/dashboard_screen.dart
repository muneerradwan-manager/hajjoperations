import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/error_text.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/l10n/permission_labels.dart';
import '../../../core/theme/app_accents.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../application/dashboard_cubit.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_stats.dart';
import 'widgets/charts.dart';

/// The season, from above.
///
/// Every other screen in this app answers one question about one row. This is
/// the only one that answers a question about the whole season — how many of
/// its files are actually running, whether the people who owe reports are
/// filing them, where the mission's strength sits.
///
/// What appears depends entirely on what the reader holds. The database drops
/// the sections a permission does not cover rather than zeroing them, and this
/// screen draws whatever it was handed: a man with `approvals.decide` and
/// nothing else sees the queue and no files at all. That is why there is no
/// permission check anywhere below — the answer already arrived filtered, and
/// checking again here would be a second, disagreeing copy of the same rule.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardCubit(DashboardRepository()),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(title: Text(l.dashboardTitle)),
      body: Builder(
        builder: (context) => BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state.status == DashboardStatus.loading &&
                state.stats.season == null) {
              return const SkeletonList(count: 4, minTileWidth: 220);
            }
            if (state.status == DashboardStatus.error) {
              return EmptyState(
                icon: AppIcons.dashboard,
                title: friendlyError(context, state.error),
                action: FilledButton(
                  onPressed: () => context.read<DashboardCubit>().refresh(),
                  child: Text(l.commonRetry),
                ),
              );
            }
            if (state.stats.season == null) {
              return EmptyState(
                icon: AppIcons.seasons,
                title: l.dashboardNoSeason,
              );
            }

            return ResponsivePage(
              builder: (context, size) => SinglePaneLayout(
                gutter: size.gutter,
                onRefresh: () => context.read<DashboardCubit>().refresh(),
                children: _sections(context, l, state),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _sections(
    BuildContext context,
    AppLocalizations l,
    DashboardState state,
  ) {
    final stats = state.stats;

    if (stats.isEmpty) {
      return [
        const SizedBox(height: AppSpacing.xl),
        _SeasonFilter(state: state),
        const SizedBox(height: AppSpacing.xxl),
        EmptyState(icon: AppIcons.dashboard, title: l.dashboardNothingToShow),
      ];
    }

    return [
      FadeSlideIn(child: _SeasonFilter(state: state)),
      const SizedBox(height: AppSpacing.lg),

      // The headline row: the four or five numbers somebody opens this page to
      // read. Everything below explains one of them.
      AdaptiveGrid(
        minTileWidth: 200,
        maxColumns: 4,
        children: staggered(_headline(context, l, stats)),
      ),

      if (stats.people != null) ...[
        const SizedBox(height: AppSpacing.xl),
        FadeSlideIn(
          child: SectionHeader(
            l.dashboardSectionPeople,
            icon: AppIcons.participants,
          ),
        ),
        _cards([
          _Card(
            title: l.dashboardInternal,
            child: SplitBar(
              slices: [
                ChartSlice(
                  label: l.dashboardInternal,
                  value: stats.people!.internal,
                ),
                ChartSlice(
                  label: l.dashboardExternal,
                  value: stats.people!.external,
                ),
              ],
            ),
          ),
          _Card(
            title: l.dashboardByMission,
            child: SplitBar(
              slices: [
                for (final m in stats.people!.byMission)
                  ChartSlice(label: _label(context, m), value: m.count),
              ],
            ),
          ),
          _Card(
            title: l.dashboardByGender,
            child: SplitBar(
              slices: [
                for (final g in stats.people!.byGender)
                  ChartSlice(label: _gender(l, g.key), value: g.count),
              ],
            ),
          ),
          if (stats.people!.byJobTitle.isNotEmpty)
            _Card(
              title: l.dashboardByJobTitle,
              child: RankedBars(
                slices: [
                  for (final t in stats.people!.byJobTitle)
                    ChartSlice(label: _label(context, t), value: t.count),
                ],
              ),
            ),
        ]),
      ],

      if (stats.modules != null) ...[
        const SizedBox(height: AppSpacing.xl),
        FadeSlideIn(
          child: SectionHeader(
            l.dashboardSectionModules,
            icon: AppIcons.modules,
          ),
        ),
        AdaptiveGrid(
          minTileWidth: 200,
          maxColumns: 4,
          children: staggered([
            StatTile(
              label: l.dashboardRunning,
              value: '${stats.modules!.running}',
              icon: AppIcons.activate,
              color: Accent.green.of(context),
            ),
            StatTile(
              label: l.dashboardEnded,
              value: '${stats.modules!.ended}',
              icon: AppIcons.pending,
              color: Accent.goldSoft.of(context),
            ),
            StatTile(
              label: l.dashboardNodes,
              value: '${stats.modules!.nodes}',
              icon: AppIcons.roles,
              color: Accent.greenDeep.of(context),
            ),
            // Drawn in the alarm colour only when it is not zero: a red tile
            // that is always there stops being a warning and becomes furniture.
            StatTile(
              label: l.dashboardUnstaffed,
              value: '${stats.modules!.unstaffed}',
              icon: AppIcons.emptyInbox,
              color: stats.modules!.unstaffed > 0
                  ? Theme.of(context).colorScheme.error
                  : Accent.greenDark.of(context),
              caption: stats.modules!.unstaffed > 0
                  ? l.dashboardUnstaffedCaption
                  : null,
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        _cards([
          _Card(
            title: l.dashboardActiveDraft,
            child: SplitBar(
              slices: [
                ChartSlice(
                  label: l.moduleActiveSection,
                  value: stats.modules!.active,
                ),
                ChartSlice(
                  label: l.moduleBadgeDraft,
                  value: stats.modules!.draft,
                ),
              ],
            ),
          ),
          if (stats.modules!.byType.isNotEmpty)
            _Card(
              title: l.dashboardByType,
              child: RankedBars(
                slices: [
                  for (final t in stats.modules!.byType)
                    ChartSlice(label: _label(context, t), value: t.count),
                ],
              ),
            ),
        ]),
      ],

      if (stats.reports != null || stats.ratings != null) ...[
        const SizedBox(height: AppSpacing.xl),
        FadeSlideIn(
          child: SectionHeader(l.dashboardSectionWork, icon: AppIcons.tasks),
        ),
        _cards([
          if (stats.reports != null)
            _Card(
              title: l.dashboardReportsTrend,
              child: TrendChart(
                emptyLabel: l.dashboardReportsEmpty,
                labelForDay: _day,
                points: [
                  for (final d in stats.reports!.series)
                    TrendPoint(day: d.day, value: d.count),
                ],
              ),
            ),
          if (stats.ratings != null)
            _Card(
              title: l.dashboardRatingDistribution,
              trailing: stats.ratings!.average == null
                  ? null
                  : GlassBadge(
                      label:
                          '${l.dashboardAverage} '
                          '${stats.ratings!.average!.toStringAsFixed(2)}',
                      icon: AppIcons.rating,
                      dense: true,
                    ),
              child: StarBars(counts: stats.ratings!.distribution),
            ),
        ]),
      ],

      if (stats.centralReports != null) ...[
        const SizedBox(height: AppSpacing.xl),
        FadeSlideIn(
          child: SectionHeader(
            l.dashboardSectionCentralReports,
            icon: AppIcons.reports,
          ),
        ),
        AdaptiveGrid(
          minTileWidth: 200,
          maxColumns: 4,
          children: staggered([
            StatTile(
              label: l.dashboardCentralPublished,
              value: '${stats.centralReports!.published}',
              icon: AppIcons.reports,
              color: Accent.green.of(context),
            ),
            // Alarm colour only while there is actually something unfinished,
            // same rule as the unstaffed-files tile.
            StatTile(
              label: l.dashboardCentralDrafts,
              value: '${stats.centralReports!.drafts}',
              icon: AppIcons.documentEmpty,
              color: stats.centralReports!.drafts > 0
                  ? Accent.goldSoft.of(context)
                  : Accent.greenDark.of(context),
            ),
            StatTile(
              label: l.dashboardCentralGeneral,
              value: '${stats.centralReports!.general}',
              icon: AppIcons.file,
              color: Accent.greenDeep.of(context),
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        _cards([
          _Card(
            title: l.dashboardCentralSplit,
            child: SplitBar(
              slices: [
                ChartSlice(
                  label: l.dashboardCentralPublished,
                  value: stats.centralReports!.published,
                ),
                ChartSlice(
                  label: l.dashboardCentralDrafts,
                  value: stats.centralReports!.drafts,
                ),
              ],
            ),
          ),
          if (stats.centralReports!.byType.isNotEmpty)
            _Card(
              title: l.dashboardCentralByType,
              child: RankedBars(
                slices: [
                  for (final t in stats.centralReports!.byType)
                    ChartSlice(label: _label(context, t), value: t.count),
                ],
              ),
            ),
        ]),
      ],

      if (stats.notifications != null) ...[
        const SizedBox(height: AppSpacing.xl),
        FadeSlideIn(
          child: SectionHeader(
            l.dashboardSectionNotifications,
            icon: AppIcons.notifications,
          ),
        ),
        AdaptiveGrid(
          minTileWidth: 200,
          maxColumns: 4,
          children: staggered([
            StatTile(
              label: l.dashboardNotifMessages30,
              value: '${stats.notifications!.messages}',
              icon: AppIcons.send,
              color: Accent.green.of(context),
              caption: l.dashboardNotifAllTime(
                stats.notifications!.totalMessages,
              ),
            ),
            StatTile(
              label: l.dashboardNotifRecipients,
              value: '${stats.notifications!.recipients}',
              icon: AppIcons.participants,
              color: Accent.greenDeep.of(context),
            ),
            if (stats.notifications!.readShare != null)
              StatTile(
                label: l.dashboardNotifReadShare,
                value:
                    '${(stats.notifications!.readShare! * 100).round()}%',
                icon: AppIcons.view,
                color: Accent.gold.of(context),
              ),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        _cards([
          _Card(
            title: l.dashboardNotifTrend,
            child: TrendChart(
              emptyLabel: l.dashboardNotifTrendEmpty,
              labelForDay: _day,
              points: [
                for (final d in stats.notifications!.series)
                  TrendPoint(day: d.day, value: d.count),
              ],
            ),
          ),
        ]),
      ],

      if (stats.reference != null) ...[
        const SizedBox(height: AppSpacing.xl),
        FadeSlideIn(
          child: SectionHeader(
            l.dashboardSectionReference,
            icon: AppIcons.referenceData,
          ),
        ),
        AdaptiveGrid(
          minTileWidth: 200,
          maxColumns: 4,
          children: staggered([
            StatTile(
              label: l.dashboardRefSets,
              value: '${stats.reference!.sets}',
              icon: AppIcons.referenceData,
              color: Accent.greenDeep.of(context),
            ),
            StatTile(
              label: l.dashboardRefItems,
              value: '${stats.reference!.items}',
              icon: AppIcons.document,
              color: Accent.green.of(context),
              caption: '${l.dashboardRefActive}: ${stats.reference!.active}',
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        _cards([
          _Card(
            title: l.dashboardRefSeasonSplit,
            child: SplitBar(
              slices: [
                ChartSlice(
                  label: l.dashboardRefSeasonItems,
                  value: stats.reference!.seasonItems,
                ),
                ChartSlice(
                  label: l.dashboardRefGeneralItems,
                  value: stats.reference!.generalItems,
                ),
              ],
            ),
          ),
          if (stats.reference!.bySet.isNotEmpty)
            _Card(
              title: l.dashboardRefBySet,
              child: RankedBars(
                slices: [
                  for (final s in stats.reference!.bySet)
                    ChartSlice(label: _label(context, s), value: s.count),
                ],
              ),
            ),
        ]),
      ],

      if (stats.permissions != null) ...[
        const SizedBox(height: AppSpacing.xl),
        FadeSlideIn(
          child: SectionHeader(
            l.dashboardSectionPermissions,
            icon: AppIcons.permissions,
          ),
        ),
        AdaptiveGrid(
          minTileWidth: 200,
          maxColumns: 4,
          children: staggered([
            StatTile(
              label: l.dashboardPermAdmins,
              value: '${stats.permissions!.admins}',
              icon: AppIcons.permissions,
              color: Accent.gold.of(context),
            ),
            StatTile(
              label: l.dashboardPermGrantees,
              value: '${stats.permissions!.grantees}',
              icon: AppIcons.participants,
              color: Accent.green.of(context),
            ),
            StatTile(
              label: l.dashboardPermGrants,
              value: '${stats.permissions!.grants}',
              icon: AppIcons.selected,
              color: Accent.greenDeep.of(context),
            ),
          ]),
        ),
        if (stats.permissions!.bySection.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _cards([
            _Card(
              title: l.dashboardPermBySection,
              child: RankedBars(
                slices: [
                  for (final s in stats.permissions!.bySection)
                    ChartSlice(
                      label: permissionLabel(l, s.key),
                      value: s.count,
                    ),
                ],
              ),
            ),
          ]),
        ],
      ],

      if (stats.approvals != null) ...[
        const SizedBox(height: AppSpacing.xl),
        FadeSlideIn(
          child: SectionHeader(
            l.dashboardSectionQueue,
            icon: AppIcons.approvals,
          ),
        ),
        // Four states, which is one more than colour can carry — so this is a
        // ranked list in one hue, with the name at the start of each row.
        _cards([
          _Card(
            title: l.dashboardSectionQueue,
            child: RankedBars(
              slices: [
                ChartSlice(
                  label: l.dashboardPending,
                  value: stats.approvals!.pending,
                ),
                ChartSlice(
                  label: l.dashboardApproved,
                  value: stats.approvals!.approved,
                ),
                ChartSlice(
                  label: l.dashboardIncomplete,
                  value: stats.approvals!.incomplete,
                ),
                ChartSlice(
                  label: l.dashboardRejected,
                  value: stats.approvals!.rejected,
                ),
              ],
            ),
          ),
        ]),
      ],
    ];
  }

  List<Widget> _headline(
    BuildContext context,
    AppLocalizations l,
    DashboardStats stats,
  ) {
    return [
      if (stats.people != null)
        StatTile(
          label: l.dashboardParticipants,
          value: '${stats.people!.participants}',
          icon: AppIcons.participants,
          color: Accent.green.of(context),
          caption: l.dashboardWithdrawnCaption(stats.people!.withdrawn),
        ),
      if (stats.modules != null)
        StatTile(
          label: l.dashboardFiles,
          value: '${stats.modules!.total}',
          icon: AppIcons.modules,
          color: Accent.greenDeep.of(context),
          caption: l.dashboardFilesCaption(
            stats.modules!.active,
            stats.modules!.draft,
          ),
        ),
      if (stats.reports != null)
        StatTile(
          label: l.dashboardReports,
          value: '${stats.reports!.total}',
          icon: AppIcons.trend,
          color: Accent.gold.of(context),
          caption: l.dashboardReportsCaption(stats.reports!.authors),
        ),
      if (stats.ratings != null)
        StatTile(
          label: l.dashboardRatings,
          value: '${stats.ratings!.count}',
          icon: AppIcons.rating,
          color: Accent.goldSoft.of(context),
          caption: l.dashboardRatedPeople(stats.ratings!.ratedPeople),
        ),
      if (stats.approvals != null)
        StatTile(
          label: l.dashboardPending,
          value: '${stats.approvals!.pending}',
          icon: AppIcons.approvals,
          color: stats.approvals!.pending > 0
              ? Accent.red.of(context)
              : Accent.greenDark.of(context),
        ),
    ];
  }

  /// Chart panes never share a height: a five-row ranked list and a thirty-day
  /// trend are honestly different sizes, and forcing them level would print
  /// dead glass under the shorter one. (It would also crash — a pane holding a
  /// [LayoutBuilder] cannot be asked for an intrinsic height. See
  /// [GridCellWidth].)
  Widget _cards(List<Widget> cards) => AdaptiveGrid(
    minTileWidth: 340,
    maxColumns: 3,
    equalHeights: false,
    children: staggered(cards.whereType<Widget>().toList()),
  );

  String _label(BuildContext context, CountedLabel c) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final en = c.labelEn;
    return english && en != null && en.isNotEmpty ? en : c.labelAr;
  }

  String _gender(AppLocalizations l, String key) => switch (key) {
    'male' => l.genderMale,
    'female' => l.genderFemale,
    _ => l.dashboardUnknown,
  };

  static String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Which season everything on the page is counted over.
///
/// Held to the width of a year and put at the start edge: it is a filter, not a
/// heading, and a dropdown the width of a monitor asks for something much
/// longer than "1447 هـ".
class _SeasonFilter extends StatelessWidget {
  const _SeasonFilter({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: DropdownButtonFormField<String>(
          initialValue: state.selectedSeasonId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l.dashboardSeason,
            prefixIcon: const Icon(AppIcons.seasons),
            isDense: true,
          ),
          items: [
            for (final s in state.seasons)
              DropdownMenuItem(
                value: s.id,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        l.seasonHijriYear(s.hijriYear),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (s.isCurrent) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(AppIcons.current, size: 14, color: scheme.secondary),
                    ],
                  ],
                ),
              ),
          ],
          onChanged: (v) =>
              v == null ? null : context.read<DashboardCubit>().selectSeason(v),
        ),
      ),
    );
  }
}

/// A titled pane around one chart. The title names the series, which is what
/// lets a single-series chart go without a legend.
class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}
