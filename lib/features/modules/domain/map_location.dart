/// A point on the ground, kept as the map URL that names it.
///
/// The stored value stays a plain URL string — that is what the admin pastes
/// when they already have a link, what "open location" launches, and what was
/// already in the column before pins and GPS existed. Coordinates are read back
/// out of the URL when it carries them, so reopening the picker lands on the
/// pin the admin last dropped instead of on a default city.
class MapLocation {
  const MapLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  /// The `?q=lat,lng` form: understood by Google Maps, and by every other maps
  /// app that registers for map links.
  String get url =>
      'https://www.google.com/maps?q=${_trim(latitude)},${_trim(longitude)}';

  /// Six decimals is roughly 10 cm — far past what a dropped pin means.
  static String _trim(double value) =>
      value.toStringAsFixed(6).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');

  /// Pulls coordinates out of a map URL. Handles the `q=`/`query=` parameter
  /// form this app writes and the `@lat,lng` form Google's own share links use.
  /// Returns null for a link that names a place without saying where it is —
  /// a shortened `maps.app.goo.gl` link, for instance.
  static MapLocation? parse(String? url) {
    if (url == null || url.isEmpty) return null;

    const pair = r'(-?\d{1,3}(?:\.\d+)?)\s*,\s*(-?\d{1,3}(?:\.\d+)?)';
    final match =
        RegExp('[?&](?:q|query|ll|center)=$pair').firstMatch(url) ??
        RegExp('@$pair').firstMatch(url);
    if (match == null) return null;

    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    if (lat == null || lng == null) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    return MapLocation(latitude: lat, longitude: lng);
  }
}
