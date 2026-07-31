import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/states.dart';
import '../../modules/data/modules_repository.dart';
import '../../modules/presentation/widgets/module_field_input.dart';
import '../../seasons/data/seasons_repository.dart';
import '../application/report_editor_cubit.dart';
import '../data/reports_repository.dart';
import '../domain/report.dart';
import '../domain/report_type.dart';
import 'widgets/report_blocks_editor.dart';

/// Entering a report, and correcting one.
///
/// Three things in order: what the report IS, what it says about itself, and
/// its table. The table's columns come from the type — including the ones drawn
/// from master data, so a count per تكتل is entered against the clusters this
/// season has rather than typed into a box.
class ReportEditorScreen extends StatelessWidget {
  const ReportEditorScreen({super.key, this.existing});

  final Report? existing;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ReportEditorCubit(
      ReportsRepository(),
      ModulesRepository(),
      SeasonsRepository(),
      existing: existing,
    ),
    child: _View(isNew: existing == null),
  );
}

class _View extends StatelessWidget {
  const _View({required this.isNew});
  final bool isNew;

  Future<void> _save(BuildContext context) async {
    final l = context.l10n;
    final cubit = context.read<ReportEditorCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final id = await cubit.save();
    if (id == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(cubit.state.error ?? l.commonRequired)),
        );
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.reportSaved)));
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return BlocBuilder<ReportEditorCubit, ReportEditorState>(
      builder: (context, state) {
        final cubit = context.read<ReportEditorCubit>();

        return Scaffold(
          appBar: GlassAppBar(
            title: Text(isNew ? l.reportNew : l.reportEdit),
          ),
          bottomNavigationBar: GlassSurface(
            radius: 0,
            strong: true,
            shadow: false,
            bordered: false,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: FilledButton(
                  onPressed: state.canSave && state.status != EditorStatus.saving
                      ? () => _save(context)
                      : null,
                  child: state.status == EditorStatus.saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : Text(l.commonSave),
                ),
              ),
            ),
          ),
          body: switch (state.status) {
            EditorStatus.loading => ResponsivePage(
              builder: (context, size) => SkeletonList(
                maxColumns: 1,
                minTileWidth: double.infinity,
                height: 180,
                count: 3,
                padding: context.scrollPadding(
                  horizontal: size.gutter,
                  bottom: AppSpacing.xl,
                ),
              ),
            ),
            EditorStatus.error => EmptyState(
              icon: AppIcons.reports,
              title: state.error ?? '',
            ),
            _ => ResponsivePage(
              builder: (context, size) => SinglePaneLayout(
                gutter: size.gutter,
                children: [
                  _Identity(state: state, cubit: cubit, isNew: isNew),
                  if (state.type case final t?) ...[
                    if (t.fields.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _Fields(state: state, cubit: cubit),
                    ],
                    // A type with a table is FILLED IN; one without is
                    // WRITTEN. Never both, and the form says which by showing
                    // one of the two.
                    if (t.hasTable) ...[
                      const SizedBox(height: AppSpacing.md),
                      _Table(state: state, cubit: cubit),
                    ] else ...[
                      const SizedBox(height: AppSpacing.md),
                      ReportBlocksEditor(state: state, cubit: cubit),
                    ],
                  ],
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          },
        );
      },
    );
  }
}

/// What the report is: its kind, its name, and whether it belongs to a season.
class _Identity extends StatefulWidget {
  const _Identity({
    required this.state,
    required this.cubit,
    required this.isNew,
  });

  final ReportEditorState state;
  final ReportEditorCubit cubit;
  final bool isNew;

  @override
  State<_Identity> createState() => _IdentityState();
}

class _IdentityState extends State<_Identity> {
  late final _title = TextEditingController(text: widget.state.title);
  late final _number = TextEditingController(text: widget.state.number);

  @override
  void dispose() {
    _title.dispose();
    _number.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = widget.state;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.reportIdentity, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: s.typeId,
            isExpanded: true,
            decoration: InputDecoration(labelText: '${l.reportKind} *'),
            items: [
              for (final t in s.types)
                DropdownMenuItem(
                  value: t.id,
                  child: Text(t.name.of(context)),
                ),
            ],
            // Changing the kind empties the table: its columns are the type's,
            // and rows keyed to the old ones would be values with no column to
            // stand under.
            onChanged: widget.isNew ? widget.cubit.setType : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _title,
            onChanged: widget.cubit.setTitle,
            decoration: InputDecoration(labelText: '${l.reportTitle} *'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _number,
            onChanged: widget.cubit.setNumber,
            decoration: InputDecoration(
              labelText: l.reportNumber,
              helperText: l.commonOptional,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String?>(
            initialValue: s.seasonId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l.reportScope,
              helperText: l.reportScopeHint,
            ),
            items: [
              // General first, and it is what a new report starts on.
              DropdownMenuItem(value: null, child: Text(l.reportsScopeGeneral)),
              for (final season in s.seasons)
                DropdownMenuItem(
                  value: season.id,
                  child: Text(l.seasonHijriYear(season.hijriYear)),
                ),
            ],
            onChanged: widget.cubit.setSeason,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(AppIcons.activate),
            title: Text(l.reportPublished),
            subtitle: Text(l.reportPublishedHint),
            value: s.isPublished,
            onChanged: widget.cubit.setPublished,
          ),
        ],
      ),
    );
  }
}

/// The header fields the type declares — notes, a link, a code, the document.
class _Fields extends StatelessWidget {
  const _Fields({required this.state, required this.cubit});

  final ReportEditorState state;
  final ReportEditorCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.reportAboutSection, style: Theme.of(context).textTheme.titleSmall),
          for (final f in state.type!.fields) ...[
            const SizedBox(height: AppSpacing.md),
            ModuleFieldInput(
              field: f,
              value: state.data[f.key],
              referenceSet: state.setById(f.referenceSetId),
              onChanged: (v) => cubit.setField(f.key, v),
            ),
          ],
        ],
      ),
    );
  }
}

/// The table, entered row by row.
///
/// One card per row rather than a grid of inputs: توزيع الوجبات asks for
/// seventeen values, and seventeen boxes in a line is a form nobody can fill on
/// a phone. Each row is a card of labelled fields — the same shape the reader
/// gets on a narrow window, which is not a coincidence.
class _Table extends StatelessWidget {
  const _Table({required this.state, required this.cubit});

  final ReportEditorState state;
  final ReportEditorCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final columns = state.columns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.reportRowsSection(state.rows.length),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            TextButton.icon(
              onPressed: cubit.addRow,
              icon: const Icon(AppIcons.add, size: 18),
              label: Text(l.reportAddRow),
            ),
          ],
        ),
        if (state.rows.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(l.reportNoRows),
          ),
        for (var i = 0; i < state.rows.length; i++) ...[
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.reportRowNumber(i + 1),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: l.commonDelete,
                      icon: Icon(
                        AppIcons.delete,
                        size: 18,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => cubit.removeRow(i),
                    ),
                  ],
                ),
                for (final c in columns) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _Cell(
                    // Keyed by row AND column: adding or removing a row must
                    // not leave a field showing the value of the one it
                    // replaced.
                    key: ValueKey('${i}_${c.key}'),
                    row: i,
                    column: c,
                    state: state,
                    cubit: cubit,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// One cell of the table, asked for the way its column says.
///
/// Four shapes, and each exists because typing was wrong for it: a choice from
/// a list the Administration keeps, a span of clock times, a total that is
/// worked out, and — for everything else — a plain field.
class _Cell extends StatelessWidget {
  const _Cell({
    super.key,
    required this.row,
    required this.column,
    required this.state,
    required this.cubit,
  });

  final int row;
  final ({String key, String Function(dynamic) label, ReportColumn column})
  column;
  final ReportEditorState state;
  final ReportEditorCubit cubit;

  @override
  Widget build(BuildContext context) {
    final c = column.column;
    final label = column.label(context);
    final value = state.rows[row].value(column.key);

    // Worked out, and shown so the enterer can see it move as they type the
    // numbers it is a total of. Read-only rather than absent: a total nobody
    // can see is a total nobody checks.
    if (c.isComputed) {
      return InputDecorator(
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          suffixIcon: const Icon(AppIcons.tasks, size: 18),
        ),
        child: Text(
          '${cubit.computedFor(row, c)}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
      );
    }

    // A choice from real master data — the same list إدارة البيانات المرجعية
    // edits, so a day renamed there is renamed here.
    if (c.isChoice) {
      final set = state.setById(c.referenceSetId);
      final items = set?.itemsForSeason(state.seasonId) ?? const [];
      return DropdownButtonFormField<String>(
        initialValue: items.any((i) => i.id == value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(isDense: true, labelText: label),
        items: [
          for (final i in items)
            DropdownMenuItem(value: i.id, child: Text(i.name.of(context))),
        ],
        onChanged: (v) => cubit.setCell(row, column.key, v ?? ''),
      );
    }

    if (c.isTags) {
      return _TagsField(
        label: label,
        value: value,
        onChanged: (v) => cubit.setCell(row, column.key, v),
      );
    }

    if (c.isTimeRange) {
      return _TimeRangeField(
        label: label,
        value: value,
        onChanged: (v) => cubit.setCell(row, column.key, v),
      );
    }

    return TextFormField(
      initialValue: value,
      keyboardType: c.kind == ModuleFieldKind.number
          ? TextInputType.number
          : TextInputType.text,
      maxLines: c.kind == ModuleFieldKind.textarea ? 4 : 1,
      decoration: InputDecoration(isDense: true, labelText: label),
      onChanged: (v) => cubit.setCell(row, column.key, v),
    );
  }
}

/// From one clock time to another.
///
/// Stored as the sentence the documents use — 'من الساعة 13:00 إلى الساعة
/// 16:00' — rather than as two columns, because that is what the published
/// table says and the report is a copy of a published table. The picker is what
/// stops fourteen rows coming out fourteen ways.
class _TimeRangeField extends StatelessWidget {
  const _TimeRangeField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  static final _clock = RegExp(r'(\d{1,2}):(\d{2})');

  /// The two times already in the sentence, if it holds two.
  (TimeOfDay?, TimeOfDay?) get _parsed {
    final found = _clock.allMatches(value).toList();
    TimeOfDay? at(int i) => i < found.length
        ? TimeOfDay(
            hour: int.parse(found[i].group(1)!),
            minute: int.parse(found[i].group(2)!),
          )
        : null;
    return (at(0), at(1));
  }

  String _two(TimeOfDay t) =>
      '${t.hour}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(BuildContext context, bool isStart) async {
    final l = context.l10n;
    final (from, to) = _parsed;
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? from : to) ?? const TimeOfDay(hour: 13, minute: 0),
    );
    if (picked == null) return;
    final start = isStart ? picked : from;
    final end = isStart ? to : picked;
    if (start == null || end == null) {
      // Half a span is not a span, so it is held as the one time chosen and
      // completed on the next tap rather than written out as a broken sentence.
      onChanged(_two(picked));
      return;
    }
    onChanged(l.reportTimeRange(_two(start), _two(end)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (from, to) = _parsed;
    return InputDecorator(
      decoration: InputDecoration(isDense: true, labelText: label),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _pick(context, true),
              child: Text(from == null ? l.reportTimeFrom : _two(from)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _pick(context, false),
              child: Text(to == null ? l.reportTimeTo : _two(to)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A list of small things, added one at a time.
///
/// المكونات is خبز, زبدة, زيتون, شوربة عدس — a list, and a textarea makes it
/// one blob separated by whatever the typist happened to press. Stored one per
/// line, which is what the published document prints and what was seeded.
class _TagsField extends StatefulWidget {
  const _TagsField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_TagsField> createState() => _TagsFieldState();
}

class _TagsFieldState extends State<_TagsField> {
  final _entry = TextEditingController();

  List<String> get _tags => [
    for (final t in widget.value.split('\n'))
      if (t.trim().isNotEmpty) t.trim(),
  ];

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  void _add() {
    final v = _entry.text.trim();
    if (v.isEmpty) return;
    // Silently ignored rather than added twice: a meal does not contain خبز
    // twice, and a duplicate is a slip of the finger.
    if (_tags.contains(v)) {
      _entry.clear();
      return;
    }
    widget.onChanged([..._tags, v].join('\n'));
    _entry.clear();
  }

  void _remove(String tag) =>
      widget.onChanged(_tags.where((t) => t != tag).join('\n'));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return InputDecorator(
      decoration: InputDecoration(labelText: widget.label),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final tag in _tags)
                    InputChip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                      onDeleted: () => _remove(tag),
                    ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _entry,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: l.reportAddTag,
                  ),
                  // Enter adds it, which is how a list of nine gets typed
                  // without reaching for the button nine times.
                  onSubmitted: (_) => _add(),
                ),
              ),
              IconButton(
                icon: const Icon(AppIcons.add),
                onPressed: _add,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
