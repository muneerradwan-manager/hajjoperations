import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/glass_tokens.dart';
import '../../../../core/widgets/glass.dart';
import '../../../modules/domain/module_type.dart';
import '../../domain/report_block.dart';
import 'report_field_card.dart';
import 'report_table.dart';

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
/// The columns come from the BLOCK rather than from a type, which is the whole
/// difference between a written report and a typed one. Everything after that —
/// whether there is room for a grid, and what to do when there is not — is the
/// same question [ReportTable] answers for both.
class _WrittenTable extends StatelessWidget {
  const _WrittenTable({required this.block});

  final ReportBlock block;

  @override
  Widget build(BuildContext context) =>
      ReportTable(columns: block.columns, rows: block.rows);
}
