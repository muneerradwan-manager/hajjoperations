import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/states.dart';
import '../../modules/data/modules_repository.dart';
import '../../modules/domain/module_type.dart';
import '../../modules/presentation/widgets/module_field_input.dart';
import '../../seasons/data/seasons_repository.dart';
import '../application/report_editor_cubit.dart';
import '../data/reports_repository.dart';
import '../domain/report.dart';

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
                    if (t.hasTable) ...[
                      const SizedBox(height: AppSpacing.md),
                      _Table(state: state, cubit: cubit),
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

  @override
  void dispose() {
    _title.dispose();
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
                  TextFormField(
                    // Keyed by row AND column: adding or removing a row must
                    // not leave a field showing the value of the one it
                    // replaced.
                    key: ValueKey('${i}_${c.key}'),
                    initialValue: state.rows[i].value(c.key),
                    keyboardType: c.column.kind == ModuleFieldKind.number
                        ? TextInputType.number
                        : TextInputType.text,
                    maxLines: c.column.kind == ModuleFieldKind.textarea ? 4 : 1,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: c.label(context),
                    ),
                    onChanged: (v) => cubit.setCell(i, c.key, v),
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
