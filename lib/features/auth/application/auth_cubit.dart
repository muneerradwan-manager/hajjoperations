import 'package:equatable/equatable.dart';

import '../../../core/bloc/safe_cubit.dart';
import '../data/auth_repository.dart';

enum AuthStatus { idle, submitting, emailConfirmationSent, error }

class AuthUiState extends Equatable {
  const AuthUiState({this.status = AuthStatus.idle, this.error});

  final AuthStatus status;
  final String? error;

  bool get isSubmitting => status == AuthStatus.submitting;

  @override
  List<Object?> get props => [status, error];
}

/// Handles the sign-in / sign-up / Google actions on the auth screens.
/// The [SessionCubit] reacts to the resulting auth state change separately.
class AuthCubit extends SafeCubit<AuthUiState> {
  AuthCubit(this._repo) : super(const AuthUiState());

  final AuthRepository _repo;

  Future<void> signIn(String email, String password) async {
    emit(const AuthUiState(status: AuthStatus.submitting));
    try {
      await _repo.signInWithEmail(email: email, password: password);
      emit(const AuthUiState(status: AuthStatus.idle));
    } on AuthFailure catch (e) {
      emit(AuthUiState(status: AuthStatus.error, error: e.message));
    }
  }

  Future<void> signUp(String email, String password) async {
    emit(const AuthUiState(status: AuthStatus.submitting));
    try {
      await _repo.signUpWithEmail(email: email, password: password);
      // If email confirmation is enabled there is no session yet.
      if (_repo.currentUser == null) {
        emit(const AuthUiState(status: AuthStatus.emailConfirmationSent));
      } else {
        emit(const AuthUiState(status: AuthStatus.idle));
      }
    } on AuthFailure catch (e) {
      emit(AuthUiState(status: AuthStatus.error, error: e.message));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(const AuthUiState(status: AuthStatus.submitting));
    try {
      await _repo.signInWithGoogle();
      emit(const AuthUiState(status: AuthStatus.idle));
    } on AuthFailure catch (e) {
      if (e.message == 'cancelled') {
        emit(const AuthUiState(status: AuthStatus.idle));
        return;
      }
      emit(AuthUiState(status: AuthStatus.error, error: e.message));
    }
  }

  void clearError() => emit(const AuthUiState(status: AuthStatus.idle));
}
