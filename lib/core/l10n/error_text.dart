import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import 'l10n_extension.dart';

/// Turns a cubit's stored error string into something a person can read.
///
/// Cubits keep `e.toString()`; unfiltered, a dead connection surfaced as
/// `ClientException with SocketException: Failed host lookup…` — raw English
/// exception text as the headline of an Arabic screen. Anything that smells
/// like the network being down becomes the localized "couldn't reach the
/// server"; everything else passes through, because a real server message
/// ("this reference item is in use") is worth more than a generic apology.
String friendlyError(BuildContext context, String? raw) =>
    friendlyErrorL(context.l10n, raw);

/// Same, for call sites past an async gap: they capture [AppLocalizations]
/// before the await and hand it in, instead of touching the context after.
String friendlyErrorL(AppLocalizations l, String? raw) {
  if (raw == null || raw.trim().isEmpty) return l.commonGenericError;
  final s = raw.toLowerCase();
  const networkSmells = [
    'socketexception',
    'clientexception',
    'failed host lookup',
    'connection refused',
    'connection reset',
    'connection closed',
    'network is unreachable',
    'timeoutexception',
    'handshakeexception',
    'operation timed out',
  ];
  for (final smell in networkSmells) {
    if (s.contains(smell)) return l.commonConnectionErrorTitle;
  }
  return raw;
}
