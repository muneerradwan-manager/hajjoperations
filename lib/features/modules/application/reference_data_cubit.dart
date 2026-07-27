import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../seasons/data/seasons_repository.dart';
import '../../seasons/domain/season.dart';
import '../data/modules_repository.dart';
import '../domain/reference_item.dart';

enum ReferenceDataStatus { loading, ready, error }

/// Why a write did not go through. `inUse` and `duplicate` are the two an admin
/// will actually hit — deleting a hotel a module was built around, and typing a
/// name that is already on the list.
enum ReferenceOutcome { ok, inUse, duplicate, failed }

class ReferenceResult {
  const ReferenceResult(this.outcome, {this.message});

  final ReferenceOutcome outcome;
  final String? message;

  bool get isOk => outcome == ReferenceOutcome.ok;
}

class ReferenceDataState extends Equatable {
  const ReferenceDataState({
    this.status = ReferenceDataStatus.loading,
    this.sets = const [],
    this.season,
    this.error,
  });

  final ReferenceDataStatus status;

  /// Every set with every entry it has, in every season. The screen shows only
  /// [season]'s for a scoped set — but the whole list stays here, because
  /// resolving an id to a name must work for last season's entries too.
  final List<ReferenceSet> sets;

  final Season? season;
  final String? error;

  ReferenceSet? setById(String id) =>
      sets.where((s) => s.id == id).firstOrNull;

  /// The entries to SHOW for [setId]: this season's, for a set that is scoped.
  List<ReferenceItem> visibleItems(String setId) {
    final set = setById(setId);
    if (set == null) return const [];
    return set.itemsForSeason(season?.id);
  }

  ReferenceItem? itemById(String setId, String itemId) =>
      setById(setId)?.items.where((i) => i.id == itemId).firstOrNull;

  @override
  List<Object?> get props => [status, sets, season, error];
}

/// Master data the admin owns: the lists that back every dropdown, kept out of
/// free text so the same hotel is one hotel everywhere.
class ReferenceDataCubit extends Cubit<ReferenceDataState> {
  ReferenceDataCubit(this._repo, this._seasons)
    : super(const ReferenceDataState()) {
    load();
  }

  final ModulesRepository _repo;
  final SeasonsRepository _seasons;

  /// The season an entry is created into, for a set that is scoped to one.
  String? get seasonId => state.season?.id;

  Future<void> load() async {
    try {
      final season = await _seasons.fetchCurrentSeason();
      final sets = await _repo.fetchReferenceSets(activeOnly: false);
      emit(
        ReferenceDataState(
          status: ReferenceDataStatus.ready,
          sets: sets,
          season: season,
        ),
      );
    } catch (e) {
      emit(
        ReferenceDataState(
          status: ReferenceDataStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  /// Brings another season's entries into the current one. Returns how many
  /// were added, or null when it failed.
  Future<int?> importFromSeason({
    required String setId,
    required String fromSeasonId,
  }) async {
    final to = state.season?.id;
    if (to == null) return null;
    try {
      final copied = await _repo.copyReferenceItems(
        setId: setId,
        fromSeasonId: fromSeasonId,
        toSeasonId: to,
      );
      await load();
      return copied;
    } catch (_) {
      return null;
    }
  }

  /// The seasons an import could draw from: every one but the one in force.
  Future<List<Season>> otherSeasons() async {
    final seasons = await _seasons.fetchSeasons();
    return seasons.where((s) => s.id != state.season?.id).toList();
  }

  Future<ReferenceResult> addItem({
    required String setId,
    required String nameAr,
    String? nameEn,
    Map<String, dynamic> data = const {},
  }) async {
    return _write(
      () => _repo.addReferenceItem(
        setId: setId,
        nameAr: nameAr,
        nameEn: nameEn,
        data: data,
        // Stamped only for a scoped set: a new hotel is a hotel of THIS season,
        // a new city is a city.
        seasonId: (state.setById(setId)?.isSeasonScoped ?? false)
            ? seasonId
            : null,
      ),
    );
  }

  Future<ReferenceResult> updateItem({
    required String id,
    required String nameAr,
    String? nameEn,
    Map<String, dynamic> data = const {},
  }) async {
    return _write(
      () => _repo.updateReferenceItem(
        id: id,
        nameAr: nameAr,
        nameEn: nameEn,
        data: data,
      ),
    );
  }

  Future<ReferenceResult> deleteItem(String id) =>
      _write(() => _repo.deleteReferenceItem(id));

  Future<ReferenceResult> _write(Future<void> Function() action) async {
    try {
      await action();
      await load();
      return const ReferenceResult(ReferenceOutcome.ok);
    } catch (e) {
      // The delete guard raises this sentinel; it deserves its own message
      // rather than a raw Postgres error.
      final text = e.toString();
      if (text.contains('reference_item_in_use')) {
        return const ReferenceResult(ReferenceOutcome.inUse);
      }
      // The (set_id, name_ar) unique index — the whole point of master data.
      if (text.contains('duplicate key') || text.contains('23505')) {
        return const ReferenceResult(ReferenceOutcome.duplicate);
      }
      return ReferenceResult(ReferenceOutcome.failed, message: text);
    }
  }
}
