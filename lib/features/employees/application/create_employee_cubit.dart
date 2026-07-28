import 'package:equatable/equatable.dart';

import '../../../core/bloc/safe_cubit.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/job_title.dart';
import '../../profile/domain/profile_enums.dart';
import '../data/employees_repository.dart';

enum CreateEmployeeStatus { loading, ready, submitting, created, error }

class CreateEmployeeState extends Equatable {
  const CreateEmployeeState({
    this.status = CreateEmployeeStatus.loading,
    this.jobTitles = const [],
    this.error,
  });

  final CreateEmployeeStatus status;
  final List<JobTitle> jobTitles;
  final String? error;

  CreateEmployeeState copyWith({
    CreateEmployeeStatus? status,
    List<JobTitle>? jobTitles,
    String? error,
  }) {
    return CreateEmployeeState(
      status: status ?? this.status,
      jobTitles: jobTitles ?? this.jobTitles,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, jobTitles, error];
}

class CreateEmployeeCubit extends SafeCubit<CreateEmployeeState> {
  CreateEmployeeCubit(this._employees, this._profiles)
    : super(const CreateEmployeeState()) {
    _load();
  }

  final EmployeesRepository _employees;
  final ProfileRepository _profiles;

  Future<void> _load() async {
    emit(state.copyWith(status: CreateEmployeeStatus.loading));
    try {
      final titles = await _profiles.fetchActiveJobTitles();
      emit(
        state.copyWith(status: CreateEmployeeStatus.ready, jobTitles: titles),
      );
    } catch (e) {
      emit(
        state.copyWith(status: CreateEmployeeStatus.error, error: e.toString()),
      );
    }
  }

  Future<void> submit({
    required String email,
    required String password,
    required String firstName,
    required String fatherName,
    required String surname,
    required String jobTitleId,
    required Gender gender,
    required DateTime dateOfBirth,
    required MissionType missionType,
    required String phoneSy,
    String? phoneSa,
    bool isExternal = false,
    String? externalOrganization,
    String? externalTitle,
  }) async {
    emit(state.copyWith(status: CreateEmployeeStatus.submitting));
    try {
      await _employees.createEmployee(
        email: email,
        password: password,
        firstName: firstName,
        fatherName: fatherName,
        surname: surname,
        jobTitleId: jobTitleId,
        gender: gender,
        dateOfBirth: dateOfBirth,
        missionType: missionType,
        phoneSy: phoneSy,
        phoneSa: phoneSa,
        isExternal: isExternal,
        externalOrganization: externalOrganization,
        externalTitle: externalTitle,
      );
      emit(state.copyWith(status: CreateEmployeeStatus.created));
    } catch (e) {
      emit(
        state.copyWith(status: CreateEmployeeStatus.ready, error: e.toString()),
      );
    }
  }
}
