import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/animations/animations.dart';
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

/// One report in full: what it states, its table, the paper it came from.
class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        ReportDetailCubit(ReportsRepository(), ModulesRepository(), reportId),
    child: const _View(),
  );
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return BlocBuilder<ReportDetailCubit, ReportDetailState>(
      builder: (context, state) {
        final report = state.report;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: GlassAppBar(title: Text(report?.title ?? l.navReports)),
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
    final plain = fields.where((f) => !_isOwnCard(f.kind)).toList();
    final own = fields.where((f) => _isOwnCard(f.kind)).toList();

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

            // The table. Horizontally scrollable in its own right: توزيع
            // الوجبات is seventeen columns wide and the page must not be.
            if ((type?.hasTable ?? false) && report.rows.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _TableCard(state: state, report: report),
            ],

            for (final f in own)
              if ((report.data[f.key]?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _FieldCard(
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

/// Kinds that are something to act on rather than something to read.
bool _isOwnCard(ModuleFieldKind kind) =>
    kind == ModuleFieldKind.url ||
    kind == ModuleFieldKind.qr ||
    kind == ModuleFieldKind.pdf ||
    kind == ModuleFieldKind.location;

/// A link to follow, or a code to hold up.
class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.label,
    required this.value,
    required this.kind,
  });

  final String label;
  final String value;
  final ModuleFieldKind kind;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (kind == ModuleFieldKind.qr) {
      return GlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text(label, style: text.titleSmall),
            const SizedBox(height: AppSpacing.md),
            // On white, always. A QR is read by a camera looking for dark
            // modules on a light field, and rendering it on the dark theme's
            // surface makes it slower to scan or impossible.
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: QrImageView(
                data: value,
                size: 180,
                backgroundColor: Colors.white,
                // Fails to a message rather than to a red X nobody can read.
                errorStateBuilder: (context, _) => SizedBox(
                  width: 180,
                  height: 180,
                  child: Center(
                    child: Text(
                      context.l10n.reportQrFailed,
                      textAlign: TextAlign.center,
                      style: text.bodySmall,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final uri = Uri.tryParse(value);
    return GlassCard(
      onTap: uri == null
          ? null
          : () => launchUrl(uri, mode: LaunchMode.externalApplication),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(
            kind == ModuleFieldKind.pdf ? AppIcons.pdf : AppIcons.link,
            color: scheme.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.titleSmall),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const NavChevron(),
        ],
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
              final raw = row.value(c.key);
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
