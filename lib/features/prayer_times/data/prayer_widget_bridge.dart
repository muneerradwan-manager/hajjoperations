import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/logging/app_logger.dart';

/// The way into the home-screen widget.
///
/// The widget is drawn by Android, not by Flutter: it lives on the launcher,
/// where this app's process usually is not running at all. So nothing is
/// "rendered" from here — a week of times is handed over, the provider keeps
/// them, and it redraws itself off that store whenever the launcher, a reboot
/// or its own boundary alarm asks it to. Which is why the payload carries
/// finished STRINGS rather than numbers to format: the widget must be able to
/// say "الفجر · 4:32" at three in the morning with no Dart alive to ask.
///
/// Android only. Everywhere else this is a no-op and the app is none the wiser.
class PrayerWidgetBridge {
  PrayerWidgetBridge._() {
    if (supported) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'pinned') _pinned.add(null);
      });
    }
  }
  static final instance = PrayerWidgetBridge._();

  /// Matches `PrayerWidgetPlugin.CHANNEL` on the Kotlin side.
  static const _channel = MethodChannel(
    'com.shud.hajjoperations/prayer_widget',
  );

  final _pinned = StreamController<void>.broadcast();

  /// Fires when a copy of the widget has just been placed.
  ///
  /// [requestPin] cannot answer this. It returns the moment the launcher's
  /// dialog is put on screen, which is before the reader has decided anything —
  /// so a count read off the back of it is a count taken during the question,
  /// not after the answer. Android fires this instead, once, only on a yes.
  ///
  /// It is not the ONLY way a widget appears: one dragged out of the launcher's
  /// own tray with this app closed arrives with nothing listening. So this is
  /// the fast path, not the source of truth — [installedCount] still is.
  Stream<void> get pinned => _pinned.stream;

  /// Whether there is a home screen to put a widget on.
  ///
  /// Public because the no-op is not enough on its own: every call below is
  /// safe everywhere, but a SETTINGS PANE offering to place a widget is not
  /// something a no-op can rescue — it has to not be drawn. See
  /// [PrayerWidgetSection.available].
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Hands the widget everything it needs for the next week and asks every
  /// instance of it to redraw.
  ///
  /// Never throws: a launcher with no widget on it, an OEM that refuses the
  /// broadcast, a channel that is not there in a unit test — none of it should
  /// disturb the app, and none of it is something the reader can act on.
  Future<void> push(Map<String, Object?> payload) async {
    if (!supported) return;
    try {
      await _channel.invokeMethod<void>('update', jsonEncode(payload));
    } catch (e) {
      AppLogger.warn('prayer', 'widget update failed: $e');
    }
  }

  /// How many copies of the widget the reader has placed. Zero means the work
  /// of building a payload is wasted — and, more usefully, that an offer to
  /// "add it to your home screen" is worth showing.
  Future<int> installedCount() async {
    if (!supported) return 0;
    try {
      return await _channel.invokeMethod<int>('count') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Asks Android to run its own "pin this widget" dialog, where the launcher
  /// supports one. Returns false when it does not — the reader then has to
  /// long-press the home screen themselves, and the UI says so rather than
  /// showing a button that does nothing.
  Future<bool> requestPin() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('pin') ?? false;
    } catch (_) {
      return false;
    }
  }
}
