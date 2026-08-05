import 'package:geolocator/geolocator.dart';

import '../logging/app_logger.dart';

/// The phone's position, or nothing, and never an exception.
///
/// Distinct from the location picker's version of this on purpose. There, a
/// failure is worth a sentence on screen — the person pressed "use my
/// location" and is waiting for a pin. Here, the position is EVIDENCE
/// accompanying an act that must succeed without it: a man reporting that he
/// has arrived at a camp in Mina, where the location service may be off, the
/// permission refused, or the sky simply not visible from inside a tent.
///
/// So every way of failing collapses to null, and the caller records the
/// arrival regardless. A check-in with no coordinates is a weaker record than
/// one with them, and a far stronger record than none.
Future<Position?> currentPositionOrNull({
  Duration timeout = const Duration(seconds: 12),
}) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      AppLogger.info('location', 'service off — no fix');
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      AppLogger.info('location', 'permission refused — no fix');
      return null;
    }

    // Shorter than the picker's twenty seconds. Somebody is standing at a gate
    // waiting for a button to finish; a fix that has not arrived in twelve
    // seconds is not going to arrive before he gives up and walks away, and
    // walking away with no record is the outcome this exists to prevent.
    return await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: timeout,
      ),
    );
  } catch (error) {
    AppLogger.info('location', 'no fix — $error');
    return null;
  }
}
