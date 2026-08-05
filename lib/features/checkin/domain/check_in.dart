/// How somebody's presence was established. Mirrors `check_in_method` (0087).
enum CheckInMethod {
  /// A code printed and fixed at the place, scanned there.
  qr,

  /// The phone's position, against the coordinates the file records.
  gps,

  /// He said so. The weakest of the three, kept because a node with no code
  /// printed and no coordinates recorded still has people who arrive at it, and
  /// a register that cannot hold that is a register with holes in exactly the
  /// places nobody got round to preparing.
  manual;

  static CheckInMethod fromDb(String? value) => switch (value) {
    'qr' => CheckInMethod.qr,
    'gps' => CheckInMethod.gps,
    _ => CheckInMethod.manual,
  };

  String get dbName => name;
}

/// What a check-in code says.
///
/// A code is a sticker on a camp gate, and everything about the format follows
/// from that. It has to be:
///
///   * **Unmistakable.** A custom scheme rather than a bare UUID, so that a
///     scan of somebody's WiFi code or a product barcode is rejected as what it
///     is instead of being sent to the server as a node id that happens not to
///     exist.
///   * **Short.** A QR grows with its payload, and this one is printed on A4,
///     stuck outdoors, and scanned at arm's length by a phone in the sun. Two
///     UUIDs is already 82 characters; anything more starts costing legibility.
///   * **Readable by a person.** Whoever prints them has to be able to tell one
///     sheet from another, and `hajjops://check-in?m=…&n=…` can be read off the
///     page. A binary payload could not.
///
/// It carries no secret and is not meant to. A code proves you are looking at
/// the sticker, nothing more; what makes that worth something is the position
/// recorded beside it. See migration 0087.
class CheckInCode {
  const CheckInCode({required this.moduleId, this.nodeId});

  /// Null for the file itself — a flat file with no towers still has people who
  /// arrive somewhere.
  final String? nodeId;
  final String moduleId;

  static const scheme = 'hajjops';
  static const host = 'check-in';

  String encode() {
    return Uri(
      scheme: scheme,
      host: host,
      // The null-aware value marker: the entry is left out entirely when this
      // code stands for the file rather than for a place inside it.
      queryParameters: {'m': moduleId, 'n': ?nodeId},
    ).toString();
  }

  /// Reads a scanned string, or null if it was not one of ours.
  ///
  /// Null rather than throwing: a camera pointed at a crowd will read all sorts
  /// of things, and the scanner keeps looking rather than showing an error for
  /// every barcode that drifts through the frame.
  static CheckInCode? parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;
    if (uri.scheme != scheme || uri.host != host) return null;

    final moduleId = uri.queryParameters['m'];
    if (moduleId == null || moduleId.isEmpty) return null;

    final nodeId = uri.queryParameters['n'];
    return CheckInCode(
      moduleId: moduleId,
      nodeId: (nodeId == null || nodeId.isEmpty) ? null : nodeId,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CheckInCode &&
      other.moduleId == moduleId &&
      other.nodeId == nodeId;

  @override
  int get hashCode => Object.hash(moduleId, nodeId);

  @override
  String toString() => encode();
}

/// One recorded arrival, as the presence board reads it back.
class PresenceLine {
  const PresenceLine({
    required this.id,
    required this.profileId,
    required this.fullName,
    required this.method,
    required this.createdAt,
    this.nodeId,
    this.nodeLabel,
    this.distanceM,
    this.accuracyM,
    this.note,
  });

  final String id;
  final String profileId;
  final String fullName;
  final CheckInMethod method;
  final DateTime createdAt;

  final String? nodeId;
  final String? nodeLabel;

  /// Metres between the phone and where the file says the place is. Null when
  /// the node has no recorded position, or the phone gave none — which is not
  /// the same as zero and must never be shown as it.
  final double? distanceM;

  /// What the phone thought its own fix was worth.
  final double? accuracyM;

  final String? note;

  /// How far off it may be counted as, allowing for the phone's own doubt.
  ///
  /// A fix reported at 400 m from the gate but accurate to only 500 m is not
  /// evidence that anybody was in the wrong place; a fix 400 m off and accurate
  /// to 8 m is. Subtracting the accuracy is what tells those apart, and doing it
  /// anywhere but here would mean doing it differently in two screens.
  double? get worstCaseDistanceM {
    final distance = distanceM;
    if (distance == null) return null;
    final slack = accuracyM ?? 0;
    final adjusted = distance - slack;
    return adjusted < 0 ? 0 : adjusted;
  }

  /// Far enough from the recorded position, after allowing for the phone's own
  /// margin, that somebody should look at it.
  ///
  /// Deliberately a QUESTION and not a verdict. It is never used to refuse a
  /// check-in — a man in a metal camp with a bad fix must still be able to
  /// report that he arrived — only to mark the row so the operations room can
  /// ask. Two hundred metres is about the length of a Mina camp: closer than
  /// that and the difference is the GPS, not the man.
  static const suspectDistanceM = 200.0;

  bool get isFarFromPlace =>
      (worstCaseDistanceM ?? 0) > suspectDistanceM;
}
