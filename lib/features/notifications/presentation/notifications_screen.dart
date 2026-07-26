import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/responsive_center.dart';
import '../application/notifications_cubit.dart';
import '../data/notifications_repository.dart';
import '../domain/app_notification.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationsCubit(NotificationsRepository()),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: GlassAppBar(
        title: Text(l.navNotifications),
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              if (state.unread == 0) return const SizedBox.shrink();
              return IconButton(
                tooltip: l.notificationMarkAllRead,
                icon: const Icon(AppIcons.selected),
                onPressed: () =>
                    context.read<NotificationsCubit>().markAllRead(),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              if (state.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.items.isEmpty) {
                return _Empty(message: l.notificationsEmpty);
              }
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  24 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                itemCount: state.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final n = state.items[i];
                  return FadeSlideIn(
                    delay: Duration(milliseconds: 25 * i),
                    child: _NotificationCard(
                      notification: n,
                      onTap: n.isRead
                          ? null
                          : () => context.read<NotificationsCubit>().markRead(
                              n.id,
                            ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, this.onTap});
  final AppNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unread = !notification.isRead;
    return GlassCard(
      onTap: onTap,
      tint: unread ? scheme.primary : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              AppIcons.notifications,
              color: unread ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (notification.body != null &&
                      notification.body!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.body!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _fmt(notification.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (unread)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: FadeSlideIn(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.notifications, size: 64, color: scheme.outline),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
