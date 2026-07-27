import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../domain/app_notification.dart';

/// One file chosen to go out with a notification, before it has been uploaded.
class PendingAttachment {
  const PendingAttachment({
    required this.file,
    required this.name,
    required this.kind,
    this.mimeType,
  });

  final File file;
  final String name;
  final AttachmentKind kind;
  final String? mimeType;
}

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

  /// The attachments of [notificationIds], grouped by notification. One query
  /// for the whole inbox rather than one per row.
  Future<Map<String, List<NotificationAttachment>>> fetchAttachments(
    List<String> notificationIds,
  ) async {
    if (notificationIds.isEmpty) return const {};
    final rows = await supabase
        .from('notification_attachments')
        .select()
        .inFilter('notification_id', notificationIds)
        .order('sort_order');

    final byNotification = <String, List<NotificationAttachment>>{};
    for (final row in (rows as List).cast<Map<String, dynamic>>()) {
      (byNotification[row['notification_id'] as String] ??= []).add(
        NotificationAttachment.fromMap(row),
      );
    }
    return byNotification;
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
        .select('id')
        .single();
    final id = row['id'] as String;

    if (attachments.isNotEmpty) {
      final rows = <Map<String, dynamic>>[];
      for (var i = 0; i < attachments.length; i++) {
        final attachment = attachments[i];
        // Prefixed with the index: two photos straight from a camera roll can
        // arrive with the same name, and the second must not replace the first.
        final path = '$id/${i}_${attachment.name}';
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
          'notification_id': id,
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

    try {
      await supabase.functions.invoke(
        'send-notification',
        body: {'recipient_id': recipientId, 'title': title, 'body': body},
      );
    } catch (_) {
      // Push is best-effort; the in-app notification was already stored.
    }
  }
}
