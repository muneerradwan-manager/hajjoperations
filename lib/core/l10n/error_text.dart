import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../utils/network_error.dart';
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
  // The same list the outbox decides retries by — see [looksLikeNetworkFailure].
  // Kept in one place because the two must agree: a failure this calls "the
  // connection" is exactly the failure that ought to be tried again.
  if (looksLikeNetworkFailure(raw)) return l.commonConnectionErrorTitle;
  // Codes the admin-set-email function answers with. They arrive wrapped in
  // exception text ("FunctionException(status: 400, details: {error:
  // email_taken}…)"), so this matches by substring like the smells above.
  if (s.contains('email_taken')) return l.employeeEmailTaken;
  if (s.contains('cannot_set_admin_email')) return l.employeeEmailAdminBlocked;
  // The reports trigger (0078) refusing a second once-per-season report. The
  // editor blocks this before saving, so this is the belt behind the braces —
  // a stale list, or two people entering the same document at once.
  if (s.contains('report_once_per_season')) return l.reportOncePerSeason;
  // The complaints migration (0079). The form blocks the first three before
  // sending, so these are the belt behind the braces; `complaint_locked` is the
  // one that genuinely reaches a person, when somebody closed the thread while
  // they were typing into it.
  // The check-in guard (0094). The sheet blocks this before sending — the
  // button is dead until a place is named — so this is the belt behind the
  // braces: an outbox entry queued by an older build, or a file whose places
  // were deleted between the pick and the send.
  if (s.contains('check_in_needs_a_place')) return l.checkInNeedsAPlace;
  if (s.contains('check_in_node_mismatch')) return l.checkInWrongFile;
  if (s.contains('complaint_locked')) return l.complaintLocked;
  if (s.contains('complaint_body_required')) return l.complaintBodyRequired;
  if (s.contains('complaint_target_missing') ||
      s.contains('complaint_target_wrong_set')) {
    return l.complaintTargetRequired;
  }
  if (s.contains('complaint_not_found')) return l.complaintMissing;
  // The evaluations migration (0084). The form and the fill screen block most
  // of these before sending, so these are the belt behind the braces — except
  // `evaluation_incomplete`, which the fill screen raises itself as a code so
  // that one sentence answers both the local refusal and the server's.
  if (s.contains('evaluation_incomplete')) return l.evaluationIncomplete;
  if (s.contains('evaluation_already_submitted')) {
    return l.evaluationAlreadySubmitted;
  }
  if (s.contains('evaluation_not_found') ||
      s.contains('evaluation_form_not_found')) {
    return l.evaluationMissing;
  }
  if (s.contains('evaluation_form_in_use')) return l.evaluationEditorForLocked;
  if (s.contains('evaluation_option_worth_more_than_question')) {
    return l.evaluationErrorOptionTooHigh;
  }
  if (s.contains('evaluation_written_question_takes_no_options')) {
    return l.evaluationErrorWrittenHasOptions;
  }
  return raw;
}
