import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/bloc/safe_cubit.dart';
import '../../../core/constants/permission_codes.dart';
import '../../notifications/data/push_service.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/profile.dart';
import '../../profile/domain/profile_enums.dart';
import '../data/auth_repository.dart';

enum SessionStatus {
  unknown,
  unauthenticated,
  incomplete, // signed in, profile not yet submitted
  pending,
  rejected,
  suspended,
  approved,
}

class SessionState extends Equatable {
  const SessionState({
    this.status = SessionStatus.unknown,
    this.profile,
    this.permissions = const {},
  });

  final SessionStatus status;
  final Profile? profile;
  final Set<String> permissions;

  bool get isAdmin => profile?.isAdmin ?? false;
  bool can(String code) => isAdmin || permissions.contains(code);

  /// Whether seasons are this person's business at all — the section itself, or
  /// either of the two things one can do inside it.
  ///
  /// A getter rather than a check written out at each call site, because it is
  /// asked in two places that must not drift: the dashboard decides whether to
  /// show the door, and the router decides whether the door opens. A rule kept
  /// in one of those places only is decoration.
  ///
  /// All three codes are asked. The permissions editor grants the section
  /// before it will show the actions, but nothing in the database enforces that
  /// order, and a row written any other way still means this person works with
  /// seasons.
  bool get canSeeSeasons =>
      can(PermissionCodes.seasons) ||
      can(PermissionCodes.seasonsManage) ||
      can(PermissionCodes.seasonsParticipants);

  SessionState copyWith({
    SessionStatus? status,
    Profile? profile,
    Set<String>? permissions,
  }) {
    return SessionState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      permissions: permissions ?? this.permissions,
    );
  }

  @override
  List<Object?> get props => [status, profile, permissions];
}

/// Owns the app's authenticated session: reacts to Supabase auth events,
/// loads the profile, and derives the routing status.
class SessionCubit extends SafeCubit<SessionState> {
  SessionCubit(this._auth, this._profiles) : super(const SessionState()) {
    _sub = _auth.authStateChanges.listen(_onAuthChanged);
    // Handle a session that already exists at startup.
    if (_auth.currentUser != null) {
      reload();
    } else {
      emit(const SessionState(status: SessionStatus.unauthenticated));
    }
  }

  final AuthRepository _auth;
  final ProfileRepository _profiles;
  late final StreamSubscription<AuthState> _sub;

  Future<void> _onAuthChanged(AuthState event) async {
    if (event.session == null) {
      emit(const SessionState(status: SessionStatus.unauthenticated));
    } else {
      await reload();
    }
  }

  /// Re-fetch the profile and permissions and recompute status.
  Future<void> reload() async {
    if (_auth.currentUser == null) {
      emit(const SessionState(status: SessionStatus.unauthenticated));
      return;
    }

    final profile = await _profiles.fetchMine();
    if (profile == null) {
      // Row may not be visible for a beat right after signup; treat as incomplete.
      emit(const SessionState(status: SessionStatus.incomplete));
      return;
    }

    final status = switch (profile.accountStatus) {
      AccountStatus.incomplete => SessionStatus.incomplete,
      AccountStatus.pending => SessionStatus.pending,
      AccountStatus.rejected => SessionStatus.rejected,
      AccountStatus.approved =>
        profile.isSuspended ? SessionStatus.suspended : SessionStatus.approved,
    };

    Set<String> permissions = const {};
    if (status == SessionStatus.approved && !profile.isAdmin) {
      permissions = await _loadPermissions();
    }

    emit(
      SessionState(status: status, profile: profile, permissions: permissions),
    );

    // Register this device for push once the user has full access.
    if (status == SessionStatus.approved) {
      unawaited(PushService.instance.start());
    }
  }

  Future<Set<String>> _loadPermissions() async {
    try {
      final rows = await Supabase.instance.client.rpc('my_permissions');
      return (rows as List).map((e) => e as String).toSet();
    } catch (_) {
      return const {};
    }
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
