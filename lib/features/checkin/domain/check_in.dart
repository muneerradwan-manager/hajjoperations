import 'dart:math' as math;

/// The arithmetic of "near enough", in one place because two places would
/// disagree.
///
/// The phone needs all of it as well as the server: since 0098 a check-in that
/// is too far away is REFUSED rather than flagged, and a phone with no signal
/// must be able to refuse honestly instead of queueing something the server
/// will throw away hours later. So the rule is written twice, once here and
/// once in SQL, and `test/check_in_radius_test.dart` reads the migration to
/// hold the two together.
abstract final class CheckInRules {
  /// How near a phone must be, when the place does not say otherwise.
  ///
  /// About the length of a camp in منى, and the same number 0087 used to call a
  /// check-in suspect — so the figure that used to raise an eyebrow is now the
  /// figure that decides. Mirrors `place_radius_m`'s default in 0098.
  static const defaultRadiusM = 200.0;

  /// Metres between two points on the globe.
  ///
  /// The same haversine as `metres_between` in 0087, written again rather than
  /// asked for, because the whole point is to be able to answer without a
  /// network. Two formulas that disagree by ten metres would be a man refused
  /// by his phone and accepted by the server, so a test pins them together.
  static double metresBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusM = 6371000.0;
    double radians(double degrees) => degrees * math.pi / 180.0;

    final dLat = radians(lat2 - lat1);
    final dLng = radians(lng2 - lng1);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(radians(lat1)) *
            math.cos(radians(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadiusM * math.asin(math.sqrt(a));
  }

  /// How far off it may be counted as, allowing for the phone's own doubt.
  ///
  /// A fix reported 400 m from the gate but accurate only to 500 m is not
  /// evidence that anybody was in the wrong place; a fix 400 m off and accurate
  /// to 8 m is. Subtracting the accuracy is what tells those apart.
  ///
  /// It used to live on [PresenceLine], where it decided whether to draw a
  /// warning. It decides whether to accept the check-in at all now, which is
  /// why it had to move somewhere there is no line yet.
  static double worstCase(double distance, double? accuracy) =>
      math.max(0, distance - (accuracy ?? 0));

  /// Whether a fix taken here would be refused for being too far away.
  static bool tooFar({
    required double distance,
    double? accuracy,
    required double radius,
  }) => worstCase(distance, accuracy) > radius;
}

/// What the code on a place says.
///
/// A code is a sticker on a hotel entrance or a camp gate, and everything about
/// the format follows from that:
///
///   * **Unmistakable.** A custom scheme rather than a bare UUID, so a scan of
///     somebody's WiFi code or a product barcode is refused as what it is
///     rather than sent to the server as an id that happens not to exist.
///   * **Readable by a person.** Whoever prints forty of these has to tell one
///     sheet from another, and the payload is printed under the QR for exactly
///     that — a sun-bleached sticker can still be identified.
///   * **Revocable.** [secret] is what makes "regenerate" mean something. A
///     code photographed and sent round a group chat is a code that admits
///     people who are not there; rotating the secret makes every copy of it
///     dead, including the one on the wall, which is why the app offers to
///     print the moment it rotates.
///
/// [latitude], [longitude] and [radiusM] are the place's own, copied onto the
/// poster so a phone with no signal can refuse honestly. They carry a rule that
/// must be stated once and obeyed everywhere:
///
/// > **They may only ever cause a REFUSAL, never an acceptance.**
///
/// The server recomputes both from the master data and is the only thing that
/// writes a row. So a forged poster claiming the camp stands wherever the phone
/// happens to be gets past the phone and is refused by the database — and a
/// poster printed before this field existed, which carries none of them, simply
/// gets the server's answer instead. Null means "no local check possible", not
/// "no check".
class PlaceCode {
  const PlaceCode({
    required this.itemId,
    required this.secret,
    this.latitude,
    this.longitude,
    this.radiusM,
  });

  /// The `reference_items` row this is stuck to — a hotel, a camp.
  final String itemId;

  /// The rotatable half. A payload without one is not a code of ours.
  final String secret;

  final double? latitude;
  final double? longitude;
  final double? radiusM;

  static const scheme = 'hajjops';
  static const host = 'check-in';

  /// Whether this poster carries enough to be judged without a network.
  bool get canCheckLocally =>
      latitude != null && longitude != null && radiusM != null;

  String encode() => Uri(
    scheme: scheme,
    host: host,
    queryParameters: {
      'p': itemId,
      'k': secret,
      if (latitude != null && longitude != null)
        'c': '${_trim(latitude!)},${_trim(longitude!)}',
      if (radiusM != null) 'r': _trim(radiusM!),
    },
  ).toString();

  /// Reads a scanned string, or null if it was not one of ours.
  ///
  /// Null rather than throwing: a camera pointed at a crowd reads all sorts of
  /// things, and the scanner keeps looking rather than showing an error for
  /// every barcode that drifts through the frame.
  static PlaceCode? parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;
    if (uri.scheme != scheme || uri.host != host) return null;

    final itemId = uri.queryParameters['p'];
    final secret = uri.queryParameters['k'];
    // Both, always. A payload naming a place but carrying no secret is either a
    // code from before 0098 or somebody's guess, and neither may be sent.
    if (itemId == null || itemId.isEmpty) return null;
    if (secret == null || secret.isEmpty) return null;

    double? lat;
    double? lng;
    final pair = uri.queryParameters['c']?.split(',');
    if (pair != null && pair.length == 2) {
      lat = double.tryParse(pair[0].trim());
      lng = double.tryParse(pair[1].trim());
      // A pair off the globe was not a position, and half a pair is not one
      // either — both go, so `canCheckLocally` cannot be half true.
      if (lat == null ||
          lng == null ||
          lat.abs() > 90 ||
          lng.abs() > 180) {
        lat = null;
        lng = null;
      }
    }

    final radius = double.tryParse(uri.queryParameters['r'] ?? '');

    return PlaceCode(
      itemId: itemId,
      secret: secret,
      latitude: lat,
      longitude: lng,
      radiusM: (radius != null && radius > 0) ? radius : null,
    );
  }

  static String _trim(double v) {
    final s = v.toStringAsFixed(6);
    return s.contains('.')
        ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
        : s;
  }

  @override
  bool operator ==(Object other) =>
      other is PlaceCode &&
      other.itemId == itemId &&
      other.secret == secret &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.radiusM == radiusM;

  @override
  int get hashCode =>
      Object.hash(itemId, secret, latitude, longitude, radiusM);

  @override
  String toString() => encode();
}

/// One recorded arrival, as the presence board reads it back.
///
/// [distanceM] and [radiusM] are not nullable any more, and neither is the
/// position behind them. Every row on the board was measured and passed, by
/// construction — which is also why the "far from the place" flag that used to
/// live here is gone: it could never fire, and a warning that never fires
/// teaches a room to stop reading warnings.
class PresenceLine {
  const PresenceLine({
    required this.id,
    required this.profileId,
    required this.fullName,
    required this.itemId,
    required this.placeName,
    required this.distanceM,
    required this.radiusM,
    required this.createdAt,
    this.setCode,
    this.setName,
    this.groupName,
    this.accuracyM,
    this.note,
  });

  final String id;
  final String profileId;
  final String fullName;

  final String itemId;

  /// "فندق الأنصار", "المخيم رقم ١٤".
  final String placeName;

  /// Which list it came from, and what that list is called.
  final String? setCode;
  final String? setName;

  /// Where the board groups it — the hotel's city, the camp's مشعر. Read from
  /// the entry's own dividing reference, so a fifth group appears the day a
  /// fifth exists.
  final String? groupName;

  /// Metres between the phone and where the master data says the place is.
  final double distanceM;

  /// What the phone thought its own fix was worth.
  final double? accuracyM;

  /// What it was measured against. Stored on the row rather than looked up,
  /// because the place's override can be edited afterwards and a line has to
  /// stay explicable to somebody reading it in شوال.
  final double radiusM;

  final String? note;
  final DateTime createdAt;
}
