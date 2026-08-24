import 'package:equatable/equatable.dart';

import '../../../core/bloc/safe_cubit.dart';
import '../../../core/utils/arabic_search.dart';
import '../../seasons/data/seasons_repository.dart';
import '../data/travel_repository.dart';
import '../domain/trip.dart';

enum TripsStatus { loading, ready, error }

class TripsState extends Equatable {
  const TripsState({
    this.status = TripsStatus.loading,
    this.trips = const [],
    this.points = const [],
    this.query = '',
    this.role,
    this.mode,
    this.error,
  });

  final TripsStatus status;
  final List<Trip> trips;
  final List<TravelPoint> points;

  final String query;

  /// Narrowed to one leg of the season — القدوم, التنقل الداخلي, العودة. Null
  /// is all three, which is the honest default: the board is read as a whole
  /// far more often than one role at a time.
  final LegRole? role;
  final TravelMode? mode;

  final String? error;

  /// Filtered in the app rather than on the server. A season's trips number in
  /// the dozens, not the thousands — the employee directory makes the same call
  /// for the same reason, and the picker makes the opposite one because it is
  /// paging hundreds of people.
  List<Trip> get filtered {
    final q = query.trim();
    return trips
        .where((t) {
          if (role != null && t.role != role) return false;
          if (mode != null && t.mode != mode) return false;
          if (q.isEmpty) return true;
          return arabicMatchesAll([
            t.tripNumber,
            t.fromPoint.ar,
            t.fromPoint.en,
            t.toPoint.ar,
            t.toPoint.en,
          ], q);
        })
        .toList(growable: false);
  }

  /// The board, cut into the three parts of a season and each in time order.
  /// Grouped rather than flat because "which flights bring people in" and
  /// "which take them home" are different questions asked on different days.
  Map<LegRole, List<Trip>> get grouped {
    final out = <LegRole, List<Trip>>{};
    for (final role in LegRole.values) {
      final of = filtered.where((t) => t.role == role).toList()
        ..sort((a, b) => a.plannedDepartureAt.compareTo(b.plannedDepartureAt));
      if (of.isNotEmpty) out[role] = of;
    }
    return out;
  }

  bool get isNarrowed =>
      query.trim().isNotEmpty || role != null || mode != null;

  TripsState copyWith({
    TripsStatus? status,
    List<Trip>? trips,
    List<TravelPoint>? points,
    String? query,
    LegRole? role,
    TravelMode? mode,
    bool clearFilters = false,
    String? error,
  }) => TripsState(
    status: status ?? this.status,
    trips: trips ?? this.trips,
    points: points ?? this.points,
    query: clearFilters ? '' : (query ?? this.query),
    role: clearFilters ? null : (role ?? this.role),
    mode: clearFilters ? null : (mode ?? this.mode),
    error: error,
  );

  @override
  List<Object?> get props => [
    status,
    trips.map((t) => '${t.id}${t.assignedCount}${t.status}').join(),
    points.length,
    query,
    role,
    mode,
    error,
  ];
}

/// The season's trips, and creating them.
class TripsCubit extends SafeCubit<TripsState> {
  TripsCubit(this._repo, {this.seasonId}) : super(const TripsState()) {
    load();
  }

  final TravelRepository _repo;

  /// Null means the current season, which the database resolves. The board
  /// does not cache a season id of its own for the reason `SeasonsRepository`
  /// gives: which season is current is a server decision, not the phone's.
  final String? seasonId;

  Future<void> load() async {
    emit(state.copyWith(status: TripsStatus.loading, error: null));
    try {
      final trips = await _repo.fetchTrips(seasonId: seasonId);
      final points = state.points.isEmpty
          ? await _repo.fetchPoints()
          : state.points;
      emit(
        state.copyWith(status: TripsStatus.ready, trips: trips, points: points),
      );
    } catch (e) {
      emit(state.copyWith(status: TripsStatus.error, error: '$e'));
    }
  }

  void search(String value) => emit(state.copyWith(query: value));

  /// Passing the value already selected clears it — a filter pill toggles.
  void filterRole(LegRole? value) => emit(
    TripsState(
      status: state.status,
      trips: state.trips,
      points: state.points,
      query: state.query,
      role: state.role == value ? null : value,
      mode: state.mode,
    ),
  );

  void filterMode(TravelMode? value) => emit(
    TripsState(
      status: state.status,
      trips: state.trips,
      points: state.points,
      query: state.query,
      role: state.role,
      mode: state.mode == value ? null : value,
    ),
  );

  void clearFilters() => emit(state.copyWith(clearFilters: true));

  Future<String?> create(TripDraft draft) async {
    try {
      final season = seasonId ?? await _currentSeasonId();
      if (season == null) {
        emit(state.copyWith(error: 'no current season'));
        return null;
      }
      final id = await _repo.createTrip(draft, seasonId: season);
      await load();
      return id;
    } catch (e) {
      emit(state.copyWith(error: '$e'));
      return null;
    }
  }

  Future<bool> update(String tripId, TripDraft draft) async {
    try {
      await _repo.updateTrip(tripId, draft);
      await load();
      return true;
    } catch (e) {
      emit(state.copyWith(error: '$e'));
      return false;
    }
  }

  Future<bool> setStatus(String tripId, TripStatus status) async {
    try {
      await _repo.setTripStatus(tripId, status);
      await load();
      return true;
    } catch (e) {
      emit(state.copyWith(error: '$e'));
      return false;
    }
  }

  /// Refused by the database while anybody is still aboard (BR-11), and the
  /// refusal is worth showing rather than hiding: cancelling and erasing are
  /// different acts and the reader should be told which one they wanted.
  Future<bool> delete(String tripId) async {
    try {
      await _repo.deleteTrip(tripId);
      await load();
      return true;
    } catch (e) {
      emit(state.copyWith(error: '$e'));
      return false;
    }
  }

  /// Which season a new trip belongs to.
  ///
  /// Read off the board when there is anything on it, and asked otherwise —
  /// through [SeasonsRepository], which already holds the process-wide cache
  /// every screen in this app leans on rather than each one asking again.
  Future<String?> _currentSeasonId() async {
    if (state.trips.isNotEmpty) return state.trips.first.seasonId;
    return (await SeasonsRepository().fetchCurrentSeason())?.id;
  }
}
