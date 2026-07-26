import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/modules_repository.dart';
import '../domain/module_type.dart';
import '../domain/operational_module.dart';

enum ModulesStatus { loading, ready, error }

class ModulesState extends Equatable {
  const ModulesState({
    this.status = ModulesStatus.loading,
    this.modules = const [],
    this.types = const [],
    this.error,
  });

  final ModulesStatus status;
  final List<OperationalModule> modules;

  /// Types available when creating — also the source of the "no types defined
  /// yet" message on an empty system.
  final List<ModuleType> types;
  final String? error;

  List<OperationalModule> get active =>
      modules.where((m) => m.isActive).toList();

  /// Only managers ever receive these rows; RLS filters them out for everyone
  /// else, so no extra permission check is needed to render the section.
  List<OperationalModule> get drafts =>
      modules.where((m) => !m.isActive).toList();

  /// The types that could still be opened in [seasonId]. A file exists at most
  /// once per season, so a type already used there is not offered again.
  List<ModuleType> typesAvailableIn(String seasonId) {
    final taken = {
      for (final m in modules)
        if (m.seasonId == seasonId) m.moduleTypeId,
    };
    return types.where((t) => !taken.contains(t.id)).toList();
  }

  @override
  List<Object?> get props => [status, modules, types, error];
}

class ModulesCubit extends Cubit<ModulesState> {
  ModulesCubit(this._repo) : super(const ModulesState()) {
    load();
  }

  final ModulesRepository _repo;

  Future<void> load() async {
    emit(const ModulesState(status: ModulesStatus.loading));
    try {
      final modules = await _repo.fetchModules();
      final types = await _repo.fetchModuleTypes();
      emit(
        ModulesState(
          status: ModulesStatus.ready,
          modules: modules,
          types: types,
        ),
      );
    } catch (e) {
      emit(ModulesState(status: ModulesStatus.error, error: e.toString()));
    }
  }
}
