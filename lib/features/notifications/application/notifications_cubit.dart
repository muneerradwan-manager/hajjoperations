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
    _sub = _repo.streamMine().listen((items) {
      emit(state.copyWith(items: items, loading: false));
    }, onError: (_) => emit(state.copyWith(loading: false)));
  }

  final NotificationsRepository _repo;
  late final StreamSubscription<List<AppNotification>> _sub;

  Future<void> markRead(String id) => _repo.markRead(id);
  Future<void> markAllRead() => _repo.markAllRead();

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
