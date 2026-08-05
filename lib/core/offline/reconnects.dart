import 'package:connectivity_plus/connectivity_plus.dart';

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
Stream<void> platformReconnects() => Connectivity().onConnectivityChanged
    .where((results) => results.any(_isConnected))
    .map((_) {});

bool _isConnected(ConnectivityResult result) =>
    result != ConnectivityResult.none;
