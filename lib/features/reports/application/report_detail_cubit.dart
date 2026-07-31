import 'package:equatable/equatable.dart';

import '../../../core/bloc/safe_cubit.dart';
import '../../modules/data/modules_repository.dart';
import '../../modules/domain/reference_item.dart';
import '../data/reports_repository.dart';
import '../domain/report.dart';
import '../domain/report_type.dart';

enum ReportDetailStatus { loading, ready, missing, error }

class ReportDetailState extends Equatable {
  const ReportDetailState({
    this.status = ReportDetailStatus.loading,
    this.report,
    this.type,
    this.referenceSets = const [],
    this.error,
  });

  final ReportDetailStatus status;
  final Report? report;
  final ReportType? type;

  /// Needed to resolve two things: a reference cell's value, and the columns of
  /// an EXPANDED declaration — توزيع الوجبات has a column per تكتل and the
  /// clusters live in master data.
  final List<ReferenceSet> referenceSets;

  final String? error;

  ReferenceSet? setById(String? id) =>
      id == null ? null : referenceSets.where((s) => s.id == id).firstOrNull;

  /// The columns as they are actually drawn: a plain declaration stands for
  /// itself, and one with a source list becomes a column per entry of it.
  ///
  /// Scoped to the report's own season for a season-scoped list, so last year's
  /// clusters do not appear as empty columns on this year's table.
  List<({String key, String Function(dynamic) label, ReportColumn column})>
  get drawnColumns {
    final t = type;
    final r = report;
    if (t == null || r == null) return const [];
    final out =
        <({String key, String Function(dynamic) label, ReportColumn column})>[];
    for (final c in t.columns) {
      if (!c.isExpanded) {
        out.add((key: c.key, label: (ctx) => c.label.of(ctx), column: c));
        continue;
      }
      final set = setById(c.sourceSetId);
      if (set == null) continue;
      for (final item in set.itemsForSeason(r.seasonId)) {
        out.add((
          key: item.id,
          label: (ctx) => item.name.of(ctx),
          column: c,
        ));
      }
    }
    return out;
  }

  @override
  List<Object?> get props => [status, report, type, referenceSets, error];
}

class ReportDetailCubit extends SafeCubit<ReportDetailState> {
  ReportDetailCubit(this._repo, this._modules, this.reportId)
    : super(const ReportDetailState()) {
    load();
  }

  final ReportsRepository _repo;

  /// The master-data lists live with the modules feature; a report reads them
  /// rather than keeping a second copy.
  final ModulesRepository _modules;

  final String reportId;

  Future<void> load() async {
    emit(const ReportDetailState());
    try {
      final report = await _repo.fetchReport(reportId);
      if (report == null) {
        emit(const ReportDetailState(status: ReportDetailStatus.missing));
        return;
      }
      final types = await _repo.fetchTypes();
      final sets = await _modules.fetchReferenceSets(activeOnly: false);
      emit(
        ReportDetailState(
          status: ReportDetailStatus.ready,
          report: report,
          type: types.where((t) => t.id == report.reportTypeId).firstOrNull,
          referenceSets: sets,
        ),
      );
    } catch (e) {
      emit(
        ReportDetailState(
          status: ReportDetailStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  /// Passed straight to the shared attachments widget, so it keeps that
  /// widget's signature rather than a simpler one of its own.
  Future<String> signedUrl(
    String path, {
    bool download = false,
    String? downloadName,
  }) => _repo.signedUrl(path, download: download, downloadName: downloadName);
}
