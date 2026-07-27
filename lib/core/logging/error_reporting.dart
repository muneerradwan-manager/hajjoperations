import 'package:flutter/foundation.dart';

import 'app_logger.dart';

/// Routes every error the app can throw into the console.
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
    // Still handed on: the default handler is what prints the red box in a
    // debug build, and losing that would be a poor trade for a log line.
    previous?.call(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('async', 'unhandled', error, stack);
    // False lets it carry on to the platform's own handler.
    return false;
  };
}
