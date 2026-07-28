import 'package:equatable/equatable.dart';

import '../../../core/bloc/safe_cubit.dart';
import '../../seasons/data/seasons_repository.dart';
import '../../seasons/domain/season.dart';
import '../data/modules_repository.dart';
import '../domain/module_type.dart';
import '../domain/operational_module.dart';

enum ModulesStatus { loading, ready, error }

class ModulesState extends Equatable {
  const ModulesState({
    this.status = ModulesStatus.loading,
    this.modules = const [],
    this.types = const [],
    this.season,
    this.error,
  });

  final ModulesStatus status;

  /// The files of [season] only. A file belongs to one season, and the season
  /// in force is a choice the admin makes — switching it should change what
  /// this screen is about.
  final List<OperationalModule> modules;

  /// The season everything here belongs to. Null when none is current, which is
  /// also when nothing can be created.
  final Season? season;

  /// Types available when creating — also the source of the "no types defined
  /// yet" message on an empty system.
  final List<ModuleType> types;
  final String? error;

  /// The files that are actually running: switched on, and not past their end
  /// date. A file that has run out is no more a working file than one nobody
  /// activated — which is the same answer the database gives its members.
  List<OperationalModule> get active =>
      modules.where((m) => m.isRunning).toList();

  /// Everything else — never activated, switched off, or finished. Each card
  /// says WHICH of those it is; the section only says it is not running.
  ///
  /// Only managers ever receive these rows; RLS filters them out for everyone
  /// else, so no extra permission check is needed to render the section.
  List<OperationalModule> get drafts =>
      modules.where((m) => !m.isRunning).toList();

  /// The types that could still be opened this season. A file exists at most
  /// once per season, so a type already used is not offered again. [modules] is
  /// already this season's, which is why nothing here filters by season.
  List<ModuleType> typesAvailable() {
    final taken = {for (final m in modules) m.moduleTypeId};
    return types.where((t) => !taken.contains(t.id)).toList();
  }

  @override
  List<Object?> get props => [status, modules, types, season, error];
}

class ModulesCubit extends SafeCubit<ModulesState> {
  ModulesCubit(this._repo, this._seasons) : super(const ModulesState()) {
    load();
  }

  final ModulesRepository _repo;
  final SeasonsRepository _seasons;

  Future<void> load() async {
    emit(const ModulesState(status: ModulesStatus.loading));
    try {
      // The season decides what this screen is about, so it is read first and
      // everything below is scoped to it.
      final season = await _seasons.fetchCurrentSeason();
      final modules = season == null
          ? const <OperationalModule>[]
          : await _repo.fetchModules(seasonId: season.id);
      final types = await _repo.fetchModuleTypes();
      emit(
        ModulesState(
          status: ModulesStatus.ready,
          modules: modules,
          types: types,
          season: season,
        ),
      );
    } catch (e) {
      emit(ModulesState(status: ModulesStatus.error, error: e.toString()));
    }
  }
}
