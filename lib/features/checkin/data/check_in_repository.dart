import '../../../core/supabase/supabase_client.dart';
import '../domain/check_in.dart';

/// What a place's code is, and what came back when somebody used it.
typedef CheckInReceipt = ({
  String id,
  String placeName,
  double distanceM,
  double radiusM,
});

/// Filing an arrival, and reading who has arrived.
///
/// Everything goes through RPCs rather than through the tables, and for a
/// sharper reason than before 0098: the distance between where a man says he is
/// and where the master data says the place is has to be measured by the
/// database, because it now DECIDES rather than annotates. A distance the
/// client offered would be a rule the client could switch off.
class CheckInRepository {
  /// Files an arrival at a place. Throws with the server's own code on refusal.
  Future<CheckInReceipt> checkIn({
    required String itemId,
    required String secret,
    required double latitude,
    required double longitude,
    double? accuracy,
    String? note,
  }) async {
    final rows = await supabase.rpc(
      'check_in_at_place',
      params: {
        'p_item_id': itemId,
        'p_secret': secret,
        'p_lat': latitude,
        'p_lng': longitude,
        'p_accuracy': accuracy,
        'p_note': note,
      },
    );
    final row = (rows as List).cast<Map<String, dynamic>>().first;
    return (
      id: row['check_in_id'] as String,
      placeName: (row['place_name'] as String?) ?? '',
      distanceM: (row['distance_m'] as num).toDouble(),
      radiusM: (row['radius_m'] as num).toDouble(),
    );
  }

  /// Who is where, everywhere, latest per person per place.
  ///
  /// [since] decides what "now" means and is the reader's to choose: an evening
  /// inspection wants today, a night in منى wants the last few hours. Left off,
  /// the database uses twelve.
  Future<List<PresenceLine>> fetchPresence({
    DateTime? since,
    String? itemId,
  }) async {
    final rows = await supabase.rpc(
      'presence_board',
      params: {
        'p_since': since?.toUtc().toIso8601String(),
        'p_item_id': itemId,
      },
    );
    return [
      for (final row in (rows as List).cast<Map<String, dynamic>>())
        _lineFromRow(row),
    ];
  }

  /// Who is NOT where they are posted — the same fact from the other side.
  ///
  /// [within] is what "recently" means, and it defaults on the SERVER rather
  /// than here so this screen and the board cannot come to disagree about it:
  /// both leave it off and both get twelve hours.
  ///
  /// Postgres has no `interval` in JSON, so it travels as the string it parses
  /// from — `'8 hours'`. Built from the number rather than handed in as free
  /// text, because an interval that arrives as a sentence is one an interface
  /// can get wrong in a way the type system cannot see.
  Future<List<PresenceGap>> fetchGaps({Duration? within, String? itemId}) async {
    final rows = await supabase.rpc(
      'presence_gaps',
      params: {
        'p_within': within == null ? null : '${within.inMinutes} minutes',
        'p_item_id': itemId,
      },
    );
    return [
      for (final row in (rows as List).cast<Map<String, dynamic>>())
        PresenceGap.fromMap(row),
    ];
  }

  /// The code fixed to one place, with everything a poster needs.
  ///
  /// Refused outright for anybody without `checkin.codes` — the secret is
  /// printable, so who may read it is who may print it.
  Future<({PlaceCode code, String placeName, DateTime rotatedAt})?> fetchCode(
    String itemId,
  ) async {
    final rows = await supabase.rpc('place_code', params: {
      'p_item_id': itemId,
    });
    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return null;
    final row = list.first;
    return (
      code: PlaceCode(
        itemId: row['item_id'] as String,
        secret: row['secret'] as String,
        latitude: (row['lat'] as num?)?.toDouble(),
        longitude: (row['lng'] as num?)?.toDouble(),
        radiusM: (row['radius_m'] as num?)?.toDouble(),
      ),
      placeName: (row['place_name'] as String?) ?? '',
      rotatedAt: DateTime.parse(row['rotated_at'] as String).toLocal(),
    );
  }

  /// Makes every printed copy of this place's code dead, and returns the one
  /// that replaces it.
  Future<void> rotateCode(String itemId) async {
    await supabase.rpc('rotate_place_code', params: {'p_item_id': itemId});
  }

  static PresenceLine _lineFromRow(Map<String, dynamic> row) => PresenceLine(
    id: row['check_in_id'] as String,
    profileId: row['profile_id'] as String,
    fullName: (row['full_name'] as String?) ?? '',
    itemId: row['item_id'] as String,
    placeName: (row['place_name'] as String?) ?? '',
    setCode: row['set_code'] as String?,
    setName: row['set_name_ar'] as String?,
    groupName: row['group_ar'] as String?,
    distanceM: (row['distance_m'] as num?)?.toDouble() ?? 0,
    accuracyM: (row['accuracy_m'] as num?)?.toDouble(),
    radiusM:
        (row['radius_m'] as num?)?.toDouble() ?? CheckInRules.defaultRadiusM,
    note: row['note'] as String?,
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
  );
}
