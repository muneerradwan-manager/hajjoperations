import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repo) : super(const NotificationsState()) {
    _sub = _repo.streamMine().listen(
      _onNotifications,
      onError: (_) => emit(state.copyWith(loading: false)),
    );
  }

  final NotificationsRepository _repo;
  late final StreamSubscription<List<AppNotification>> _sub;

  /// The list lands first and the attachments follow, in one query for the
  /// whole inbox. Shown straight away rather than held back: the title and the
  /// body are the notification, and a photo arriving a moment later is a photo
  /// arriving a moment later.
  Future<void> _onNotifications(List<AppNotification> items) async {
    emit(state.copyWith(items: items, loading: false));
    if (items.isEmpty) return;
    try {
      final byNotification = await _repo.fetchAttachments([
        for (final n in items) n.id,
      ]);
      if (isClosed || byNotification.isEmpty) return;
      emit(
        state.copyWith(
          items: [
            for (final n in items)
              n.withAttachments(byNotification[n.id] ?? const []),
          ],
        ),
      );
    } catch (_) {
      // The inbox is already on screen; attachments simply do not appear.
    }
  }

  Future<void> markRead(String id) => _repo.markRead(id);
  Future<void> markAllRead() => _repo.markAllRead();

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
