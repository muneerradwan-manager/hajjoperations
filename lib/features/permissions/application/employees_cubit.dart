import 'package:equatable/equatable.dart';

import '../../../core/bloc/safe_cubit.dart';
import '../../../core/utils/arabic_search.dart';
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
    // Folded on both sides, like every other directory in the app: احمد must
    // find أحمد here too.
    final q = foldArabic(query.trim());
    return employees
        .where((e) => foldArabic(e.fullName).contains(q))
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

class EmployeesCubit extends SafeCubit<EmployeesState> {
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
