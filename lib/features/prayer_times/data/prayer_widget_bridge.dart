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
  PrayerWidgetBridge._();
  static final instance = PrayerWidgetBridge._();

  /// Matches `PrayerWidgetPlugin.CHANNEL` on the Kotlin side.
  static const _channel = MethodChannel('com.shud.hajjoperations/prayer_widget');

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Hands the widget everything it needs for the next week and asks every
  /// instance of it to redraw.
  ///
  /// Never throws: a launcher with no widget on it, an OEM that refuses the
  /// broadcast, a channel that is not there in a unit test — none of it should
  /// disturb the app, and none of it is something the reader can act on.
  Future<void> push(Map<String, Object?> payload) async {
    if (!_supported) return;
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
    if (!_supported) return 0;
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
    if (!_supported) return false;
    try {
      return await _channel.invokeMethod<bool>('pin') ?? false;
    } catch (_) {
      return false;
    }
  }
}
