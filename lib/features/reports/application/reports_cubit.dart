import 'package:equatable/equatable.dart';

import '../../../core/bloc/safe_cubit.dart';
import '../../../core/utils/arabic_search.dart';
import '../../seasons/data/seasons_repository.dart';
import '../data/reports_repository.dart';
import '../domain/report.dart';
import '../domain/report_type.dart';

enum ReportsStatus { loading, ready, error }

/// Which reports the list is showing.
enum ReportScope {
  /// Everything the reader may see.
  all,

  /// Tied to the season being run.
  seasonal,

  /// True whichever season it is.
  general,
}

class ReportsState extends Equatable {
  const ReportsState({
    this.status = ReportsStatus.loading,
    this.reports = const [],
    this.types = const [],
    this.query = '',
    this.scope = ReportScope.all,
    this.typeId,
    this.error,
  });

  final ReportsStatus status;
  final List<Report> reports;

  /// The catalog, for the type filter. The reader never sees a type as a
  /// concept — only as a way of narrowing a list that is otherwise long.
  final List<ReportType> types;

  final String query;
  final ReportScope scope;
  final String? typeId;
  final String? error;

  bool get isNarrowed =>
      query.trim().isNotEmpty || scope != ReportScope.all || typeId != null;

  /// The list after the reader's narrowing. Done here rather than in the
  /// database: the whole list is already in hand and it is tens of rows, not
  /// thousands — a round trip per keystroke would be slower and no more
  /// correct.
  List<Report> get visible {
    return reports.where((r) {
      if (typeId != null && r.reportTypeId != typeId) return false;
      switch (scope) {
        case ReportScope.seasonal:
          if (!r.isSeasonal) return false;
        case ReportScope.general:
          if (r.isSeasonal) return false;
        case ReportScope.all:
          break;
      }
      return arabicMatchesAll([
        r.title,
        r.typeName?.ar,
        r.typeName?.en,
      ], query);
    }).toList();
  }

  ReportsState copyWith({
    ReportsStatus? status,
    List<Report>? reports,
    List<ReportType>? types,
    String? query,
    ReportScope? scope,
    Object? typeId = _unset,
    String? error,
  }) => ReportsState(
    status: status ?? this.status,
    reports: reports ?? this.reports,
    types: types ?? this.types,
    query: query ?? this.query,
    scope: scope ?? this.scope,
    // Null is a real value here — it means "any kind" — so `??` could never
    // clear it.
    typeId: typeId == _unset ? this.typeId : typeId as String?,
    error: error,
  );

  @override
  List<Object?> get props => [
    status,
    reports,
    types,
    query,
    scope,
    typeId,
    error,
  ];
}

const Object _unset = Object();

class ReportsCubit extends SafeCubit<ReportsState> {
  ReportsCubit(this._repo, this._seasons) : super(const ReportsState()) {
    load();
  }

  final ReportsRepository _repo;
  final SeasonsRepository _seasons;

  Future<void> load() async {
    emit(state.copyWith(status: ReportsStatus.loading, error: null));
    try {
      final season = await _seasons.fetchCurrentSeason();
      final reports = await _repo.fetchReports(seasonId: season?.id);
      final types = await _repo.fetchTypes();
      emit(
        state.copyWith(
          status: ReportsStatus.ready,
          reports: reports,
          types: types,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: ReportsStatus.error, error: e.toString()));
    }
  }

  void search(String value) => emit(state.copyWith(query: value));
  void setScope(ReportScope scope) => emit(state.copyWith(scope: scope));
  void setType(String? id) => emit(state.copyWith(typeId: id));

  void clearFilters() => emit(
    state.copyWith(query: '', scope: ReportScope.all, typeId: null),
  );
}
