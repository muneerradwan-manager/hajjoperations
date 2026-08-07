import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../auth/application/session_cubit.dart';

/// The way out, from wherever you are standing.
///
/// 0088 built the urgent report around one sentence: "a report that took thirty
/// seconds to compose is a report that was never sent." Everything about the
/// form obeys it — one line of text, no category, nothing else required.
///
/// And then it was reachable from exactly one place: a button on the home page,
/// one of twenty-five destinations. From anywhere else in the app that is back,
/// back, read the tiles, press — which spends the thirty seconds the form was
/// designed not to spend, before the form opens. The rule was right and the
/// door was in the wrong place.
///
/// So it sits in the app bar, on all forty-nine screens that use [GlassAppBar],
/// in the same position on every one of them. Not a floating button: eight
/// screens already have one of those, and an emergency that lands underneath
/// the "add" button on some screens and beside it on others is not a fixed
/// point — which is the entire property being bought here.
class IncidentButton extends StatelessWidget {
  const IncidentButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!_approved(context)) return const SizedBox.shrink();

    return IconButton(
      // The same words as the screen it opens, and the same words as the tile
      // on the home page. Three doors into one thing should not have three
      // names.
      tooltip: context.l10n.incidentTitle,
      onPressed: () => context.push(Routes.raiseIncident),
      icon: Icon(AppIcons.warning, color: Theme.of(context).colorScheme.error),
    );
  }

  /// Whether there is an approved session to raise a report from.
  ///
  /// Absent is a legitimate answer, not an error, and that is why this is
  /// wrapped rather than read directly. [GlassAppBar] is generic chrome: it is
  /// on the login screen, on the registration screen and on all three
  /// pre-approval status screens, none of which sit under a [SessionCubit] in
  /// the way this needs — and it is built by widget tests inside a bare
  /// `MaterialApp` with no providers at all. A piece of app furniture that
  /// throws when it cannot find a session is furniture that decides where it
  /// may be put.
  ///
  /// The gate itself is not cosmetic. `raise_incident` refuses anybody who is
  /// not approved (0088), so an unapproved account pressing this would reach
  /// the form, type out an emergency, and be told no by the database at the
  /// last possible moment.
  bool _approved(BuildContext context) {
    // Caught broadly on purpose. The failure being handled is
    // `ProviderNotFoundException`, which lives in `provider` — a package this
    // one does not depend on directly, only through flutter_bloc, and naming a
    // transitive package's type here would tie this widget to how flutter_bloc
    // happens to get its own work done. The body is a single lookup, so there
    // is nothing else in here for a broad catch to hide.
    try {
      return context.watch<SessionCubit>().state.status ==
          SessionStatus.approved;
    } catch (_) {
      return false;
    }
  }
}
