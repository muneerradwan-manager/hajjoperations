import 'package:flutter/foundation.dart';

import '../../../core/supabase/supabase_client.dart';
import '../domain/check_in.dart';

/// Chooses, from every node of one file, the ones worth offering as "here".
///
/// Separated from the fetch because it is the whole of the judgement and none
/// of the network: the first version of it asked only `is_place` and so came
/// back empty for المدينة, whose file is organised by service company. Empty is
/// indistinguishable on screen from a query that failed, which is how it took a
/// second report to find.
@visibleForTesting
List<({String id, String name})> checkInTargetsFrom(
  List<Map<String, dynamic>> rows,
) {
  if (rows.isEmpty) return const [];

  int depthOf(Map<String, dynamic> row) =>
      ((row['module_type_levels'] as Map?)?['depth'] as int?) ?? 0;
  bool isPlace(Map<String, dynamic> row) =>
      ((row['module_type_levels'] as Map?)?['is_place'] as bool?) ?? false;

  var offered = rows.where(isPlace).toList();
  if (offered.isEmpty) {
    // The innermost rung this file actually fills. Innermost rather than
    // outermost because it is the narrower claim: "the fourth company" tells
    // the room more than "the file" does.
    final deepest = rows.map(depthOf).reduce((a, b) => a > b ? a : b);
    offered = rows.where((row) => depthOf(row) == deepest).toList();
  }

  return [
    for (final row in offered)
      (
        id: row['id'] as String,
        // Named by hand in منى, drawn from a list in عرفات and مكة. Either way
        // the reader needs the name he knows it by.
        name:
            (row['label'] as String?) ??
            ((row['reference_items'] as Map?)?['name_ar'] as String?) ??
            '',
      ),
  ];
}

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

  /// What a person can name as the HERE of "I am here", in one file.
  ///
  /// Offered when there is no code to scan, so that the check-in carries
  /// something: without it the only thing the app could send was the file
  /// itself, which the register cannot draw, cannot count, and cannot show
  /// anybody looking for the man.
  ///
  /// Places first — the levels 0089 marks as somewhere a person stands and a
  /// sticker is screwed on. But `is_place` answers a narrower question than
  /// this one. It governs where CODES are printed, and it is deliberately false
  /// for شركة الخدمة in المدينة, because a company is not a building and a code
  /// on it would name nothing.
  ///
  /// That is right for printing and wrong here. Asked "where are you", a man in
  /// المدينة can still answer "with such-and-such company" — less than a
  /// building, far more than nothing, and enough for the room to find him. So
  /// when a file has no places at all, the innermost level it does have stands
  /// in. Reading `is_place` as the whole answer is what left the sheet blank
  /// for those files and the button dead-ending on the server's refusal.
  ///
  /// A file with no nodes whatsoever comes back empty, and that is honest: it
  /// has nothing to name, and only the position can carry the check-in.
  Future<List<({String id, String name})>> fetchCheckInTargets(
    String moduleId,
  ) async {
    // One query for the whole tree rather than two round trips, because the
    // fallback is only known after seeing whether any place came back — and a
    // man standing at a gate should not wait twice.
    final rows = await supabase
        .from('module_nodes')
        .select(
          'id, label, sort_order, '
          'reference_items(name_ar), '
          'module_type_levels!inner(depth, is_place)',
        )
        .eq('module_id', moduleId)
        .order('sort_order');

    return checkInTargetsFrom((rows as List).cast<Map<String, dynamic>>());
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
