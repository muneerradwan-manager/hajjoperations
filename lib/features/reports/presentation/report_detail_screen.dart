import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/constants/permission_codes.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/widgets/overflow_menu.dart';
import '../../auth/application/session_cubit.dart';
import '../../../core/attachments/attachments_view.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/info_section.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/states.dart';
import '../../modules/data/modules_repository.dart';
import '../../modules/domain/module_type.dart';
import '../application/report_detail_cubit.dart';
import '../data/reports_repository.dart';
import '../domain/report.dart';
import '../domain/report_type.dart';
import 'report_editor_screen.dart';
import 'widgets/report_block_view.dart';
import 'widgets/report_field_card.dart';

/// One report in full: what it states, its table, the paper it came from.
class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({
    super.key,
    required this.reportId,
    this.fromOffice = false,
  });

  final String reportId;

  /// Whether this was opened from إدارة التقارير rather than from عام.
  ///
  /// The same rule the operational file follows: holding the permission is what
  /// makes editing possible, and coming in through the office is what makes
  /// THIS page the place to do it. Reached from عام the report is something
  /// being read, and a delete button does not belong on it.
  final bool fromOffice;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        ReportDetailCubit(ReportsRepository(), ModulesRepository(), reportId),
    child: _View(fromOffice: fromOffice),
  );
}

class _View extends StatelessWidget {
  const _View({required this.fromOffice});

  final bool fromOffice;

  Future<void> _edit(BuildContext context, Report report) async {
    final cubit = context.read<ReportDetailCubit>();
    final saved = await Navigator.of(context).push<bool>(
      fadeThroughRoute((_) => ReportEditorScreen(existing: report)),
    );
    if (saved == true) await cubit.load();
  }

  Future<void> _delete(BuildContext context, Report report) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.commonDelete),
        content: Text(l.reportDeleteConfirm(report.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await supabase.from('reports').delete().eq('id', report.id);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.reportDeleted)));
      // Nothing left on this page to look at.
      navigator.pop(true);
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return BlocBuilder<ReportDetailCubit, ReportDetailState>(
      builder: (context, state) {
        final report = state.report;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: GlassAppBar(
            title: Text(report?.title ?? l.navReports),
            actions: [
              if (fromOffice &&
                  report != null &&
                  context.watch<SessionCubit>().state.can(
                    PermissionCodes.reportsManage,
                  ))
                OverflowMenu(
                  actions: [
                    MenuAction(
                      icon: AppIcons.edit,
                      label: l.commonEdit,
                      onSelected: () => _edit(context, report),
                    ),
                    MenuAction(
                      icon: AppIcons.delete,
                      label: l.commonDelete,
                      isDestructive: true,
                      onSelected: () => _delete(context, report),
                    ),
                  ],
                ),
            ],
          ),
          body: switch (state.status) {
            // Shaped like what is about to replace it: one column of tall
            // cards, at the page's own gutter. A skeleton that columns
            // differently from the screen it stands in for is a flash of a
            // layout that never arrives.
            ReportDetailStatus.loading => ResponsivePage(
              builder: (context, size) => SkeletonList(
                maxColumns: 1,
                minTileWidth: double.infinity,
                height: 200,
                count: 3,
                padding: context.scrollPadding(
                  horizontal: size.gutter,
                  bottom: AppSpacing.xl,
                ),
              ),
            ),
            ReportDetailStatus.missing => EmptyState(
              icon: AppIcons.reports,
              title: l.reportMissing,
            ),
            ReportDetailStatus.error => EmptyState(
              icon: AppIcons.reports,
              title: state.error ?? '',
            ),
            ReportDetailStatus.ready => _Body(state: state, report: report!),
          },
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.report});

  final ReportDetailState state;
  final Report report;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final type = state.type;
    final fields = type?.fields ?? const <ModuleField>[];

    // Read straight through, not read across: a location and a code and a
    // document are three different things to DO, and each gets its own card.
    final plain = fields.where((f) => !isActionableReportField(f.kind)).toList();
    final own = fields.where((f) => isActionableReportField(f.kind)).toList();

    return Builder(
      builder: (context) => ResponsivePage(
        builder: (context, size) => SinglePaneLayout(
          gutter: size.gutter,
          onRefresh: context.read<ReportDetailCubit>().load,
          children: staggered([
            InfoSection(
              title: l.reportAboutSection,
              icon: AppIcons.reports,
              children: [
                InfoRow(
                  icon: AppIcons.reports,
                  label: l.reportKind,
                  value: report.typeName?.of(context),
                ),
                if ((report.number ?? '').isNotEmpty)
                  InfoRow(
                    icon: AppIcons.document,
                    label: l.reportNumber,
                    value: report.number,
                  ),
                InfoRow(
                  icon: AppIcons.seasons,
                  label: l.reportScope,
                  // A general report is not "missing a season" — it is true in
                  // all of them, and says so.
                  value: report.isSeasonal
                      ? l.seasonHijriYear(report.seasonHijriYear ?? 0)
                      : l.reportsScopeGeneral,
                ),
                if (type?.description != null)
                  InfoRow(
                    icon: AppIcons.document,
                    label: l.reportAbout,
                    value: type!.description!.of(context),
                  ),
                for (final f in plain)
                  if ((report.data[f.key]?.toString() ?? '').isNotEmpty)
                    InfoRow(
                      icon: AppIcons.document,
                      label: f.label.of(context),
                      value: report.data[f.key].toString(),
                    ),
              ],
            ),

            // A written report's content, in the order it was written.
            if (report.isWritten)
              for (final block in report.blocks)
                if (!block.isEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  ReportBlockView(block: block),
                ],

            // A typed one's content is its table.
            if ((type?.hasTable ?? false) && report.rows.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _TableCard(state: state, report: report),
            ],

            for (final f in own)
              if ((report.data[f.key]?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                ReportFieldCard(
                  label: f.label.of(context),
                  value: report.data[f.key].toString(),
                  kind: f.kind,
                ),
              ],

            if (report.attachments.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.reportSource, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    AttachmentsView(
                      attachments: report.attachments,
                      signer: context.read<ReportDetailCubit>().signedUrl,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),
            Text(
              l.reportUpdated(formatDate(report.updatedAt)),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// The report's table, drawn the way the window can actually hold it.
///
/// A column declared over a master-data list has already been expanded into one
/// column per entry by the cubit, so this draws whatever it is handed — which
/// for توزيع الوجبات is seventeen columns.
///
/// Seventeen columns do not go on a phone. A grid that wide either scrolls
/// sideways with the row labels sliding out of sight, or squeezes every cell to
/// three characters; both are worse than not being a grid. So below a wide
/// window each ROW is drawn as its own card — the key columns as a heading, the
/// rest as label-and-value lines. Same data, read down instead of across, which
/// is the direction a phone actually scrolls.
class _TableCard extends StatelessWidget {
  const _TableCard({required this.state, required this.report});

  final ReportDetailState state;
  final Report report;

  /// Values resolved once, with a spanning column's blank cell filled from the
  /// row above it — the date of all three documents is written once and read
  /// down the page.
  List<Map<String, String>> _resolved(
    BuildContext context,
    List<({String key, String Function(dynamic) label, ReportColumn column})>
    columns,
  ) {
    final carried = <String, String>{};
    return [
      for (final row in report.rows)
        {
          for (final c in columns)
            c.key: () {
              // A reference cell holds an id; the reader wants the name. And a
              // name looked up in a set that no longer has it reads as blank
              // rather than as a uuid nobody can use.
              var raw = row.value(c.key);
              if (c.column.isChoice && raw.isNotEmpty) {
                raw =
                    state
                        .setById(c.column.referenceSetId)
                        ?.items
                        .where((i) => i.id == raw)
                        .firstOrNull
                        ?.name
                        .of(context) ??
                    '';
              }
              if (!c.column.spansRows) return raw;
              if (raw.isNotEmpty) {
                carried[c.key] = raw;
                return raw;
              }
              return carried[c.key] ?? '';
            }(),
        },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final columns = state.drawnColumns;
    if (columns.isEmpty) return const SizedBox.shrink();
    final rows = _resolved(context, columns);

    return WindowSizeBuilder(
      builder: (context, size) {
        // The threshold is the data's, not the device's: four columns fit
        // anywhere, seventeen need a monitor. Asked of the table rather than
        // assumed from a breakpoint.
        final roomy =
            size.isAtLeast(WindowSize.expanded) && columns.length <= 6 ||
            size.isAtLeast(WindowSize.large) && columns.length <= 10 ||
            size.isAtLeast(WindowSize.extraLarge);
        return roomy
            ? _Grid(columns: columns, rows: rows)
            : _Stacked(columns: columns, rows: rows);
      },
    );
  }
}

/// The wide arrangement: an actual table, striped so the eye keeps its row.
class _Grid extends StatelessWidget {
  const _Grid({required this.columns, required this.rows});

  final List<({String key, String Function(dynamic) label, ReportColumn column})>
  columns;
  final List<Map<String, String>> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 46,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 120,
          columnSpacing: AppSpacing.lg,
          horizontalMargin: AppSpacing.md,
          dividerThickness: 0.4,
          headingTextStyle: text.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
          columns: [
            for (final c in columns) DataColumn(label: Text(c.label(context))),
          ],
          rows: [
            for (var i = 0; i < rows.length; i++)
              DataRow(
                // Striping, not borders: a seventeen-column grid with a line
                // under every cell reads as graph paper.
                color: WidgetStatePropertyAll(
                  i.isOdd
                      ? scheme.onSurface.withValues(alpha: 0.03)
                      : Colors.transparent,
                ),
                cells: [
                  for (final c in columns)
                    DataCell(
                      Text(rows[i][c.key] ?? '', style: text.bodySmall),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// The narrow arrangement: one card per row, read downwards.
///
/// The first two columns become the card's heading — for all three meal
/// documents those are التاريخ and الوجبة, which is exactly how somebody names
/// the row out loud. Everything else is a labelled line, and an empty cell is
/// left out rather than printed as a blank.
class _Stacked extends StatelessWidget {
  const _Stacked({required this.columns, required this.rows});

  final List<({String key, String Function(dynamic) label, ReportColumn column})>
  columns;
  final List<Map<String, String>> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final heading = columns.take(2).toList();
    final rest = columns.skip(2).toList();

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final c in heading)
                      if ((rows[i][c.key] ?? '').isNotEmpty)
                        Text(
                          rows[i][c.key]!,
                          style: text.titleSmall?.copyWith(
                            color: c == heading.first
                                ? scheme.onSurface
                                : scheme.primary,
                          ),
                        ),
                  ],
                ),
                for (final c in rest)
                  if ((rows[i][c.key] ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 104,
                            child: Text(
                              c.label(context),
                              style: text.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              rows[i][c.key]!,
                              style: text.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
