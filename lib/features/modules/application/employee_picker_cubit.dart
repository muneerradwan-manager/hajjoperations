import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/modules_repository.dart';
import '../domain/assignable_employee.dart';

enum PickerStatus { loading, ready, error }

/// Which participants to show. The mission runs on both, and which one you are
/// looking for is usually decided before you start typing.
enum ParticipantFilter {
  all,
  internal,
  external;

  bool? get isExternal => switch (this) {
    ParticipantFilter.all => null,
    ParticipantFilter.internal => false,
    ParticipantFilter.external => true,
  };
}

class EmployeePickerState extends Equatable {
  const EmployeePickerState({
    this.status = PickerStatus.loading,
    this.people = const [],
    this.selected = const {},
    this.query = '',
    this.filter = ParticipantFilter.all,
    this.loadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final PickerStatus status;
  final List<AssignableEmployee> people;

  /// Held here rather than in the widget so it survives a search that empties
  /// the list: choosing three people, searching for a fourth and finding none
  /// must not lose the three.
  final Set<String> selected;

  final String query;
  final ParticipantFilter filter;
  final bool loadingMore;

  /// False once a page came back short — there is nothing further to ask for.
  final bool hasMore;

  final String? error;

  EmployeePickerState copyWith({
    PickerStatus? status,
    List<AssignableEmployee>? people,
    Set<String>? selected,
    String? query,
    ParticipantFilter? filter,
    bool? loadingMore,
    bool? hasMore,
    String? error,
  }) {
    return EmployeePickerState(
      status: status ?? this.status,
      people: people ?? this.people,
      selected: selected ?? this.selected,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    people,
    selected,
    query,
    filter,
    loadingMore,
    hasMore,
    error,
  ];
}

/// Drives the page that chooses people for a role.
///
/// Every narrowing — the text, the filter, the next page — is a question put to
/// the database rather than a pass over a list held here. At five hundred
/// participants that is the difference between a page that opens and one that
/// waits for the whole roster first.
class EmployeePickerCubit extends Cubit<EmployeePickerState> {
  EmployeePickerCubit(
    this._repo, {
    required this.seasonId,
    Set<String> selected = const {},
  }) : super(EmployeePickerState(selected: {...selected})) {
    _fetch();
  }

  final ModulesRepository _repo;
  final String seasonId;

  static const _pageSize = 40;

  Timer? _debounce;

  /// Guards against an older, slower search overwriting a newer one.
  int _generation = 0;

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  /// Typing is not a search. Each keystroke restarts the clock, and only the
  /// pause at the end of a word reaches the database.
  void search(String value) {
    emit(state.copyWith(query: value));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _fetch);
  }

  void setFilter(ParticipantFilter filter) {
    if (filter == state.filter) return;
    _debounce?.cancel();
    emit(state.copyWith(filter: filter));
    _fetch();
  }

  void toggle(String profileId) {
    final selected = {...state.selected};
    if (!selected.remove(profileId)) selected.add(profileId);
    emit(state.copyWith(selected: selected));
  }

  /// Replaces the selection outright — what a single-holder role does when a
  /// name is tapped.
  void selectOnly(String profileId) =>
      emit(state.copyWith(selected: {profileId}));

  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    final generation = ++_generation;
    emit(state.copyWith(status: PickerStatus.loading, error: null));
    try {
      final people = await _repo.searchAssignableEmployees(
        seasonId: seasonId,
        query: state.query,
        isExternal: state.filter.isExternal,
        limit: _pageSize,
      );
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          status: PickerStatus.ready,
          people: people,
          hasMore: people.length == _pageSize,
        ),
      );
    } catch (e) {
      if (isClosed || generation != _generation) return;
      emit(state.copyWith(status: PickerStatus.error, error: e.toString()));
    }
  }

  /// The next page, appended. Does nothing while one is already in flight or
  /// once the list has run out.
  Future<void> loadMore() async {
    if (state.loadingMore ||
        !state.hasMore ||
        state.status != PickerStatus.ready) {
      return;
    }
    final generation = _generation;
    emit(state.copyWith(loadingMore: true));
    try {
      final more = await _repo.searchAssignableEmployees(
        seasonId: seasonId,
        query: state.query,
        isExternal: state.filter.isExternal,
        limit: _pageSize,
        offset: state.people.length,
      );
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          people: [...state.people, ...more],
          hasMore: more.length == _pageSize,
          loadingMore: false,
        ),
      );
    } catch (_) {
      if (isClosed || generation != _generation) return;
      emit(state.copyWith(loadingMore: false));
    }
  }
}
