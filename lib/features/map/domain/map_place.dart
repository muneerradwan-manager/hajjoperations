import 'package:latlong2/latlong.dart';

import '../../../core/l10n/localized_name.dart';

/// How a place is doing, at a glance, from across a room.
///
/// The whole point of drawing the season instead of listing it is that a colour
/// is read before a word is. So there are three and only three, and they are
/// ordered by what somebody would have to DO about them.
enum PlaceCondition {
  /// Something is wrong here and nobody has closed it.
  incident,

  /// Nobody has reported arriving in the last shift, though people are posted.
  ///
  /// Not an accusation. A phone with no signal cannot check in, and the man may
  /// well be standing there — which is exactly why this is drawn as a question
  /// and not as a failure.
  unmanned,

  /// Somebody is there and nothing is outstanding.
  manned,

  /// Nobody is posted here at all. The place exists in the file and has not
  /// been staffed.
  empty,

  /// Nobody CAN report arriving here: the node stands on no master-data entry,
  /// so there is nothing to fix a code to (0098).
  ///
  /// Without this such a place read as [unmanned] — a coloured pin accusing
  /// nobody of anything, since no arrival could ever be counted against it. The
  /// answer is not to look for the man; it is to give the node an entry.
  uncoded;

  /// Whether it is worth the operations room's attention.
  bool get wantsAttention =>
      this == PlaceCondition.incident || this == PlaceCondition.unmanned;
}

/// One place of the season, as the map draws it.
class MapPlace {
  const MapPlace({
    required this.nodeId,
    required this.moduleId,
    required this.moduleName,
    required this.placeName,
    required this.position,
    required this.groupKey,
    required this.groupName,
    this.posted = 0,
    this.present = 0,
    this.openIncidents = 0,
    this.canCheckIn = true,
  });

  /// Null for a hotel that is not a node in any file — most of المدينة. It is
  /// still a place the mission's pilgrims are in, and still worth drawing.
  final String? nodeId;
  final String? moduleId;

  /// Which of the season's four groups this belongs to — the camps of منى, the
  /// camps of عرفات, the hotels of مكة, the hotels of المدينة.
  ///
  /// Stable and never shown: a filter has to survive a refresh, and the label
  /// beside it is content that changes with the reader's language.
  final String groupKey;

  final LocalizedName groupName;

  /// The file this place belongs to — "توزيع الأعضاء على مخيمات منى".
  final String moduleName;

  /// The place itself — "المخيم رقم ١٤", "فندق الأنصار".
  final String placeName;

  final LatLng position;

  /// How many hold a post here.
  final int posted;

  /// How many have reported arriving in the last twelve hours.
  final int present;

  final int openIncidents;

  /// Whether an arrival can be recorded here at all.
  ///
  /// False for a node that names no master-data entry: a code is fixed to a
  /// hotel or a camp, and a node standing on neither has nothing to carry one.
  final bool canCheckIn;

  PlaceCondition get condition {
    if (openIncidents > 0) return PlaceCondition.incident;
    if (posted == 0) return PlaceCondition.empty;
    if (present > 0) return PlaceCondition.manned;
    // Checked AFTER `manned`, deliberately. A count above zero settles the
    // question whatever the flag says, and a place that somehow has arrivals
    // recorded against it plainly can be checked into.
    if (!canCheckIn) return PlaceCondition.uncoded;
    return PlaceCondition.unmanned;
  }

  static MapPlace fromRow(Map<String, dynamic> map) => MapPlace(
    nodeId: map['node_id'] as String?,
    moduleId: map['module_id'] as String?,
    moduleName: (map['module_name'] as String?) ?? '',
    placeName: (map['place_name'] as String?) ?? '',
    position: LatLng(
      (map['lat'] as num).toDouble(),
      (map['lng'] as num).toDouble(),
    ),
    groupKey: (map['group_key'] as String?) ?? '—',
    groupName: LocalizedName(
      ar: (map['group_ar'] as String?) ?? '',
      en: map['group_en'] as String?,
    ),
    posted: (map['posted'] as num?)?.toInt() ?? 0,
    present: (map['present'] as num?)?.toInt() ?? 0,
    openIncidents: (map['open_incidents'] as num?)?.toInt() ?? 0,
    canCheckIn: (map['can_check_in'] as bool?) ?? true,
  );
}

/// One of the season's groups of places, and how many are in it.
///
/// The four the mission actually thinks in — the camps of منى, the camps of
/// عرفات, the hotels of مكة, the hotels of المدينة — are not hard-coded
/// anywhere. They fall out of the data: a place drawn from the hotels list is
/// grouped by the hotel's city, and everything else by the file it belongs to.
/// A fifth arrives on the day a fifth exists.
class MapGroup {
  const MapGroup({required this.key, required this.name, required this.count});

  final String key;
  final LocalizedName name;

  /// How many places carry this group. Shown on the filter, because a group
  /// with nothing in it is worth knowing about before it is switched on.
  final int count;
}

/// The box that holds every point being drawn.
///
/// Needed because the season is not in one place: مكة and المدينة are four
/// hundred kilometres apart, and منى and عرفات are ten minutes apart. Opening
/// on a fixed centre and zoom would show either an empty desert or one camp,
/// depending on which file the reader happened to be looking at.
class MapBounds {
  const MapBounds({required this.southWest, required this.northEast});

  final LatLng southWest;
  final LatLng northEast;

  LatLng get centre => LatLng(
    (southWest.latitude + northEast.latitude) / 2,
    (southWest.longitude + northEast.longitude) / 2,
  );

  /// Null when there is nothing to frame — which the caller must handle by
  /// falling back to a fixed centre rather than by framing an empty box.
  static MapBounds? around(Iterable<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;
    for (final p in points) {
      minLat = (minLat == null || p.latitude < minLat) ? p.latitude : minLat;
      maxLat = (maxLat == null || p.latitude > maxLat) ? p.latitude : maxLat;
      minLng = (minLng == null || p.longitude < minLng) ? p.longitude : minLng;
      maxLng = (maxLng == null || p.longitude > maxLng) ? p.longitude : maxLng;
    }
    if (minLat == null) return null;

    // A single point has no extent, and a zero-sized box makes the map zoom to
    // its maximum — a street corner filling the screen. Padded to something a
    // person can recognise the surroundings of.
    const pad = 0.002;
    return MapBounds(
      southWest: LatLng(minLat - pad, minLng! - pad),
      northEast: LatLng(maxLat! + pad, maxLng! + pad),
    );
  }
}
