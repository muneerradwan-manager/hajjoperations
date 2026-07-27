import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/storage_key.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/app_notification.dart';

class NotificationsRepository {
  static const _bucket = 'notifications';

  /// Realtime stream of the signed-in user's notifications, newest first.
  ///
  /// Attachments are not in it: a Supabase stream is a single table and cannot
  /// carry a joined one. [fetchAttachments] fills them in after each emission.
  Stream<List<AppNotification>> streamMine() {
    final uid = supabase.auth.currentUser?.id;
    return supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', uid ?? '')
        .order('created_at')
        .map((rows) {
          final list = rows.map(AppNotification.fromMap).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// One read of the inbox, newest first.
  ///
  /// The stream is the usual source, but it only re-reads when Realtime says
  /// something changed. This is what pull-to-refresh and "I just sent that"
  /// call, so the list is right even when the socket is not.
  Future<List<AppNotification>> fetchMine() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return const [];
    final rows = await supabase
        .from('notifications')
        .select()
        .eq('recipient_id', uid)
        .order('created_at', ascending: false);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(AppNotification.fromMap)
        .toList();
  }

  /// The attachments of [groupIds], keyed by group. One query for the whole
  /// inbox rather than one per row.
  ///
  /// Keyed on the GROUP because a broadcast is one upload read by everyone it
  /// went to — five hundred recipients share one file, not five hundred copies.
  Future<Map<String, List<NotificationAttachment>>> fetchAttachments(
    List<String> groupIds,
  ) async {
    if (groupIds.isEmpty) return const {};
    final rows = await supabase
        .from('notification_attachments')
        .select()
        .inFilter('group_id', groupIds)
        .order('sort_order');

    final byGroup = <String, List<NotificationAttachment>>{};
    for (final row in (rows as List).cast<Map<String, dynamic>>()) {
      (byGroup[row['group_id'] as String] ??= []).add(
        NotificationAttachment.fromMap(row),
      );
    }
    return byGroup;
  }

  /// A short-lived link to an attachment. Signing goes through RLS, so nobody
  /// but the recipient can mint one.
  ///
  /// [download] asks storage to serve it as a download named [downloadName]
  /// rather than rendering it in place — which is the difference between
  /// "open the photo" and "save the photo".
  Future<String> signedUrl(
    String path, {
    int expiresInSeconds = 3600,
    bool download = false,
    String? downloadName,
  }) {
    return supabase.storage
        .from(_bucket)
        .createSignedUrl(path, expiresInSeconds)
        .then((url) {
          if (!download) return url;
          // Storage honours a `download` query parameter, and its value becomes
          // the file name the device saves it under.
          final separator = url.contains('?') ? '&' : '?';
          final name = Uri.encodeComponent(downloadName ?? '');
          return '$url${separator}download${name.isEmpty ? '' : '=$name'}';
        });
  }

  Future<void> markRead(String id) async {
    await supabase
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .filter('read_at', 'is', null);
  }

  Future<void> markAllRead() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    await supabase
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('recipient_id', uid)
        .filter('read_at', 'is', null);
  }

  /// Sends a notification to [recipientId], with whatever was attached to it.
  ///
  /// The row is created first: the files are filed under its id, so it has to
  /// exist before they can go anywhere. Also invokes the push Edge Function —
  /// best-effort, the inbox row is the source of truth.
  Future<void> send({
    required String recipientId,
    required String title,
    String? body,
    List<PendingAttachment> attachments = const [],
  }) async {
    final senderId = supabase.auth.currentUser?.id;
    final row = await supabase
        .from('notifications')
        .insert({
          'recipient_id': recipientId,
          'sender_id': senderId,
          'title': title,
          'body': body,
        })
        .select('id, group_id')
        .single();
    final id = row['group_id'] as String;

    if (attachments.isNotEmpty) {
      final rows = <Map<String, dynamic>>[];
      for (var i = 0; i < attachments.length; i++) {
        final attachment = attachments[i];
        // Prefixed with the index: two photos straight from a camera roll can
        // arrive with the same name, and the second must not replace the first.
        final path = '$id/${i}_${storageKey(attachment.name, fallback: '$i')}';
        await supabase.storage
            .from(_bucket)
            .upload(
              path,
              attachment.file,
              fileOptions: FileOptions(
                upsert: true,
                contentType: attachment.mimeType,
              ),
            );
        rows.add({
          'group_id': id,
          'kind': attachment.kind.name,
          'path': path,
          'name': attachment.name,
          'mime_type': attachment.mimeType,
          'size_bytes': attachment.file.lengthSync(),
          'sort_order': i,
        });
      }
      await supabase.from('notification_attachments').insert(rows);
    }

    await _push({'recipient_id': recipientId, 'title': title, 'body': body});
  }

  /// Sends to everyone holding a role anywhere in [moduleId].
  ///
  /// The inbox rows are written by one statement inside the database, and the
  /// push is one call to the file topic. Neither cost grows with the number of
  /// members, which at five hundred is the whole point.
  Future<void> broadcastToModule({
    required String moduleId,
    required String title,
    String? body,
    List<PendingAttachment> attachments = const [],
  }) async {
    final groupId =
        await supabase.rpc(
              'broadcast_to_module',
              params: {
                'p_module_id': moduleId,
                'p_title': title,
                'p_body': body,
              },
            )
            as String;

    await _uploadAttachments(groupId, attachments);
    await _push({
      'topic': PushTopics.module(moduleId),
      'title': title,
      'body': body,
    });
  }

  /// Sends to every working account, or to one season's participants.
  Future<void> broadcastToAll({
    required String title,
    String? body,
    String? seasonId,
    List<PendingAttachment> attachments = const [],
  }) async {
    final groupId =
        await supabase.rpc(
              'broadcast_to_all',
              params: {
                'p_title': title,
                'p_body': body,
                'p_season_id': seasonId,
              },
            )
            as String;

    await _uploadAttachments(groupId, attachments);
    await _push({'topic': PushTopics.all, 'title': title, 'body': body});
  }

  /// Uploads once, under the group. Every recipient reads the same file.
  Future<void> _uploadAttachments(
    String groupId,
    List<PendingAttachment> attachments,
  ) async {
    if (attachments.isEmpty) return;
    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < attachments.length; i++) {
      final attachment = attachments[i];
      // Prefixed with the index: two photos straight from a camera roll can
      // arrive with the same name, and the second must not replace the first.
      final path = '$groupId/${i}_${storageKey(attachment.name, fallback: '$i')}';
      await supabase.storage
          .from(_bucket)
          .upload(
            path,
            attachment.file,
            fileOptions: FileOptions(
              upsert: true,
              contentType: attachment.mimeType,
            ),
          );
      rows.add({
        'group_id': groupId,
        'kind': attachment.kind.name,
        'path': path,
        'name': attachment.name,
        'mime_type': attachment.mimeType,
        'size_bytes': attachment.file.lengthSync(),
        'sort_order': i,
      });
    }
    await supabase.from('notification_attachments').insert(rows);
  }

  /// Best effort, always: the inbox row is the source of truth and a failed
  /// push must never lose the message.
  Future<void> _push(Map<String, dynamic> body) async {
    try {
      await supabase.functions.invoke('send-notification', body: body);
    } catch (_) {}
  }
}

/// The FCM topics this app uses. Kept beside the sender so the name a broadcast
/// pushes to and the name a device subscribes to cannot drift apart.
class PushTopics {
  const PushTopics._();

  static const all = 'all';

  static String module(String moduleId) => 'module_$moduleId';
}
