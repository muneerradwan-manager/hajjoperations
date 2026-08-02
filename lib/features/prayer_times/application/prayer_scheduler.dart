import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart' show Locale;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/settings/settings_cubit.dart';
import '../../../l10n/app_localizations.dart';
import '../data/prayer_alerts_store.dart';
import '../data/prayer_notifications.dart';
import '../data/prayer_times_repository.dart';
import '../data/prayer_widget_bridge.dart';
import '../domain/prayer_alerts.dart';
import '../domain/prayer_day.dart';
import '../domain/prayer_place.dart';
import '../domain/prayer_schedule.dart';
import '../domain/prayer_text.dart';

/// Keeps the two things OUTSIDE the app in step with the two inside it: the
/// alarms sitting in Android's scheduler, and the times drawn on the home
/// screen.
///
/// Both survive the app being closed, and neither can ask a question when it
/// wakes up — so both have to be given a week of answers in advance, and both
/// have to be re-given them whenever an answer changes. There are exactly four
/// things that change one:
///
///   * the position moved (a new fix, or the first one);
///   * the reader changed what they want announced;
///   * the reader changed the app's language, which the notification text and
///     the widget's labels are written in;
///   * a week went by — which is caught by re-laying everything at start-up.
///
/// Rather than four call sites each assembling their own arguments, every one
/// of them calls [refresh] and this reads the current answers back off disk.
/// The position is already persisted by [PrayerTimesRepository], the choices by
/// [PrayerAlertsStore] and the language by [SettingsCubit] — so "what is true
/// now" is a question with one answer and no parameters, which is what makes it
/// safe to call this from a start-up path that knows nothing about any of it.
class PrayerScheduler {
  PrayerScheduler._();
  static final instance = PrayerScheduler._();

  final _repository = PrayerTimesRepository();
  final _store = const PrayerAlertsStore();

  Future<void>? _running;
  bool _asked = false;

  /// Re-lays the alarms and redraws the widget from whatever is on disk.
  ///
  /// Calls made while one is already in flight do not queue up one behind the
  /// other — they collapse into a single extra pass at the end, because they
  /// would all read the same state and lay down the same seventy alarms.
  Future<void> refresh() async {
    if (_running != null) {
      _asked = true;
      return _running;
    }
    _running = _refresh();
    try {
      await _running;
    } finally {
      _running = null;
    }
    if (_asked) {
      _asked = false;
      await refresh();
    }
  }

  Future<void> _refresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alerts = _store.readFrom(prefs);
      final l = await _strings(prefs);
      final fix = await _repository.lastKnownFix();

      final now = DateTime.now();
      final latitude = fix?.latitude ?? PrayerTimesRepository.fallbackLatitude;
      final longitude =
          fix?.longitude ?? PrayerTimesRepository.fallbackLongitude;

      final days = [
        for (var i = 0; i < PrayerSchedule.horizonDays; i++)
          _repository.dayFor(
            latitude: latitude,
            longitude: longitude,
            // Built by field rather than by adding a Duration: `now + 24h` is
            // an hour short of tomorrow on the day a zone comes off summer
            // time, and lands on the same calendar day twice.
            at: DateTime(now.year, now.month, now.day + i),
          ),
      ];

      // No fix means the times on screen are مكة's, shown to somebody who may
      // be a thousand miles from it and labelled "موقع تقريبي" for exactly that
      // reason. A card may say so; a phone that goes off in the dark may not.
      // So the widget still draws them — with the same warning — and nothing
      // is scheduled until the app knows where it is standing.
      if (alerts.announces && fix != null) {
        await PrayerNotifications.instance.apply(
          PrayerSchedule.alarmsFor(days: days, alerts: alerts, now: now),
          text: (alarm) => _textFor(l, alarm, alerts),
          silent: alerts.silent,
        );
      } else {
        await PrayerNotifications.instance.cancelAll();
      }

      await PrayerWidgetBridge.instance.push(
        widgetPayload(
          l: l,
          days: days,
          now: now,
          place: fix == null
              ? null
              : PrayerPlace.nearestTo(latitude, longitude),
          approximate: fix == null,
          rtl: _isRtl(l.localeName),
        ),
      );
    } catch (e, s) {
      AppLogger.error('prayer', 'scheduler refresh failed', e, s);
    }
  }

  /// Turns off everything this device says about prayer, and forgets it.
  ///
  /// Called on sign-out: the next person to hold this phone should not be told
  /// when to pray by an app they have not signed into.
  Future<void> stop() async {
    await PrayerNotifications.instance.cancelAll();
    await _store.write(const PrayerAlerts());
  }

  // ── What an alarm says ─────────────────────────────────────────────────

  PrayerAlarmText _textFor(
    AppLocalizations l,
    PrayerAlarm alarm,
    PrayerAlerts alerts,
  ) {
    final name = slotName(l, alarm.slot);
    final clock = clockText(l, alarm.callAt);
    return alarm.isReminder
        ? PrayerAlarmText(
            title: l.prayerAlertBefore(name, alerts.reminderMinutes),
            body: l.prayerAlertBeforeBody(clock),
          )
        : PrayerAlarmText(
            title: l.prayerAlertNow(name),
            body: l.prayerAlertNowBody(clock),
          );
  }

  // ── What the home screen is given ──────────────────────────────────────

  /// Everything the widget needs for a week, as finished strings.
  ///
  /// Public and pure so that a test can read what the launcher will be handed
  /// without a platform channel in sight.
  static Map<String, Object?> widgetPayload({
    required AppLocalizations l,
    required List<PrayerDay> days,
    required DateTime now,
    required PrayerPlace? place,
    required bool approximate,
    required bool rtl,
  }) {
    return {
      'updatedAt': now.millisecondsSinceEpoch,
      'rtl': rtl,
      'approximate': approximate,
      'place': place == null
          ? (approximate ? l.prayerApproximate : l.prayerYourLocation)
          : placeName(l, place),
      'labels': {
        'title': l.prayerTimesTitle,
        'next': l.prayerNextLabel,
        'fajrEnds': l.prayerFajrEndsLabel,
        'remaining': l.prayerRemainingLabel,
        'gap': l.prayerSunriseGapNote,
        'tomorrow': l.prayerTomorrow,
        'stale': l.prayerWidgetStale,
      },
      // Every mark of every day in the horizon, in order. The provider picks
      // the row for today out of it by the `day` key and the next mark by the
      // first `at` still ahead — which is all the arithmetic a launcher has to
      // do, and none of it needs a calendar or a timezone.
      'marks': [
        for (final day in days)
          for (final slot in PrayerSlot.values)
            {
              'day': _dayKey(day.day),
              'slot': slot.name,
              'name': slotName(l, slot),
              'clock': shortClockText(day.timeOf(slot)),
              'at': day.timeOf(slot).millisecondsSinceEpoch,
              'prayer': slot.isPrayer,
            },
      ],
    };
  }

  static String _dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  // ── Which language all of that is in ───────────────────────────────────

  /// The app's own language, not the phone's.
  ///
  /// A notification raised while the app is closed still belongs to the app,
  /// and somebody who set this app to Arabic on an English phone did so on
  /// purpose. The device's list is only consulted when they made no choice —
  /// which is what "follow the system" means in the settings page.
  Future<AppLocalizations> _strings(SharedPreferences prefs) {
    final chosen = prefs.getString(SettingsCubit.localeKey);
    final locale = chosen != null ? Locale(chosen) : _deviceLocale();
    return AppLocalizations.delegate.load(locale);
  }

  static Locale _deviceLocale() {
    for (final wanted in PlatformDispatcher.instance.locales) {
      for (final supported in AppLocalizations.supportedLocales) {
        if (supported.languageCode == wanted.languageCode) return supported;
      }
    }
    return AppLocalizations.supportedLocales.first;
  }

  /// The two languages this app speaks, one of which is written right to left.
  static bool _isRtl(String localeName) => localeName.startsWith('ar');
}
