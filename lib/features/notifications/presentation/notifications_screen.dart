import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/responsive.dart';
import '../../auth/application/session_cubit.dart';
import '../../modules/data/modules_repository.dart';
import '../../modules/presentation/module_detail_screen.dart';
import '../application/notifications_cubit.dart';
import '../data/notifications_repository.dart';
import '../data/push_service.dart';
import '../domain/app_notification.dart';
import 'send_notification_sheet.dart';
import '../../../core/attachments/attachments_view.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = NotificationsRepository();
    return BlocProvider(
      create: (_) => NotificationsCubit(repo),
      // The same instance the cubit reads through: signing an attachment URL
      // goes through it too, and it holds nothing worth having twice.
      child: _View(repo: repo),
    );
  }
}

class _View extends StatefulWidget {
  const _View({required this.repo});

  final NotificationsRepository repo;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  NotificationsRepository get repo => widget.repo;

  @override
  void initState() {
    super.initState();

    // Arriving here from a notification tapped in the phone's own tray. The
    // tap named a file, so opening the inbox is only half of what was asked
    // for — the reader pressed a sentence about a place.
    //
    // Waited for a frame because opening it may fail: the file can have been
    // deleted since, and saying so needs a Scaffold that exists.
    final tap = PushService.instance.takePendingTap();
    final moduleId = tap == null ? null : AppNotification.moduleIdIn(tap);
    if (moduleId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openModule(context, moduleId);
    });
  }

  /// Mark it read, and take the reader to what it is about.
  ///
  /// "تم إسنادك إلى ملف تشغيلي" is a sentence about a place, and the reader's
  /// next move is always to go and look at it. So the tap goes there — but only
  /// after asking whether it is still there to go to.
  ///
  /// The file may be gone: deleted since, or deactivated, or the reader taken
  /// off it. All three come back as nothing, and all three mean the same thing
  /// to whoever is tapping — so they get one honest sentence rather than a
  /// screen that opens onto an error. The notification itself stays; it is a
  /// record of something that happened, and it happened.
  Future<void> _open(BuildContext context, AppNotification n) async {
    final cubit = context.read<NotificationsCubit>();
    if (!n.isRead) cubit.markRead(n.id);

    final moduleId = n.moduleId;
    if (moduleId == null) return;
    await _openModule(context, moduleId);
  }

  /// Opens a file a notification pointed at, from either door: a row tapped in
  /// this list, or the notification tapped in the phone's tray that opened the
  /// app on this list. Both are the same act and must not drift apart.
  Future<void> _openModule(BuildContext context, String moduleId) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final module = await ModulesRepository().fetchModule(moduleId);
    if (module == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.notificationTargetGone)));
      return;
    }
    // Not `fromOffice`: arriving from an inbox is not arriving through إدارة
    // الملفات, so the file opens to be read rather than to be edited.
    navigator.push(
      fadeThroughRoute((_) => ModuleDetailScreen(moduleId: moduleId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      floatingActionButton:
          context.watch<SessionCubit>().state.canSendAnyNotification
          ? Builder(
              builder: (context) => FloatingActionButton.extended(
                onPressed: () async {
                  final cubit = context.read<NotificationsCubit>();
                  await showSendNotificationSheet(context);
                  // A broadcast reaches the sender too, and it should appear
                  // without waiting to be told about it.
                  await cubit.refresh();
                },
                icon: const Icon(AppIcons.send),
                label: Text(l.notificationSend),
              ),
            )
          : null,
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
        child: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.items.isEmpty) {
              return _Empty(message: l.notificationsEmpty);
            }
            // Two columns at most, and the page stops at 1200 — narrower than
            // any other list here. These cards hold sentences somebody wrote,
            // not fields; a notification stretched across a monitor is a line
            // of prose two feet long, and the eye loses the next one on the way
            // back. Twice as many messages on the screen is the whole gain
            // available, and it is worth having.
            return ResponsivePage(
              maxWidth: 1200,
              builder: (context, size) => AdaptiveGridView(
                padding: EdgeInsets.fromLTRB(
                  size.gutter,
                  12,
                  size.gutter,
                  24 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                onRefresh: () => context.read<NotificationsCubit>().refresh(),
                minTileWidth: 380,
                maxColumns: 2,
                spacing: 10,
                itemCount: state.items.length,
                itemBuilder: (context, i) {
                  final n = state.items[i];
                  return FadeSlideIn(
                    delay: Duration(milliseconds: 25 * i),
                    child: _NotificationCard(
                      notification: n,
                      repo: repo,
                      // Tappable whenever there is something to do — opening
                      // what it is about, marking it read, or both. A notice
                      // already read still points at its file, so being read
                      // must not make it inert.
                      onTap: (n.isRead && !n.hasTarget)
                          ? null
                          : () => _open(context, n),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.repo,
    this.onTap,
  });

  final AppNotification notification;
  final NotificationsRepository repo;
  final VoidCallback? onTap;

  /// Whether this card leads anywhere, which decides the chevron. Tapping to
  /// mark something read is not "leading somewhere" — the card stays put.

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
                  AttachmentsView(
                    attachments: notification.attachments,
                    signer: repo.signedUrl,
                  ),
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
            // Says the card goes somewhere. Without it the only way to find
            // out is to tap, and half of these cards go nowhere — a broadcast
            // names no place to open.
            if (notification.hasTarget)
              Padding(
                padding: EdgeInsetsDirectional.only(start: unread ? 6 : 0),
                child: const NavChevron(),
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
