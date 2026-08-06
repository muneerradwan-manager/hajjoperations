import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/glass_tokens.dart';
import '../../../../core/widgets/glass.dart';
import '../../application/report_editor_cubit.dart';
import '../../domain/report_block.dart';
import 'tag_list_field.dart';

/// Writing a general report.
///
/// A typed report is FILLED IN — its type declares the columns and the form
/// asks for them. This one is written, so the form's job is to make plain what
/// it can be made of: a heading, prose, a numbered list, a table, a link, a code
/// to scan. The row of "add" buttons is that statement — somebody who does not
/// know a report may carry a QR code finds out by looking at the form, which is
/// the only place they were ever going to look.
class ReportBlocksEditor extends StatelessWidget {
  const ReportBlocksEditor({
    super.key,
    required this.state,
    required this.cubit,
  });

  final ReportEditorState state;
  final ReportEditorCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.reportContentSection,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l.reportContentHint,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Every kind, always offered. A menu that hides the rare ones behind
        // "more" is a menu that decides for the writer what their notice needs.
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (final kind in ReportBlockKind.values)
              ActionChip(
                avatar: Icon(_iconFor(kind), size: 16),
                label: Text(_labelFor(context, kind)),
                visualDensity: VisualDensity.compact,
                onPressed: () => cubit.addBlock(kind),
              ),
          ],
        ),
        if (state.blocks.isEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(l.reportNoBlocks),
          ),
        ],
        for (var i = 0; i < state.blocks.length; i++) ...[
          const SizedBox(height: AppSpacing.sm),
          _BlockCard(
            key: ValueKey('block_$i'),
            index: i,
            block: state.blocks[i],
            total: state.blocks.length,
            cubit: cubit,
          ),
        ],
      ],
    );
  }
}

IconData _iconFor(ReportBlockKind kind) => switch (kind) {
  ReportBlockKind.heading => AppIcons.document,
  ReportBlockKind.subheading => AppIcons.document,
  ReportBlockKind.paragraph => AppIcons.file,
  ReportBlockKind.bullets => AppIcons.tasks,
  ReportBlockKind.numbers => AppIcons.tasks,
  ReportBlockKind.table => AppIcons.referenceData,
  ReportBlockKind.url => AppIcons.link,
  ReportBlockKind.qr => AppIcons.view,
  ReportBlockKind.note => AppIcons.pending,
  ReportBlockKind.divider => AppIcons.modules,
};

String _labelFor(BuildContext context, ReportBlockKind kind) {
  final l = context.l10n;
  return switch (kind) {
    ReportBlockKind.heading => l.blockHeading,
    ReportBlockKind.subheading => l.blockSubheading,
    ReportBlockKind.paragraph => l.blockParagraph,
    ReportBlockKind.bullets => l.blockBullets,
    ReportBlockKind.numbers => l.blockNumbers,
    ReportBlockKind.table => l.blockTable,
    ReportBlockKind.url => l.blockUrl,
    ReportBlockKind.qr => l.blockQr,
    ReportBlockKind.note => l.blockNote,
    ReportBlockKind.divider => l.blockDivider,
  };
}

/// One block, with the fields its kind needs and the means to move it.
class _BlockCard extends StatelessWidget {
  const _BlockCard({
    super.key,
    required this.index,
    required this.block,
    required this.total,
    required this.cubit,
  });

  final int index;
  final DraftBlock block;
  final int total;
  final ReportEditorCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(_iconFor(block.kind), size: 18, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _labelFor(context, block.kind),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              // The order is what gets rewritten most, so it is two taps and
              // not a drag: a drag inside a scrolling form fights the scroll.
              IconButton(
                tooltip: l.blockMoveUp,
                visualDensity: VisualDensity.compact,
                onPressed: index == 0 ? null : () => cubit.moveBlock(index, -1),
                icon: const Icon(Icons.keyboard_arrow_up, size: 20),
              ),
              IconButton(
                tooltip: l.blockMoveDown,
                visualDensity: VisualDensity.compact,
                onPressed: index == total - 1
                    ? null
                    : () => cubit.moveBlock(index, 1),
                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              ),
              IconButton(
                tooltip: l.commonDelete,
                visualDensity: VisualDensity.compact,
                onPressed: () => cubit.removeBlock(index),
                icon: Icon(AppIcons.delete, size: 18, color: scheme.error),
              ),
            ],
          ),
          ..._fields(context),
        ],
      ),
    );
  }

  /// One row's inputs, across the EFFECTIVE columns.
  ///
  /// The generated columns are resolved through the cubit's own expansion —
  /// the same resolution the reader uses — so the editor and the page agree
  /// about which heading a cell sits under. A generated column's field is
  /// labelled with its entry's name (تكتل الكعبة, not "عمود ١٦") and keyed by
  /// the entry's id, so a season gaining a cluster does not strand a
  /// controller's text under the wrong heading.
  List<Widget> _rowFields(BuildContext context, int r) {
    final block = this.block;
    final expansion = cubit.state.expansionOf(block);
    final at = block.expandAt ?? block.columns.length;

    // (label, stable key part) per effective column, typed and generated
    // spliced exactly as the rows store them.
    final headings = <({String label, String key})>[
      for (var c = 0; c < at; c++)
        (label: block.columns[c], key: 'c$c'),
      for (final item in expansion)
        (label: item.name.of(context), key: item.id),
      for (var c = at; c < block.columns.length; c++)
        (label: block.columns[c], key: 'c$c'),
    ];

    return [
      for (var e = 0; e < headings.length; e++) ...[
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          key: ValueKey('b${index}_r${r}_${headings[e].key}'),
          initialValue: e < block.rows[r].length ? block.rows[r][e] : '',
          decoration: InputDecoration(
            isDense: true,
            labelText: headings[e].label,
          ),
          onChanged: (v) => cubit.setBlockCell(index, r, e, v),
        ),
      ],
    ];
  }

  List<Widget> _fields(BuildContext context) {
    final l = context.l10n;

    switch (block.kind) {
      // Nothing to fill in: a rule is a rule.
      case ReportBlockKind.divider:
        return const [];

      case ReportBlockKind.heading:
      case ReportBlockKind.subheading:
      case ReportBlockKind.paragraph:
      case ReportBlockKind.note:
        final long =
            block.kind == ReportBlockKind.paragraph ||
            block.kind == ReportBlockKind.note;
        return [
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: block.text,
            maxLines: long ? 5 : 1,
            decoration: InputDecoration(
              isDense: true,
              labelText: long ? l.blockTextLong : l.blockTextShort,
            ),
            onChanged: (v) => cubit.setBlockValue(index, 'text', v),
          ),
        ];

      case ReportBlockKind.bullets:
      case ReportBlockKind.numbers:
        return [
          const SizedBox(height: AppSpacing.sm),
          TagListField(
            label: l.blockItems,
            items: block.items,
            hint: l.blockAddItem,
            onChanged: (v) => cubit.setBlockValue(index, 'items', v),
          ),
        ];

      case ReportBlockKind.url:
        return [
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: block.data['url']?.toString() ?? '',
            keyboardType: TextInputType.url,
            decoration: InputDecoration(isDense: true, labelText: l.blockUrl),
            onChanged: (v) => cubit.setBlockValue(index, 'url', v),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: block.data['label']?.toString() ?? '',
            decoration: InputDecoration(
              isDense: true,
              labelText: l.blockLabel,
              helperText: l.commonOptional,
            ),
            onChanged: (v) => cubit.setBlockValue(index, 'label', v),
          ),
        ];

      case ReportBlockKind.qr:
        return [
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: block.data['value']?.toString() ?? '',
            decoration: InputDecoration(
              isDense: true,
              labelText: l.blockQrValue,
              helperText: l.blockQrHint,
            ),
            onChanged: (v) => cubit.setBlockValue(index, 'value', v),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: block.data['label']?.toString() ?? '',
            decoration: InputDecoration(
              isDense: true,
              labelText: l.blockLabel,
              helperText: l.commonOptional,
            ),
            onChanged: (v) => cubit.setBlockValue(index, 'label', v),
          ),
        ];

      case ReportBlockKind.table:
        return [
          const SizedBox(height: AppSpacing.sm),
          // The columns first, and as tags: a table is not a table until it
          // knows what its columns are, and naming them is a list of short
          // things like any other.
          TagListField(
            label: l.blockTableColumns,
            items: block.columns,
            hint: l.blockAddColumn,
            onChanged: (v) => cubit.setBlockColumns(index, v),
          ),
          // Which of them print a repeated value once against the rows it
          // covers — the date beside its three meals rather than three times.
          // Only the typed columns are offered: a generated one holds a count
          // per تكتل, and two clusters with the same number are a coincidence,
          // not a merged cell.
          if (block.columns.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.blockTableSpans,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (var c = 0; c < block.columns.length; c++)
                  FilterChip(
                    label: Text(block.columns[c]),
                    selected: block.spansAt(c),
                    onSelected: (_) => cubit.toggleBlockSpan(index, c),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // A column of items rather than a sentence. مكونات الوجبات is nine
            // per meal, and nine lines down a column makes the row nine lines
            // tall with the rest of the table sitting in a stripe of white.
            // Told rather than guessed: a paragraph in a table has newlines in
            // it too and is not a list.
            Text(
              l.blockTableTags,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (var c = 0; c < block.columns.length; c++)
                  FilterChip(
                    label: Text(block.columns[c]),
                    selected: block.tagsAt(c),
                    onSelected: (_) => cubit.toggleBlockTags(index, c),
                  ),
              ],
            ),
          ],
          // And the list whose entries become one column each. THIS is what a
          // hand-typed table could never do, and the reason توزيع الوجبات
          // needed a report type of its own until 0102: a column per تكتل that
          // appears the day a تكتل is added, rather than a heading somebody
          // typed that goes stale silently.
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String?>(
            initialValue: block.expandSetCode,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              labelText: l.blockTableExpand,
              helperText: l.blockTableExpandHint,
            ),
            items: [
              DropdownMenuItem(value: null, child: Text(l.blockTableExpandNone)),
              for (final set in cubit.state.referenceSets)
                DropdownMenuItem(
                  value: set.code,
                  child: Text(set.name.of(context)),
                ),
            ],
            onChanged: (v) => cubit.setBlockExpand(index, v),
          ),
          if (block.columns.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                l.blockTableNeedsColumns,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else ...[
            for (var r = 0; r < block.rows.length; r++) ...[
              const SizedBox(height: AppSpacing.sm),
              // One field per column, labelled with that column. Typed as a
              // single line with separators it was impossible to tell which
              // cell you were in, and one missing separator shifted the rest.
              GlassCard(
                subtle: true,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.reportRowNumber(r + 1),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        IconButton(
                          tooltip: l.commonDelete,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => cubit.removeBlockRow(index, r),
                          icon: Icon(
                            AppIcons.delete,
                            size: 16,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    // Every column the table HAS — the typed ones AND the ones
                    // its expansion generates, each labelled by the entry it
                    // stands for and addressed at its EFFECTIVE index.
                    //
                    // Both halves of that sentence fix a live corruption. The
                    // loop used to cover the typed columns only, so a
                    // distribution table's thirteen cluster cells were never
                    // rendered and could not be edited at all. And it handed
                    // `setBlockCell` its typed loop index while the rows store
                    // effective positions — so the field labelled المجموع read
                    // and OVERWROTE the first تكتل's count, in both directions,
                    // silently.
                    ..._rowFields(context, r),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => cubit.addBlockRow(index),
                icon: const Icon(AppIcons.add, size: 18),
                label: Text(l.reportAddRow),
              ),
            ),
          ],
        ];
    }
  }
}
