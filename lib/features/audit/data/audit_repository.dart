import '../../../core/supabase/supabase_client.dart';
import '../domain/audit_event.dart';

class AuditRepository {
  /// One page of the log, newest first.
  ///
  /// Keyset-paged on the id ([beforeId]) rather than offset-paged: the log
  /// grows at the top while it is being read, and "the next 50 after the last
  /// one I have" stays correct where "rows 50–100" slides.
  Future<List<AuditEvent>> fetchEvents({
    int limit = 50,
    int? beforeId,
    String? actorId,
    List<String>? actions,
    List<String>? tables,
    DateTime? from,
    DateTime? to,
    String? query,
  }) async {
    final rows = await supabase.rpc(
      'audit_events',
      params: {
        'p_limit': limit,
        'p_before_id': beforeId,
        'p_actor_id': actorId,
        'p_actions': actions,
        'p_tables': tables,
        'p_from': from?.toUtc().toIso8601String(),
        'p_to': to?.toUtc().toIso8601String(),
        'p_query': query,
      },
    );
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(AuditEvent.fromMap)
        .toList();
  }

  /// Everyone who has ever done anything — the "by person" filter's options.
  Future<List<AuditActor>> fetchActors() async {
    final rows = await supabase.rpc('audit_actors');
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(AuditActor.fromMap)
        .toList();
  }
}
