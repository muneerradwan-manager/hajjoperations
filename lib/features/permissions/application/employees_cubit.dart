import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../profile/domain/profile.dart';
import '../data/permissions_repository.dart';

enum EmployeesStatus { loading, loaded, error }

class EmployeesState extends Equatable {
  const EmployeesState({
    this.status = EmployeesStatus.loading,
    this.employees = const [],
    this.query = '',
    this.error,
  });

  final EmployeesStatus status;
  final List<Profile> employees;
  final String query;
  final String? error;

  List<Profile> get filtered {
    if (query.trim().isEmpty) return employees;
    final q = query.trim().toLowerCase();
    return employees
        .where((e) => e.fullName.toLowerCase().contains(q))
        .toList();
  }

  EmployeesState copyWith({
    EmployeesStatus? status,
    List<Profile>? employees,
    String? query,
    String? error,
  }) {
    return EmployeesState(
      status: status ?? this.status,
      employees: employees ?? this.employees,
      query: query ?? this.query,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, employees, query, error];
}

class EmployeesCubit extends Cubit<EmployeesState> {
  EmployeesCubit(this._repo) : super(const EmployeesState()) {
    load();
  }

  final PermissionsRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: EmployeesStatus.loading));
    try {
      final employees = await _repo.fetchEmployees();
      emit(
        state.copyWith(status: EmployeesStatus.loaded, employees: employees),
      );
    } catch (e) {
      emit(state.copyWith(status: EmployeesStatus.error, error: e.toString()));
    }
  }

  void search(String query) => emit(state.copyWith(query: query));
}
