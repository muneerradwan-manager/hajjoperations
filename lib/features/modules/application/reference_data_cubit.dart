import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    this.error,
  });

  final ReferenceDataStatus status;
  final List<ReferenceSet> sets;
  final String? error;

  ReferenceSet? setById(String id) =>
      sets.where((s) => s.id == id).firstOrNull;

  ReferenceItem? itemById(String setId, String itemId) =>
      setById(setId)?.items.where((i) => i.id == itemId).firstOrNull;

  @override
  List<Object?> get props => [status, sets, error];
}

/// Master data the admin owns: the lists that back every dropdown, kept out of
/// free text so the same hotel is one hotel everywhere.
class ReferenceDataCubit extends Cubit<ReferenceDataState> {
  ReferenceDataCubit(this._repo) : super(const ReferenceDataState()) {
    load();
  }

  final ModulesRepository _repo;

  Future<void> load() async {
    try {
      final sets = await _repo.fetchReferenceSets(activeOnly: false);
      emit(ReferenceDataState(status: ReferenceDataStatus.ready, sets: sets));
    } catch (e) {
      emit(
        ReferenceDataState(
          status: ReferenceDataStatus.error,
          error: e.toString(),
        ),
      );
    }
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
