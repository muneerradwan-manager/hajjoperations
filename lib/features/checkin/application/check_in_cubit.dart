import 'package:equatable/equatable.dart';

import '../../../core/bloc/safe_cubit.dart';
import '../../../core/offline/outbox.dart';
import '../../../core/offline/save_outcome.dart';
import '../../../core/utils/device_position.dart';
import '../data/check_in_outbox.dart';
import '../data/check_in_repository.dart';
import '../domain/check_in.dart';

enum PresenceStatus { loading, ready, error }

class PresenceState extends Equatable {
  const PresenceState({
    this.status = PresenceStatus.loading,
    this.lines = const [],
    this.error,
  });

  final PresenceStatus status;
  final List<PresenceLine> lines;
  final String? error;

  /// The ones worth a second look — far from where the file says the place is,
  /// after the phone's own margin of error has been allowed for.
  List<PresenceLine> get suspect =>
      [for (final line in lines) if (line.isFarFromPlace) line];

  @override
  List<Object?> get props => [status, lines, error];
}

/// Reading who is where in one file.
class PresenceCubit extends SafeCubit<PresenceState> {
  PresenceCubit(this._repo, this.moduleId) : super(const PresenceState()) {
    load();
  }

  final CheckInRepository _repo;
  final String moduleId;

  Future<void> load({DateTime? since}) async {
    try {
      final lines = await _repo.fetchPresence(moduleId: moduleId, since: since);
      emit(PresenceState(status: PresenceStatus.ready, lines: lines));
    } catch (e) {
      emit(PresenceState(status: PresenceStatus.error, error: e.toString()));
    }
  }
}

/// Reporting an arrival.
///
/// Not a screen's cubit — a plain object with one method, used from the scanner
/// sheet and from the file page alike. Both do exactly the same thing and must
/// keep doing exactly the same thing: take a fix, then hand the whole act to
/// the outbox.
abstract final class CheckIn {
  /// Records that the caller arrived. Never throws for want of a network.
  ///
  /// The order matters and is the reason this is not two lines at the call
  /// site. The POSITION IS TAKEN FIRST, before anything is sent, so that what
  /// is recorded is where the man was when he pressed the button — not where
  /// the phone happened to be when the queue finally drained, which may be a
  /// different camp or a hotel in Makkah hours later.
  static Future<SaveOutcome> arrive({
    required String moduleId,
    String? nodeId,
    required CheckInMethod method,
    String? note,
    CheckInRepository? repository,
  }) async {
    final repo = repository ?? CheckInRepository();
    final position = await currentPositionOrNull();

    // A scan with a fix beside it is still a scan: the code is what identified
    // the place, and the coordinates are the corroboration. Only an arrival
    // with nothing to identify the place BUT the coordinates is a `gps` one.
    final resolved = switch (method) {
      CheckInMethod.manual when position != null => CheckInMethod.gps,
      _ => method,
    };

    try {
      final sent = await sendOrQueue(
        send: () => repo.checkIn(
          moduleId: moduleId,
          nodeId: nodeId,
          method: resolved,
          latitude: position?.latitude,
          longitude: position?.longitude,
          accuracy: position?.accuracy,
          note: note,
        ),
        kind: CheckInOutbox.kind,
        payload: CheckInOutbox.payload(
          moduleId: moduleId,
          nodeId: nodeId,
          method: resolved,
          latitude: position?.latitude,
          longitude: position?.longitude,
          accuracy: position?.accuracy,
          note: note,
        ),
      );
      return sent ? const SaveOutcome.sent() : const SaveOutcome.queued();
    } catch (e) {
      return SaveOutcome.failed(e.toString());
    }
  }
}
