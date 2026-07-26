import '../../../core/supabase/supabase_client.dart';
import '../domain/app_notification.dart';

class NotificationsRepository {
  /// Realtime stream of the signed-in user's notifications, newest first.
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

  /// Sends a notification to [recipientId]. Also invokes the push Edge Function
  /// (best-effort — the inbox row is the source of truth).
  Future<void> send({
    required String recipientId,
    required String title,
    String? body,
  }) async {
    final senderId = supabase.auth.currentUser?.id;
    await supabase.from('notifications').insert({
      'recipient_id': recipientId,
      'sender_id': senderId,
      'title': title,
      'body': body,
    });
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
