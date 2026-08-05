import '../../../core/supabase/supabase_client.dart';
import '../domain/check_in.dart';

/// Reporting that somebody arrived, and reading back who has.
///
/// Both go through RPCs rather than through the table: the distance between
/// where a man says he is and where the file says the place is has to be
/// measured by the database, or it is not evidence of anything. See 0087.
class CheckInRepository {
  /// Files an arrival. Returns the id of the row.
  ///
  /// [latitude] and [longitude] are what the phone was willing to say and may
  /// be absent — permission refused, or no fix inside a metal camp. That is a
  /// fact about the check-in rather than a reason to refuse it.
  Future<String> checkIn({
    required String moduleId,
    String? nodeId,
    required CheckInMethod method,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? note,
  }) async {
    final id = await supabase.rpc(
      'check_in_here',
      params: {
        'p_module_id': moduleId,
        'p_node_id': nodeId,
        'p_method': method.dbName,
        'p_lat': latitude,
        'p_lng': longitude,
        'p_accuracy': accuracy,
        'p_note': note,
      },
    );
    return id as String;
  }

  /// Who is where in this file, latest arrival per person per place.
  ///
  /// [since] decides what "now" means and is the caller's to choose: an evening
  /// inspection wants today, a night in Mina wants the last few hours. Left off,
  /// the database uses twelve hours.
  Future<List<PresenceLine>> fetchPresence({
    required String moduleId,
    DateTime? since,
  }) async {
    final rows = await supabase.rpc(
      'module_presence',
      params: {
        'p_module_id': moduleId,
        'p_since': since?.toUtc().toIso8601String(),
      },
    );
    return ((rows as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_lineFromRow)
        .toList();
  }

  static PresenceLine _lineFromRow(Map<String, dynamic> map) => PresenceLine(
    id: map['check_in_id'] as String,
    profileId: map['profile_id'] as String,
    fullName: (map['full_name'] as String?) ?? '',
    method: CheckInMethod.fromDb(map['method'] as String?),
    createdAt:
        DateTime.tryParse(map['created_at'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    nodeId: map['node_id'] as String?,
    nodeLabel: map['node_label'] as String?,
    distanceM: (map['distance_m'] as num?)?.toDouble(),
    accuracyM: (map['accuracy_m'] as num?)?.toDouble(),
    note: map['note'] as String?,
  );
}
