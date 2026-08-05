import 'package:connectivity_plus/connectivity_plus.dart';

import '../logging/app_logger.dart';

/// Ticks whenever the device gains a network it did not have.
///
/// This is a HINT and is treated as one. What the platform reports is that a
/// radio has associated with something — not that the something can reach the
/// server, which on a hotel wifi behind a captive portal, or on a cell in Mina
/// carrying ten times its design load, is a different question entirely. The
/// outbox does not trust it: it uses the tick to try, and the attempt is what
/// actually decides. The value of the hint is only that it arrives in the same
/// second the signal comes back, instead of at the end of a backoff.
///
/// Separated behind a plain `Stream<void>` so the queue can be tested without
/// a platform channel — and so that a plugin that misbehaves on one platform
/// can be swapped out without the queue knowing.
/// It also NEVER FAILS, which is the second half of treating it as a hint.
///
/// Watching the network is a platform service, and on Windows the plugin's
/// listener can refuse to start at all — `NetworkManager::StartListen` answering
/// E_INVALIDARG, which arrives as an error on the stream the moment anything
/// subscribes. Unhandled, that error escapes into the framework and is reported
/// as a crash at every start-up: a red trace about connectivity, on a desktop
/// build, because of a feature for a phone in Mina.
///
/// So the error is swallowed here rather than at the subscriber. Losing the
/// hint costs the queue nothing it cannot do without — it still drains when the
/// app starts, when something is added, and when its own backoff timer comes
/// round. All that is lost is the few seconds between a signal returning and
/// the next scheduled try.
Stream<void> platformReconnects() => Connectivity().onConnectivityChanged
    .where((results) => results.any(_isConnected))
    .map((_) {})
    .handleError((Object error) {
      AppLogger.info('outbox', 'cannot watch the network here — $error');
    });

bool _isConnected(ConnectivityResult result) =>
    result != ConnectivityResult.none;
