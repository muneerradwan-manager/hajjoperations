import 'package:equatable/equatable.dart';

import '../../../core/bloc/safe_cubit.dart';
import '../data/prayer_alerts_store.dart';
import '../data/prayer_notifications.dart';
import '../data/prayer_times_repository.dart';
import '../data/prayer_widget_bridge.dart';
import '../domain/prayer_alerts.dart';
import '../domain/prayer_day.dart';
import 'prayer_scheduler.dart';

class PrayerAlertsState extends Equatable {
  const PrayerAlertsState({
    this.alerts = const PrayerAlerts(),
    this.readiness = PrayerAlertReadiness.ready,
    this.locatable = true,
    this.widgets = 0,
    this.loaded = false,
  });

  final PrayerAlerts alerts;

  /// What the system will actually let through — see [PrayerAlertReadiness].
  /// Only meaningful while [PrayerAlerts.enabled]; nothing is asked of the
  /// system until the reader has said they want this.
  final PrayerAlertReadiness readiness;

  /// Whether this device has ever known where it is.
  ///
  /// Without a fix the times on screen are مكة's, and nothing is announced from
  /// them — see [PrayerScheduler]. The switch still works, and the page says
  /// plainly why nothing will arrive until the card's location chip is tapped.
  final bool locatable;

  /// How many copies of the home-screen widget are placed.
  final int widgets;

  /// False for the frame or two before disk answers.
  final bool loaded;

  PrayerAlertsState copyWith({
    PrayerAlerts? alerts,
    PrayerAlertReadiness? readiness,
    bool? locatable,
    int? widgets,
    bool? loaded,
  }) {
    return PrayerAlertsState(
      alerts: alerts ?? this.alerts,
      readiness: readiness ?? this.readiness,
      locatable: locatable ?? this.locatable,
      widgets: widgets ?? this.widgets,
      loaded: loaded ?? this.loaded,
    );
  }

  @override
  List<Object?> get props => [alerts, readiness, locatable, widgets, loaded];
}

/// The settings page's half of the prayer alarms.
///
/// It owns the CHOICES and nothing else. Every change is written to disk and
/// then handed to [PrayerScheduler], which is what actually lays the week down
/// — the same call the app makes at start-up and after a new fix, so there is
/// one path to the alarms and not three.
class PrayerAlertsCubit extends SafeCubit<PrayerAlertsState> {
  PrayerAlertsCubit() : super(const PrayerAlertsState()) {
    _load();
  }

  final _store = const PrayerAlertsStore();
  final _repository = PrayerTimesRepository();

  Future<void> _load() async {
    final alerts = await _store.read();
    final fix = await _repository.lastKnownFix();
    emit(
      state.copyWith(
        alerts: alerts,
        locatable: fix != null,
        loaded: true,
        widgets: await PrayerWidgetBridge.instance.installedCount(),
      ),
    );
    if (alerts.enabled) {
      emit(state.copyWith(readiness: await PrayerNotifications.instance.readiness()));
    }
  }

  /// The master switch.
  ///
  /// Turning it ON is the one moment this feature is allowed to raise a system
  /// dialog: the reader has just pressed a switch labelled with what it does,
  /// which is the only point at which the permission request explains itself.
  /// If they refuse, the switch goes back — a switch left on beside a message
  /// saying nothing will happen is a lie the reader has to decode.
  Future<void> setEnabled(bool enabled) async {
    if (!enabled) {
      await _apply(state.alerts.copyWith(enabled: false));
      return;
    }

    final readiness = await PrayerNotifications.instance.request();
    emit(state.copyWith(readiness: readiness));
    if (readiness == PrayerAlertReadiness.blocked ||
        readiness == PrayerAlertReadiness.unsupported) {
      emit(state.copyWith(alerts: state.alerts.copyWith(enabled: false)));
      return;
    }
    await _apply(state.alerts.copyWith(enabled: true));
  }

  Future<void> toggleSlot(PrayerSlot slot) =>
      _apply(state.alerts.toggling(slot));

  Future<void> setReminderMinutes(int minutes) =>
      _apply(state.alerts.copyWith(reminderMinutes: minutes));

  Future<void> setSilent(bool silent) =>
      _apply(state.alerts.copyWith(silent: silent));

  /// Sends the reader to the system page for exact alarms, and re-reads the
  /// answer when they come back.
  ///
  /// Re-laying afterwards is not housekeeping: alarms already scheduled
  /// inexactly stay inexact, so the permission only takes effect on the ones
  /// laid down after it.
  Future<void> grantExactAlarms() async {
    await PrayerNotifications.instance.requestExactAlarms();
    emit(
      state.copyWith(readiness: await PrayerNotifications.instance.readiness()),
    );
    await PrayerScheduler.instance.refresh();
  }

  /// Offers the launcher's own "add this widget" dialog.
  ///
  /// Returns false where the launcher has none, which the page turns into an
  /// instruction rather than a button that appears to do nothing.
  Future<bool> addWidget() async {
    final pinned = await PrayerWidgetBridge.instance.requestPin();
    if (pinned) await refreshWidgetCount();
    return pinned;
  }

  Future<void> refreshWidgetCount() async =>
      emit(state.copyWith(widgets: await PrayerWidgetBridge.instance.installedCount()));

  Future<void> _apply(PrayerAlerts alerts) async {
    emit(state.copyWith(alerts: alerts));
    await _store.write(alerts);
    await PrayerScheduler.instance.refresh();
    if (alerts.enabled) {
      emit(
        state.copyWith(
          readiness: await PrayerNotifications.instance.readiness(),
        ),
      );
    }
  }
}
