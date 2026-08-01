import 'dart:async';

import 'package:equatable/equatable.dart';

import '../../../core/bloc/safe_cubit.dart';
import '../data/notifications_repository.dart';
import '../domain/app_notification.dart';

class NotificationsState extends Equatable {
  const NotificationsState({this.items = const [], this.loading = true});

  final List<AppNotification> items;
  final bool loading;

  int get unread => items.where((n) => !n.isRead).length;

  NotificationsState copyWith({List<AppNotification>? items, bool? loading}) {
    return NotificationsState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [items, loading];
}

class NotificationsCubit extends SafeCubit<NotificationsState> {
  NotificationsCubit(this._repo) : super(const NotificationsState()) {
    _sub = _repo.streamMine().listen(
      _onNotifications,
      onError: (_) => emit(state.copyWith(loading: false)),
    );
  }

  final NotificationsRepository _repo;
  late final StreamSubscription<List<AppNotification>> _sub;

  /// Attachments already fetched, by group. A broadcast's file does not change
  /// once sent, so there is no reason to ask for it again on every Realtime
  /// emission — only groups this cubit has not seen yet go over the wire.
  final _attachmentsByGroup = <String, List<NotificationAttachment>>{};

  /// Bumped by every emission and every optimistic write. An attachment fetch
  /// that comes back late checks it before emitting: without this, its
  /// captured snapshot overwrote whatever happened during the await — a tapped
  /// notification turned unread again, a just-arrived one vanished.
  int _generation = 0;

  /// The list lands first and the attachments follow, in one query for the
  /// whole inbox. Shown straight away rather than held back: the title and the
  /// body are the notification, and a photo arriving a moment later is a photo
  /// arriving a moment later.
  Future<void> _onNotifications(List<AppNotification> items) async {
    final generation = ++_generation;
    emit(state.copyWith(items: _withKnownAttachments(items), loading: false));
    if (items.isEmpty) return;

    final missing = [
      for (final n in items)
        if (!_attachmentsByGroup.containsKey(n.groupId)) n.groupId,
    ];
    if (missing.isEmpty) return;

    try {
      final byGroup = await _repo.fetchAttachments(missing);
      for (final id in missing) {
        _attachmentsByGroup[id] = byGroup[id] ?? const [];
      }
      if (isClosed || generation != _generation) return;
      emit(state.copyWith(items: _withKnownAttachments(state.items)));
    } catch (_) {
      // The inbox is already on screen; attachments simply do not appear.
    }
  }

  List<AppNotification> _withKnownAttachments(List<AppNotification> items) => [
    for (final n in items)
      _attachmentsByGroup[n.groupId] == null
          ? n
          : n.withAttachments(_attachmentsByGroup[n.groupId]!),
  ];

  /// Re-reads the inbox now. The stream covers the normal case; this covers
  /// the two it does not — a pull-to-refresh, and having just sent something to
  /// yourself, where waiting on a socket to tell you what you already know
  /// reads as the app being broken.
  Future<void> refresh() async {
    try {
      await _onNotifications(await _repo.fetchMine());
    } catch (_) {
      // The list on screen stays; it is not worse than it was.
    }
  }

  /// Marks one as read, on screen first.
  ///
  /// The write took the better part of three seconds on a slow connection, and
  /// waiting for it — or for Realtime to report it back — left the tap looking
  /// like it had done nothing. So the state moves now and the server catches
  /// up; if the write fails, a re-read puts the truth back.
  Future<void> markRead(String id) async {
    _generation++;
    emit(
      state.copyWith(
        items: [
          for (final n in state.items)
            if (n.id == id) n.markedRead() else n,
        ],
      ),
    );
    try {
      await _repo.markRead(id);
    } catch (_) {
      await refresh();
    }
  }

  Future<void> markAllRead() async {
    _generation++;
    emit(
      state.copyWith(items: [for (final n in state.items) n.markedRead()]),
    );
    try {
      await _repo.markAllRead();
    } catch (_) {
      await refresh();
    }
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
