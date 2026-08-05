import '../../../core/offline/outbox.dart';
import '../../../core/offline/outbox_entry.dart';
import '../domain/check_in.dart';
import 'check_in_repository.dart';

/// Arriving somewhere, kept until it can be reported.
///
/// This is the third field write, and of the three it is the one most certain
/// to be made where there is no signal. A man reports his arrival by standing at
/// the gate of a camp in Mina and pointing his phone at a sticker — which is a
/// description of the worst reception in the season. A check-in that failed
/// because of the network would be a man who WAS there and is recorded as
/// having not been, which is worse than no record at all: the operations room
/// would send somebody to look for him.
///
/// It replays cleanly because it appends: the row it writes is a new arrival
/// with its own timestamp, and the same arrival sent twice is two rows a minute
/// apart rather than a contradiction. The presence board reads the latest per
/// person per place, so a duplicate changes nothing it shows.
///
/// The POSITION is captured when the button is pressed, not when the queue
/// drains. That is the whole point — the phone may be back in Makkah by then,
/// and a check-in carrying the coordinates of wherever it was finally sent from
/// would be a lie the database would then compute a distance against.
abstract final class CheckInOutbox {
  static const kind = 'checkin.arrive';

  static void register(Outbox outbox) => outbox.register(kind, _send);

  static Map<String, dynamic> payload({
    required String moduleId,
    String? nodeId,
    required CheckInMethod method,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? note,
  }) => {
    'module_id': moduleId,
    'node_id': nodeId,
    'method': method.dbName,
    'lat': latitude,
    'lng': longitude,
    'accuracy': accuracy,
    'note': note,
  };

  static Future<void> _send(OutboxEntry entry) async {
    final payload = entry.payload;
    await CheckInRepository().checkIn(
      moduleId: payload['module_id'] as String,
      nodeId: payload['node_id'] as String?,
      method: CheckInMethod.fromDb(payload['method'] as String?),
      latitude: (payload['lat'] as num?)?.toDouble(),
      longitude: (payload['lng'] as num?)?.toDouble(),
      accuracy: (payload['accuracy'] as num?)?.toDouble(),
      note: payload['note'] as String?,
    );
  }
}
