import 'package:equatable/equatable.dart';

import '../../../core/bloc/safe_cubit.dart';
import '../../profile/domain/profile.dart';
import '../../seasons/data/seasons_repository.dart';
import '../../seasons/domain/season.dart';
import '../data/employees_repository.dart';

class EmployeeManageState extends Equatable {
  const EmployeeManageState({
    required this.profile,
    this.currentSeason,
    this.inCurrentSeason = false,
    this.seasonHistory = const [],
    this.loadingSeason = true,
    this.busy = false,
    this.error,
  });

  final Profile profile;
  final Season? currentSeason;
  final bool inCurrentSeason;

  /// Every season this employee is taking part in, newest first.
  final List<Season> seasonHistory;
  final bool loadingSeason;
  final bool busy;
  final String? error;

  EmployeeManageState copyWith({
    Profile? profile,
    Season? currentSeason,
    bool? inCurrentSeason,
    List<Season>? seasonHistory,
    bool? loadingSeason,
    bool? busy,
    String? error,
  }) {
    return EmployeeManageState(
      profile: profile ?? this.profile,
      currentSeason: currentSeason ?? this.currentSeason,
      inCurrentSeason: inCurrentSeason ?? this.inCurrentSeason,
      seasonHistory: seasonHistory ?? this.seasonHistory,
      loadingSeason: loadingSeason ?? this.loadingSeason,
      busy: busy ?? this.busy,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    profile,
    currentSeason,
    inCurrentSeason,
    seasonHistory,
    loadingSeason,
    busy,
    error,
  ];
}

/// Backs the admin employee-detail hub: view + suspend/reactivate, external
/// designation, and current-season participation toggling.
class EmployeeManageCubit extends SafeCubit<EmployeeManageState> {
  EmployeeManageCubit(this._employees, this._seasons, Profile profile)
    : super(EmployeeManageState(profile: profile)) {
    _loadSeason();
  }

  final EmployeesRepository _employees;
  final SeasonsRepository _seasons;

  Future<void> _loadSeason() async {
    try {
      final history = await _seasons.fetchParticipationHistory(
        state.profile.id,
      );
      final season = await _seasons.fetchCurrentSeason();
      emit(
        state.copyWith(
          currentSeason: season,
          // Derived from the history rather than a second round trip.
          inCurrentSeason:
              season != null && history.any((s) => s.id == season.id),
          seasonHistory: history,
          loadingSeason: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(loadingSeason: false, error: e.toString()));
    }
  }

  Future<void> toggleSuspended() async {
    final next = !state.profile.isSuspended;
    emit(state.copyWith(busy: true));
    try {
      await _employees.setSuspended(state.profile.id, next);
      emit(
        state.copyWith(
          profile: state.profile.copyWith(isSuspended: next),
          busy: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(busy: false, error: e.toString()));
    }
  }

  Future<void> saveExternal({
    required bool isExternal,
    String? organization,
    String? externalRole,
  }) async {
    emit(state.copyWith(busy: true));
    try {
      await _employees.updateExternalStatus(
        profileId: state.profile.id,
        isExternal: isExternal,
        organization: organization,
        externalRole: externalRole,
      );
      emit(
        state.copyWith(
          profile: state.profile.copyWith(
            isExternal: isExternal,
            externalOrganization: isExternal ? organization : null,
            externalTitle: isExternal ? externalRole : null,
          ),
          busy: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(busy: false, error: e.toString()));
    }
  }

  Future<void> toggleCurrentSeason() async {
    final season = state.currentSeason;
    if (season == null) return;
    final next = !state.inCurrentSeason;
    emit(state.copyWith(busy: true));
    try {
      if (next) {
        await _seasons.addParticipant(season.id, state.profile.id);
      } else {
        await _seasons.removeParticipant(season.id, state.profile.id);
      }
      // Keep the history list in step with the toggle.
      final history = [...state.seasonHistory]
        ..removeWhere((s) => s.id == season.id);
      if (next) {
        history.add(season);
        history.sort((a, b) => b.hijriYear.compareTo(a.hijriYear));
      }
      emit(
        state.copyWith(
          inCurrentSeason: next,
          seasonHistory: history,
          busy: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(busy: false, error: e.toString()));
    }
  }
}
