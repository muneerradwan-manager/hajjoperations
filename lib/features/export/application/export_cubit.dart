import 'package:equatable/equatable.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/bloc/safe_cubit.dart';
import '../../../core/share/shareable.dart';
import '../../../l10n/app_localizations.dart';
import '../data/export_catalog.dart';
import '../data/export_runner.dart';
import '../domain/export_dataset.dart';

enum ExportStatus { choosing, preparing, running, error }

class ExportState extends Equatable {
  const ExportState({
    this.datasets = const [],
    this.dataset,
    this.choices = const {},
    this.options = const {},
    this.columns = const [],
    this.selected = const {},
    this.format = ExportFormat.csv,
    this.status = ExportStatus.choosing,
    this.error,
    this.lastRowCount,
  });

  final List<ExportDataset> datasets;
  final ExportDataset? dataset;

  /// The answers each option offers, once fetched.
  final Map<String, List<ExportChoice>> choices;

  /// What has been answered.
  final Map<String, String> options;

  /// The dataset's own columns, plus any that only exist once an option was
  /// chosen.
  final List<ExportColumn> columns;
  final Set<String> selected;

  final ExportFormat format;
  final ExportStatus status;
  final String? error;

  /// How many rows the last export carried. Shown afterwards, because a file
  /// with no rows and a file with four hundred look the same in a folder, and
  /// the empty one usually means an option was left on the wrong answer.
  final int? lastRowCount;

  /// Whether there is anything to export yet: a dataset, at least one column,
  /// and an answer to every option that insists on one.
  bool get canRun {
    final target = dataset;
    if (target == null || selected.isEmpty) return false;
    for (final option in target.options) {
      if (option.required && (options[option.key] ?? '').isEmpty) return false;
    }
    return status != ExportStatus.running && status != ExportStatus.preparing;
  }

  ExportState copyWith({
    List<ExportDataset>? datasets,
    ExportDataset? dataset,
    Map<String, List<ExportChoice>>? choices,
    Map<String, String>? options,
    List<ExportColumn>? columns,
    Set<String>? selected,
    ExportFormat? format,
    ExportStatus? status,
    String? error,
    bool clearError = false,
    int? lastRowCount,
    bool clearRowCount = false,
  }) => ExportState(
    datasets: datasets ?? this.datasets,
    dataset: dataset ?? this.dataset,
    choices: choices ?? this.choices,
    options: options ?? this.options,
    columns: columns ?? this.columns,
    selected: selected ?? this.selected,
    format: format ?? this.format,
    status: status ?? this.status,
    error: clearError ? null : (error ?? this.error),
    lastRowCount: clearRowCount ? null : (lastRowCount ?? this.lastRowCount),
  );

  @override
  List<Object?> get props => [
    datasets,
    dataset?.id,
    choices,
    options,
    [for (final column in columns) column.key],
    selected,
    format,
    status,
    error,
    lastRowCount,
  ];
}

/// Drives the export screen: what can be exported, what of it, and in what.
class ExportCubit extends SafeCubit<ExportState> {
  ExportCubit({required bool isAdmin, required Set<String> permissions})
    : super(
        ExportState(
          datasets: ExportCatalog.visibleTo(
            isAdmin: isAdmin,
            permissions: permissions,
          ),
        ),
      );

  Future<void> selectDataset(ExportDataset dataset) async {
    emit(
      ExportState(
        datasets: state.datasets,
        dataset: dataset,
        columns: dataset.columns,
        selected: dataset.defaultColumns,
        format: state.format,
        status: ExportStatus.preparing,
      ),
    );

    try {
      final choices = <String, List<ExportChoice>>{};
      for (final option in dataset.options) {
        choices[option.key] = await option.choices();
      }
      emit(state.copyWith(choices: choices, status: ExportStatus.choosing));
    } catch (e) {
      emit(state.copyWith(status: ExportStatus.error, error: e.toString()));
    }
  }

  Future<void> setOption(String key, String value) async {
    final dataset = state.dataset;
    if (dataset == null) return;

    final options = {...state.options, key: value};
    emit(state.copyWith(options: options, status: ExportStatus.preparing));

    try {
      // The extra columns depend on the answers, so they are re-resolved rather
      // than added to: changing the chosen list from the hotels to the camps
      // must take the hotels' own fields away with it, or the sheet offers
      // columns that no row has anything for.
      final extra = await dataset.extraColumns(options);
      final columns = [...dataset.columns, ...extra];
      final live = {for (final column in columns) column.key};
      emit(
        state.copyWith(
          columns: columns,
          selected: state.selected.where(live.contains).toSet(),
          status: ExportStatus.choosing,
          clearRowCount: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: ExportStatus.error, error: e.toString()));
    }
  }

  void toggleColumn(String key) {
    final selected = {...state.selected};
    if (!selected.remove(key)) selected.add(key);
    emit(state.copyWith(selected: selected, clearRowCount: true));
  }

  void selectAllColumns() => emit(
    state.copyWith(
      selected: {for (final column in state.columns) column.key},
      clearRowCount: true,
    ),
  );

  void selectDefaultColumns() => emit(
    state.copyWith(
      selected: state.dataset?.defaultColumns ?? const {},
      clearRowCount: true,
    ),
  );

  void setFormat(ExportFormat format) =>
      emit(state.copyWith(format: format, clearRowCount: true));

  /// The file in the shape the share sheet wants it.
  ///
  /// A real file on disk where there is a disk: that is what every native share
  /// sheet takes, and a temporary directory is exactly the right home for
  /// something whose whole life is the next few seconds.
  ///
  /// The web has no such directory — `path_provider` has no implementation
  /// there — so the bytes are handed over as they are, and the browser's own
  /// share or download takes them from memory. Written as a fallback on the
  /// failure rather than as a check on `kIsWeb`, because the thing that matters
  /// is whether a directory can be had, not which platform is asking.
  /// Moved to `core/share/shareable.dart` when the place-code card needed the
  /// same fallback; kept here as one line so the call sites below read as they
  /// did.
  Future<XFile> _asShareable(ExportFile file) => asShareable(
    file.bytes,
    name: file.name,
    mimeType: file.format.mimeType,
  );

  /// Builds the file and hands it to the platform's share sheet.
  ///
  /// Sharing rather than saving to a folder, and that is the right shape for
  /// what this is for: the sheet is going to somebody — email, WhatsApp, a
  /// drive — far more often than it is going to sit on the phone. The share
  /// sheet includes "save to files" wherever the platform has one, so nothing
  /// is lost by starting there.
  Future<void> run({
    required AppLocalizations l,
    required String languageCode,
    required String subtitle,
    required String pageLabel,
  }) async {
    final dataset = state.dataset;
    if (dataset == null || !state.canRun) return;

    emit(state.copyWith(status: ExportStatus.running, clearError: true, clearRowCount: true));

    try {
      final file = await ExportRunner.run(
        dataset: dataset,
        request: ExportRequest(
          columnKeys: state.selected,
          options: state.options,
          l: l,
          languageCode: languageCode,
        ),
        format: state.format,
        columns: state.columns,
        subtitle: subtitle,
        pageLabel: pageLabel,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [await _asShareable(file)],
          title: state.dataset?.name.inLanguage(languageCode),
        ),
      );

      emit(
        state.copyWith(
          status: ExportStatus.choosing,
          lastRowCount: file.rowCount,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: ExportStatus.error, error: e.toString()));
    }
  }
}
