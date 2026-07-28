import 'package:equatable/equatable.dart';

import '../../../core/bloc/safe_cubit.dart';
import '../../profile/domain/profile.dart';
import '../../seasons/data/seasons_repository.dart';
import '../../seasons/domain/season.dart';
import '../data/employees_repository.dart';

enum DirectoryStatus { loading, loaded, error }

class EmployeesDirectoryState extends Equatable {
  const EmployeesDirectoryState({
    this.status = DirectoryStatus.loading,
    this.permanent = const [],
    this.external = const [],
    this.season,
    this.error,
  });

  final DirectoryStatus status;

  /// The Administration itself — the same people whatever season it is.
  final List<Profile> permanent;

  /// The externals of [season] only: a delegate is on the mission for a year,
  /// not for good.
  final List<Profile> external;

  final Season? season;
  final String? error;

  EmployeesDirectoryState copyWith({
    DirectoryStatus? status,
    List<Profile>? permanent,
    List<Profile>? external,
    Season? season,
    String? error,
  }) {
    return EmployeesDirectoryState(
      status: status ?? this.status,
      permanent: permanent ?? this.permanent,
      external: external ?? this.external,
      season: season ?? this.season,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, permanent, external, season, error];
}

class EmployeesDirectoryCubit extends SafeCubit<EmployeesDirectoryState> {
  EmployeesDirectoryCubit(this._repo, this._seasons)
    : super(const EmployeesDirectoryState()) {
    load();
  }

  final EmployeesRepository _repo;
  final SeasonsRepository _seasons;

  Future<void> load() async {
    emit(state.copyWith(status: DirectoryStatus.loading));
    try {
      final season = await _seasons.fetchCurrentSeason();
      final results = await Future.wait([
        _repo.fetchPermanent(),
        _repo.fetchExternal(seasonId: season?.id),
      ]);
      emit(
        state.copyWith(
          status: DirectoryStatus.loaded,
          permanent: results[0],
          external: results[1],
          season: season,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: DirectoryStatus.error, error: e.toString()));
    }
  }
}
