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
            ReportDetailStatus.loading => const SkeletonList(
              maxColumns: 1,
              height: 180,
              count: 3,
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

/// The report's table.
///
/// A column declared over a master-data list has already been expanded into one
/// column per entry by the cubit, so this draws whatever it is handed.
class _TableCard extends StatelessWidget {
  const _TableCard({required this.state, required this.report});

  final ReportDetailState state;
  final Report report;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final columns = state.drawnColumns;
    if (columns.isEmpty) return const SizedBox.shrink();

    // A blank cell in a spanning column means "same as above" — the date of
    // every one of these documents is written once and read down. Resolved
    // here so the reader of a filtered or a scrolled table still sees it.
    final carried = <String, String>{};

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 44,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 96,
          columnSpacing: AppSpacing.lg,
          headingTextStyle: text.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          columns: [
            for (final c in columns) DataColumn(label: Text(c.label(context))),
          ],
          rows: [
            for (final row in report.rows)
              DataRow(
                cells: [
                  for (final c in columns)
                    DataCell(
                      Text(
                        () {
                          final raw = row.value(c.key);
                          if (!c.column.spansRows) return raw;
                          if (raw.isNotEmpty) {
                            carried[c.key] = raw;
                            return raw;
                          }
                          return carried[c.key] ?? '';
                        }(),
                        style: text.bodySmall,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
