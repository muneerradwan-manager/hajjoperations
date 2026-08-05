import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'app_logger.dart';

/// Routes every error the app can throw into the console, and — where there is
/// a crash reporter to route it to — out of the device as well.
///
/// There are three separate channels and none of them catches the others:
///
///   * [FlutterError.onError] — anything thrown inside the framework: a bad
///     build, a failed layout, an overflow;
///   * [PlatformDispatcher.instance.onError] — an unhandled async error that
///     reached the engine, typically a Future nobody awaited;
///   * the zone handler in `main`, for what is thrown outside both.
///
/// Called once, from `bootstrap`.
void installErrorLogging() {
  final previous = FlutterError.onError;

  FlutterError.onError = (details) {
    AppLogger.error(
      'flutter',
      details.summary.toString(),
      details.exception,
      details.stack,
    );
    CrashReporting.recordFlutterError(details);
    // Still handed on: the default handler is what prints the red box in a
    // debug build, and losing that would be a poor trade for a log line.
    previous?.call(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('async', 'unhandled', error, stack);
    CrashReporting.record(error, stack, reason: 'unhandled async');
    // False lets it carry on to the platform's own handler.
    return false;
  };
}

/// The way out of the device for an error nobody was there to see.
///
/// A log line is worth something on a desk and nothing at all in Mina. The one
/// question that matters during a season — did the app fail on somebody, and
/// where — has no answer unless the failure travels; so every error the
/// handlers above catch is handed here too, and here decides whether there is
/// anywhere to send it.
///
/// Two things make that decision awkward, and both are dealt with rather than
/// assumed away:
///
///   * **Crashlytics needs Firebase, and Firebase starts late.** `bootstrap`
///     installs the error handlers FIRST, on purpose — so that a failure in
///     everything below them is itself caught — and brings Firebase up after,
///     off the critical path. That leaves a window at start-up during which
///     errors have nowhere to go, and start-up is exactly when the errors you
///     most want to see happen. So they are held in [_pending] and flushed the
///     moment [attach] is called.
///   * **Not every platform has it.** Firebase is configured for Android here;
///     on Windows or the web there is no Firebase app and no Crashlytics
///     plugin behind the channel. [attach] simply fails to attach, the buffer
///     is dropped, and the console remains what it always was. Nothing else in
///     the app has to know which platform it is on.
class CrashReporting {
  const CrashReporting._();

  static FirebaseCrashlytics? _crashlytics;

  /// Errors caught before [attach] ran. Bounded: if a broken build is throwing
  /// on every frame, the useful information is the first few, and an unbounded
  /// list of them is a second failure on top of the first.
  static final List<_PendingError> _pending = [];
  static const _maxPending = 20;

  /// Hands the reporter its destination. Safe to call when Firebase never came
  /// up, and safe to call twice.
  ///
  /// Collection stays OFF in debug: a developer's own broken widget is not an
  /// incident, and a dashboard full of them is a dashboard nobody reads during
  /// the season it was put there for.
  static Future<void> attach() async {
    if (_crashlytics != null) return;
    try {
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
      _crashlytics = crashlytics;
      AppLogger.info('app', 'crash reporting on');
    } catch (error) {
      AppLogger.info('app', 'no crash reporting on this platform — $error');
    }
    // Either way the buffer has served its purpose and must not grow old.
    final held = List.of(_pending);
    _pending.clear();
    final crashlytics = _crashlytics;
    if (crashlytics == null) return;
    for (final error in held) {
      unawaited(
        crashlytics.recordError(
          error.error,
          error.stack,
          reason: error.reason,
          fatal: error.fatal,
        ),
      );
    }
  }

  /// Names the signed-in account on every report from here on.
  ///
  /// The id and nothing else. It is enough to go and ask the man what he was
  /// doing when it broke, which is the whole purpose, and a crash report is no
  /// place to keep somebody's name and email.
  static void setUser(String? userId) {
    unawaited(_crashlytics?.setUserIdentifier(userId ?? ''));
  }

  /// A note about where the app was, attached to whatever it reports next —
  /// the season, the file being worked on. Turns "it crashed" into "it crashed
  /// on the Mina camps file", which is the difference between a report and a
  /// lead.
  static void setContext(String key, Object? value) {
    unawaited(_crashlytics?.setCustomKey(key, value?.toString() ?? '—'));
  }

  /// A breadcrumb — kept with the next report, showing what the app was doing
  /// in the run-up to it.
  static void log(String message) {
    unawaited(_crashlytics?.log(message));
  }

  static void recordFlutterError(FlutterErrorDetails details) {
    final crashlytics = _crashlytics;
    if (crashlytics == null) {
      _hold(
        _PendingError(
          details.exception,
          details.stack,
          reason: details.summary.toString(),
        ),
      );
      return;
    }
    unawaited(crashlytics.recordFlutterError(details));
  }

  /// Reports an error the app caught itself — a repository call that failed, a
  /// state a cubit could not recover from. [fatal] marks the ones that ended
  /// what the user was doing, rather than the ones merely logged on the way
  /// past.
  static void record(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) {
    final crashlytics = _crashlytics;
    if (crashlytics == null) {
      _hold(_PendingError(error, stack, reason: reason, fatal: fatal));
      return;
    }
    unawaited(
      crashlytics.recordError(error, stack, reason: reason, fatal: fatal),
    );
  }

  static void _hold(_PendingError error) {
    if (_pending.length >= _maxPending) return;
    _pending.add(error);
  }

  /// For tests, which must not carry one test's buffer into the next.
  @visibleForTesting
  static void resetForTest() {
    _crashlytics = null;
    _pending.clear();
  }

  @visibleForTesting
  static int get pendingCount => _pending.length;
}

class _PendingError {
  const _PendingError(this.error, this.stack, {this.reason, this.fatal = false});

  final Object error;
  final StackTrace? stack;
  final String? reason;
  final bool fatal;
}
