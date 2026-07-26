import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../profile/domain/profile.dart';
import '../data/employees_repository.dart';

enum DirectoryStatus { loading, loaded, error }

class EmployeesDirectoryState extends Equatable {
  const EmployeesDirectoryState({
    this.status = DirectoryStatus.loading,
    this.permanent = const [],
    this.external = const [],
    this.error,
  });

  final DirectoryStatus status;
  final List<Profile> permanent;
  final List<Profile> external;
  final String? error;

  EmployeesDirectoryState copyWith({
    DirectoryStatus? status,
    List<Profile>? permanent,
    List<Profile>? external,
    String? error,
  }) {
    return EmployeesDirectoryState(
      status: status ?? this.status,
      permanent: permanent ?? this.permanent,
      external: external ?? this.external,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, permanent, external, error];
}

class EmployeesDirectoryCubit extends Cubit<EmployeesDirectoryState> {
  EmployeesDirectoryCubit(this._repo) : super(const EmployeesDirectoryState()) {
    load();
  }

  final EmployeesRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: DirectoryStatus.loading));
    try {
      final results = await Future.wait([
        _repo.fetchPermanent(),
        _repo.fetchExternal(),
      ]);
      emit(
        state.copyWith(
          status: DirectoryStatus.loaded,
          permanent: results[0],
          external: results[1],
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: DirectoryStatus.error, error: e.toString()));
    }
  }
}
