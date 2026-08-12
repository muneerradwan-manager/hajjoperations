import 'package:equatable/equatable.dart';

import '../../../core/bloc/safe_cubit.dart';
import '../../../core/offline/outbox.dart';
import '../../../core/utils/device_position.dart';
import '../../../core/utils/network_error.dart';
import '../data/incidents_outbox.dart';
import '../data/incidents_repository.dart';
import '../domain/incident.dart';

enum IncidentsStatus { loading, ready, error }

class IncidentsState extends Equatable {
  const IncidentsState({
    this.status = IncidentsStatus.loading,
    this.incidents = const [],
    this.includeClosed = false,
    this.error,
  });

  final IncidentsStatus status;
  final List<Incident> incidents;
  final bool includeClosed;
  final String? error;

  int get openCount =>
      incidents.where((incident) => incident.state.isOpen).length;

  IncidentsState copyWith({
    IncidentsStatus? status,
    List<Incident>? incidents,
    bool? includeClosed,
    String? error,
  }) => IncidentsState(
    status: status ?? this.status,
    incidents: incidents ?? this.incidents,
    includeClosed: includeClosed ?? this.includeClosed,
    error: error,
  );

  @override
  List<Object?> get props => [status, incidents, includeClosed, error];
}

/// The register, for whoever receives urgent reports.
class IncidentsCubit extends SafeCubit<IncidentsState> {
  IncidentsCubit(this._repo) : super(const IncidentsState()) {
    load();
  }

  final IncidentsRepository _repo;

  Future<void> load() async {
    try {
      final incidents = await _repo.fetchList(
        includeClosed: state.includeClosed,
      );
      emit(state.copyWith(status: IncidentsStatus.ready, incidents: incidents));
    } catch (e) {
      emit(state.copyWith(status: IncidentsStatus.error, error: e.toString()));
    }
  }

  Future<void> setIncludeClosed(bool value) async {
    emit(state.copyWith(includeClosed: value));
    await load();
  }

  /// Moves one along. Returns null on success, else what went wrong.
  ///
  /// Deliberately NOT queued when there is no network. Everything else in this
  /// app that a person writes is worth keeping for later; "I have taken this
  /// on" is worth nothing later. It is a claim about right now, made so that
  /// nobody else duplicates the trip, and one that arrives an hour after the
  /// fact has told the room something that stopped being true.
  Future<String?> setState(
    Incident incident,
    IncidentState next, {
    String? resolution,
  }) async {
    try {
      await _repo.setState(
        incidentId: incident.id,
        state: next,
        resolution: resolution,
      );
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

/// Raising one. A plain function, because it is called from a button that may
/// be anywhere in the app.
abstract final class RaiseIncident {
  static Future<IncidentOutcome> send(
    PendingIncident pending, {
    IncidentsRepository? repository,
  }) async {
    final repo = repository ?? IncidentsRepository();

    // Taken first, and never allowed to hold anything up: a position that has
    // not arrived in a few seconds is not worth the delay when somebody is
    // waiting for help. `currentPositionOrNull` gives up quietly.
    final position = await currentPositionOrNull(
      timeout: const Duration(seconds: 8),
    );

    try {
      await repo.raise(
        body: pending.body,
        moduleId: pending.moduleId,
        nodeId: pending.nodeId,
        subjectProfileId: pending.subjectProfileId,
        appRoute: pending.appRoute,
        appLabel: pending.appLabel,
        latitude: position?.latitude,
        longitude: position?.longitude,
        accuracy: position?.accuracy,
        attachments: pending.attachments,
      );
      return IncidentOutcome.sent;
    } catch (error) {
      if (!looksLikeNetworkFailure(error)) return IncidentOutcome.failed;

      // Kept, so it is not lost — but the caller MUST tell the person that
      // nobody has been alerted. See [IncidentOutcome.waitingForNetwork].
      if (!Outbox.isInstalled) return IncidentOutcome.failed;
      try {
        await Outbox.instance.add(
          kind: IncidentsOutbox.kind,
          payload: IncidentsOutbox.payload(
            body: pending.body,
            moduleId: pending.moduleId,
            nodeId: pending.nodeId,
            subjectProfileId: pending.subjectProfileId,
            appRoute: pending.appRoute,
            appLabel: pending.appLabel,
            latitude: position?.latitude,
            longitude: position?.longitude,
            accuracy: position?.accuracy,
          ),
          label: pending.body,
          attachments: pending.attachments,
        );
        return IncidentOutcome.waitingForNetwork;
      } catch (_) {
        return IncidentOutcome.failed;
      }
    }
  }
}
