import 'package:equatable/equatable.dart';

import '../../../core/bloc/safe_cubit.dart';
import '../../../core/utils/arabic_search.dart';
import '../data/evaluations_repository.dart';
import '../domain/evaluation.dart';

enum EvaluationsStatus { loading, ready, error }

/// Whose evaluations the screen is showing.
///
/// Two lists, two doors, and not one screen with a switch on it: [mine] is
/// everybody's and hangs under العام — it is the errands this person was given —
/// while [all] asks for `evaluations.view` and hangs under الإدارة. The same
/// screen answers both; what differs is which question it asked the server, and
/// the server refuses [all] to whoever may not ask it.
enum EvaluationsScope { mine, all }

class EvaluationsState extends Equatable {
  const EvaluationsState({
    this.scope = EvaluationsScope.mine,
    this.status = EvaluationsStatus.loading,
    this.evaluations = const [],
    this.query = '',
    this.target,
    this.filterStatus,
    this.error,
  });

  final EvaluationsScope scope;
  final EvaluationsStatus status;
  final List<Evaluation> evaluations;
  final String query;
  final EvaluationTarget? target;
  final EvaluationStatus? filterStatus;
  final String? error;

  bool get isNarrowed =>
      query.trim().isNotEmpty || target != null || filterStatus != null;

  /// The list after the reader's narrowing.
  ///
  /// The server can narrow too — `evaluations_list` takes the same three — but
  /// it is asked only on the first read. A hundred rows are already in hand and
  /// a round trip per keystroke would be slower and no more correct.
  List<Evaluation> get visible => evaluations.where((e) {
    if (target != null && e.target != target) return false;
    if (filterStatus != null && e.status != filterStatus) return false;
    return arabicMatchesAll([
      e.targetLabel,
      e.templateTitle,
      e.evaluatorName,
      e.note,
    ], query);
  }).toList();

  /// Errands in hand, for the badge on the list this person owns. Counted over
  /// everything rather than over [visible]: a filter that hides the two
  /// outstanding sheets should not report that there are none.
  int get openCount =>
      evaluations.where((e) => !e.isSubmitted).length;

  int get overdueCount => evaluations.where((e) => e.isOverdue).length;

  EvaluationsState copyWith({
    EvaluationsScope? scope,
    EvaluationsStatus? status,
    List<Evaluation>? evaluations,
    String? query,
    EvaluationTarget? target,
    bool clearTarget = false,
    EvaluationStatus? filterStatus,
    bool clearStatus = false,
    String? error,
  }) => EvaluationsState(
    scope: scope ?? this.scope,
    status: status ?? this.status,
    evaluations: evaluations ?? this.evaluations,
    query: query ?? this.query,
    target: clearTarget ? null : (target ?? this.target),
    filterStatus: clearStatus ? null : (filterStatus ?? this.filterStatus),
    error: error,
  );

  @override
  List<Object?> get props => [
    scope,
    status,
    evaluations,
    query,
    target,
    filterStatus,
    error,
  ];
}

class EvaluationsCubit extends SafeCubit<EvaluationsState> {
  EvaluationsCubit(
    this._repo, {
    EvaluationsScope scope = EvaluationsScope.mine,
  }) : super(EvaluationsState(scope: scope)) {
    load();
  }

  final EvaluationsRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: EvaluationsStatus.loading, error: null));
    try {
      final evaluations = await _repo.fetchList(
        all: state.scope == EvaluationsScope.all,
      );
      emit(
        state.copyWith(
          status: EvaluationsStatus.ready,
          evaluations: evaluations,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: EvaluationsStatus.error, error: e.toString()),
      );
    }
  }

  void search(String value) => emit(state.copyWith(query: value));

  void setTarget(EvaluationTarget? target) => emit(
    target == null
        ? state.copyWith(clearTarget: true)
        : state.copyWith(target: target),
  );

  void setStatus(EvaluationStatus? status) => emit(
    status == null
        ? state.copyWith(clearStatus: true)
        : state.copyWith(filterStatus: status),
  );

  void clearFilters() => emit(
    state.copyWith(query: '', clearTarget: true, clearStatus: true),
  );

  /// Deleting from the register, which is the office's act and never the
  /// evaluator's — except for an untouched errand he was given and the person
  /// who gave it wants back, which the database decides rather than this.
  Future<String?> delete(String evaluationId) async {
    try {
      await _repo.delete(evaluationId);
      emit(
        state.copyWith(
          evaluations: [
            for (final e in state.evaluations)
              if (e.id != evaluationId) e,
          ],
        ),
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
