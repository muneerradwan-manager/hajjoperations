import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/glass_tokens.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../modules/domain/module_type.dart';
import '../../domain/report_block.dart';
import 'report_field_card.dart';

/// One block of a written report, drawn as what it is.
///
/// Deliberately NOT all wrapped in cards. A notice reads as a document — its
/// headings sit on the page and its paragraphs run under them — and putting
/// every line in glass turns a page of prose into a stack of tiles. Only the
/// things that are OBJECTS rather than text get a card: a table, a link, a
/// code, and a note, which is set apart because being set apart is what makes
/// it a note.
class ReportBlockView extends StatelessWidget {
  const ReportBlockView({super.key, required this.block});

  final ReportBlock block;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    switch (block.kind) {
      case ReportBlockKind.heading:
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(block.text, style: text.titleLarge),
        );

      case ReportBlockKind.subheading:
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            block.text,
            style: text.titleSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        );

      case ReportBlockKind.paragraph:
        return Align(
          alignment: AlignmentDirectional.centerStart,
          // Prose, so it gets prose's line height rather than a label's.
          child: Text(block.text, style: text.bodyLarge?.copyWith(height: 1.6)),
        );

      case ReportBlockKind.note:
        return GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          tint: scheme.secondary,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.pending, size: 18, color: scheme.secondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  block.text,
                  style: text.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        );

      case ReportBlockKind.bullets:
      case ReportBlockKind.numbers:
        final numbered = block.kind == ReportBlockKind.numbers;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < block.items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        numbered ? '${i + 1}.' : '•',
                        style: text.bodyLarge?.copyWith(color: scheme.primary),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        block.items[i],
                        style: text.bodyLarge?.copyWith(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );

      case ReportBlockKind.divider:
        return Divider(
          height: AppSpacing.lg,
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        );

      case ReportBlockKind.url:
        return ReportFieldCard(
          label: block.label.isEmpty ? block.url : block.label,
          value: block.url,
          kind: ModuleFieldKind.url,
        );

      case ReportBlockKind.qr:
        return ReportFieldCard(
          label: block.label.isEmpty
              ? context.l10n.reportScanCode
              : block.label,
          value: block.value,
          kind: ModuleFieldKind.qr,
        );

      case ReportBlockKind.table:
        return _WrittenTable(block: block);
    }
  }
}

/// A table a notice carries its own columns for.
///
/// Same choice the typed table makes and for the same reason: a wide grid on a
/// phone is a sideways scroll with the first column sliding out of sight, so
/// below a wide window each row becomes a card of labelled lines. The columns
/// here come from the BLOCK rather than from a type, which is the whole
/// difference between a written report and a typed one.
class _WrittenTable extends StatelessWidget {
  const _WrittenTable({required this.block});

  final ReportBlock block;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final columns = block.columns;
    final rows = block.rows;
    if (columns.isEmpty || rows.isEmpty) return const SizedBox.shrink();

    String cell(List<String> row, int i) => i < row.length ? row[i] : '';

    return WindowSizeBuilder(
      builder: (context, size) {
        // Asked of the data, not of the device: five columns fit anywhere,
        // twelve need a monitor.
        final roomy =
            size.isAtLeast(WindowSize.expanded) && columns.length <= 5 ||
            size.isAtLeast(WindowSize.large) && columns.length <= 9 ||
            size.isAtLeast(WindowSize.extraLarge);

        if (roomy) {
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
                columns: [for (final c in columns) DataColumn(label: Text(c))],
                rows: [
                  for (var i = 0; i < rows.length; i++)
                    DataRow(
                      // Striping rather than a line under every cell, which
                      // reads as graph paper.
                      color: WidgetStatePropertyAll(
                        i.isOdd
                            ? scheme.onSurface.withValues(alpha: 0.03)
                            : Colors.transparent,
                      ),
                      cells: [
                        for (var j = 0; j < columns.length; j++)
                          DataCell(
                            Text(cell(rows[i], j), style: text.bodySmall),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var j = 0; j < columns.length; j++)
                      if (cell(rows[i], j).isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: j == columns.length - 1 ? 0 : AppSpacing.sm,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 104,
                                child: Text(
                                  columns[j],
                                  style: text.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  cell(rows[i], j),
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
      },
    );
  }
}
