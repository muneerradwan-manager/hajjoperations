import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/permissions_repository.dart';
import '../domain/permission.dart';

enum PermissionEditorStatus { loading, ready, error }

class PermissionEditorState extends Equatable {
  const PermissionEditorState({
    this.status = PermissionEditorStatus.loading,
    this.catalog = const [],
    this.granted = const {},
    this.busy = const {},
    this.error,
  });

  final PermissionEditorStatus status;
  final List<Permission> catalog;
  final Set<String> granted; // permission ids
  final Set<String> busy; // permission ids currently toggling
  final String? error;

  PermissionEditorState copyWith({
    PermissionEditorStatus? status,
    List<Permission>? catalog,
    Set<String>? granted,
    Set<String>? busy,
    String? error,
  }) {
    return PermissionEditorState(
      status: status ?? this.status,
      catalog: catalog ?? this.catalog,
      granted: granted ?? this.granted,
      busy: busy ?? this.busy,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, catalog, granted, busy, error];
}

/// Loads the catalog + the employee's granted set and toggles each permission,
/// writing through to the DB immediately.
class PermissionEditorCubit extends Cubit<PermissionEditorState> {
  PermissionEditorCubit(this._repo, this.userId)
    : super(const PermissionEditorState()) {
    _load();
  }

  final PermissionsRepository _repo;
  final String userId;

  Future<void> _load() async {
    emit(state.copyWith(status: PermissionEditorStatus.loading));
    try {
      final results = await Future.wait([
        _repo.fetchCatalog(),
        _repo.fetchGranted(userId),
      ]);
      emit(
        state.copyWith(
          status: PermissionEditorStatus.ready,
          catalog: results[0] as List<Permission>,
          granted: results[1] as Set<String>,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PermissionEditorStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  List<Permission> childrenOf(String parentId) =>
      state.catalog.where((p) => p.parentId == parentId).toList();

  /// Toggles a permission. Parents cascade: turning a parent off revokes all its
  /// granted children; a child can only be toggled while its parent is granted.
  Future<void> toggle(String permissionId) async {
    if (state.busy.contains(permissionId)) return;
    final perm = state.catalog.firstWhere((p) => p.id == permissionId);
    final isGranted = state.granted.contains(permissionId);

    emit(state.copyWith(busy: {...state.busy, permissionId}));
    try {
      if (perm.isParent) {
        if (isGranted) {
          // Revoke the parent and every granted child.
          final children = childrenOf(
            perm.id,
          ).where((c) => state.granted.contains(c.id)).toList();
          for (final c in children) {
            await _repo.revoke(userId, c.id);
          }
          await _repo.revoke(userId, perm.id);
          final removed = {perm.id, ...children.map((c) => c.id)};
          emit(
            state.copyWith(
              granted: state.granted.difference(removed),
              busy: state.busy.difference({permissionId}),
            ),
          );
        } else {
          await _repo.grant(userId, perm.id);
          emit(
            state.copyWith(
              granted: {...state.granted, perm.id},
              busy: state.busy.difference({permissionId}),
            ),
          );
        }
      } else {
        // Child — parent must be granted first (UI enforces this too).
        if (!isGranted &&
            perm.parentId != null &&
            !state.granted.contains(perm.parentId)) {
          emit(state.copyWith(busy: state.busy.difference({permissionId})));
          return;
        }
        if (isGranted) {
          await _repo.revoke(userId, perm.id);
          emit(
            state.copyWith(
              granted: state.granted.difference({perm.id}),
              busy: state.busy.difference({permissionId}),
            ),
          );
        } else {
          await _repo.grant(userId, perm.id);
          emit(
            state.copyWith(
              granted: {...state.granted, perm.id},
              busy: state.busy.difference({permissionId}),
            ),
          );
        }
      }
    } catch (e) {
      emit(
        state.copyWith(
          busy: state.busy.difference({permissionId}),
          error: e.toString(),
        ),
      );
    }
  }
}
