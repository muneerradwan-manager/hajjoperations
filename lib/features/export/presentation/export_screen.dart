import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/error_text.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/states.dart';
import '../../auth/application/session_cubit.dart';
import '../application/export_cubit.dart';
import '../data/export_runner.dart';
import '../domain/export_dataset.dart';

/// Taking data out of the app: what, which parts of it, and in what shape.
///
/// Three questions in that order, and the middle one is the reason this screen
/// exists rather than an export button on each list. What a person wants out of
/// the employees is almost never all forty of their fields — it is the name,
/// the trade and the telephone, for one particular purpose — and a system that
/// exports everything makes him delete columns in Excel, which is where files
/// get quietly wrong.
class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionCubit>().state;
    return BlocProvider(
      create: (_) => ExportCubit(
        isAdmin: session.profile?.isAdmin ?? false,
        permissions: session.permissions,
      ),
      child: const _ExportView(),
    );
  }
}

class _ExportView extends StatelessWidget {
  const _ExportView();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      appBar: GlassAppBar(title: Text(l.exportTitle)),
      body: BlocConsumer<ExportCubit, ExportState>(
        listenWhen: (a, b) =>
            a.error != b.error || a.lastRowCount != b.lastRowCount,
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state.error != null) {
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(friendlyError(context, state.error))),
              );
            return;
          }
          final rows = state.lastRowCount;
          if (rows == null) return;
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  // Said either way. "Exported 0 rows" is the single most
                  // useful sentence this screen produces: it almost always
                  // means an option is on the wrong answer, and without it the
                  // person emails an empty sheet.
                  rows == 0 ? l.exportNothingMatched : l.exportDoneRows(rows),
                ),
              ),
            );
        },
        builder: (context, state) {
          if (state.datasets.isEmpty) {
            return EmptyState(
              icon: AppIcons.upload,
              title: l.exportNothingAvailable,
              message: l.exportNothingAvailableHint,
            );
          }

          // A form of choices rather than a reading column, so it stops well
          // short of a monitor's width; and its bottom padding comes from
          // `scrollPadding`, which is what keeps the export button above the
          // Android 15 gesture bar instead of behind it.
          return ResponsivePage(
            width: PageWidth.form,
            builder: (context, size) => SinglePaneLayout(
              gutter: size.gutter,
              children: [
              SectionHeader(l.exportWhat),
              _DatasetPicker(state: state),
              if (state.dataset != null) ...[
                for (final option in state.dataset!.options)
                  _OptionPicker(option: option, state: state),
                const SizedBox(height: AppSpacing.md),
                SectionHeader(
                  l.exportWhichColumns,
                  trailing: _ColumnActions(state: state),
                ),
                _ColumnPicker(state: state),
                const SizedBox(height: AppSpacing.md),
                SectionHeader(l.exportFormat),
                _FormatPicker(state: state),
                const SizedBox(height: AppSpacing.lg),
                _RunButton(state: state),
              ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DatasetPicker extends StatelessWidget {
  const _DatasetPicker({required this.state});
  final ExportState state;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final dataset in state.datasets)
          ChoiceChip(
            label: Text(dataset.name.inLanguage(language)),
            selected: state.dataset?.id == dataset.id,
            onSelected: (_) =>
                context.read<ExportCubit>().selectDataset(dataset),
          ),
      ],
    );
  }
}

class _OptionPicker extends StatelessWidget {
  const _OptionPicker({required this.option, required this.state});

  final ExportOption option;
  final ExportState state;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final choices = state.choices[option.key] ?? const <ExportChoice>[];
    final value = state.options[option.key];

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: DropdownButtonFormField<String>(
        initialValue: choices.any((c) => c.id == value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: option.label.inLanguage(language),
          // An optional one says so, because "الموسم" with nothing chosen is
          // read as "not chosen yet" rather than as "every season".
          helperText: option.required ? null : context.l10n.exportOptionAny,
        ),
        items: [
          for (final choice in choices)
            DropdownMenuItem(
              value: choice.id,
              child: Text(
                choice.label.inLanguage(language),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (picked) {
          if (picked == null) return;
          context.read<ExportCubit>().setOption(option.key, picked);
        },
      ),
    );
  }
}

class _ColumnActions extends StatelessWidget {
  const _ColumnActions({required this.state});
  final ExportState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cubit = context.read<ExportCubit>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: cubit.selectDefaultColumns,
          child: Text(l.exportColumnsDefault),
        ),
        TextButton(
          onPressed: cubit.selectAllColumns,
          child: Text(l.exportColumnsAll),
        ),
      ],
    );
  }
}

class _ColumnPicker extends StatelessWidget {
  const _ColumnPicker({required this.state});
  final ExportState state;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final l = context.l10n;

    if (state.status == ExportStatus.preparing) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: AppLoader(),
      );
    }

    return GlassCard(
      child: Column(
        children: [
          for (final column in state.columns)
            CheckboxListTile(
              dense: true,
              value: state.selected.contains(column.key),
              title: Text(column.label.inLanguage(language)),
              onChanged: (_) =>
                  context.read<ExportCubit>().toggleColumn(column.key),
            ),
          if (state.selected.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                l.exportPickAtLeastOne,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}

class _FormatPicker extends StatelessWidget {
  const _FormatPicker({required this.state});
  final ExportState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SegmentedButton<ExportFormat>(
      segments: [
        ButtonSegment(
          value: ExportFormat.csv,
          label: Text(l.exportFormatCsv),
          icon: const Icon(AppIcons.file, size: 16),
        ),
        ButtonSegment(
          value: ExportFormat.pdf,
          label: Text(l.exportFormatPdf),
          icon: const Icon(AppIcons.file, size: 16),
        ),
      ],
      selected: {state.format},
      onSelectionChanged: (picked) =>
          context.read<ExportCubit>().setFormat(picked.first),
    );
  }
}

class _RunButton extends StatelessWidget {
  const _RunButton({required this.state});
  final ExportState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final running = state.status == ExportStatus.running;

    return FilledButton.icon(
      onPressed: state.canRun
          ? () => context.read<ExportCubit>().run(
              l: l,
              languageCode: Localizations.localeOf(context).languageCode,
              subtitle: l.exportGeneratedBy,
              pageLabel: l.exportPage,
            )
          : null,
      icon: running
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(AppIcons.upload),
      label: Text(running ? l.exportRunning : l.exportRun),
    );
  }
}
