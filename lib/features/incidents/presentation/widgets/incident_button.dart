import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/glass_tokens.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../auth/application/session_cubit.dart';

/// The way out, from wherever you are standing.
///
/// 0088 built the urgent report around one sentence: "a report that took thirty
/// seconds to compose is a report that was never sent." Everything about the
/// form obeys it — one line of text, no category, nothing else required.
///
/// And then it was reachable from exactly one place: a full-width red slab on
/// the home page. From anywhere else in the app that is back, back, read the
/// page, press — which spends the thirty seconds the form was designed not to
/// spend, before the form opens. The rule was right and the door was in the
/// wrong place.
///
/// So it sits in the app bar, on every screen that uses [GlassAppBar], in the
/// same position on every one of them. Not a floating button: several screens
/// already have one of those, and an emergency that lands underneath the "add"
/// button on some screens and beside it on others is not a fixed point — which
/// is the entire property being bought here.
///
/// ## Why it is a chip and not a bare icon
///
/// It was a bare red glyph among grey ones for a while, which is the shape this
/// control can least afford. A row of icons in an app bar is read as "the
/// things this SCREEN does"; an emergency belongs to none of them, and one
/// tinted glyph in that row does not say so loudly enough to be found by
/// somebody who has just watched a coach go into a barrier.
///
/// A filled chip in the error container reads as a different KIND of thing at
/// arm's length, before a word of it is read — and it carries its own name
/// wherever the window has room for one. Below [WindowSize.medium] the label
/// goes and the chip does not: a phone app bar holding a back arrow, a title
/// and two other actions has room for a 40-pixel mark and not for four words,
/// and the mark is the half that is recognised anyway.
class IncidentButton extends StatelessWidget {
  const IncidentButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!_approved(context)) return const SizedBox.shrink();

    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // Measured from the WINDOW rather than from this bar's own box: an app bar
    // is as wide as the window and has no useful constraints of its own to ask
    // about.
    final roomForWords = context.windowSize.isAtLeast(WindowSize.medium);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      child: Material(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: () {
            // The one press in this app that is worth a buzz on its own: it is
            // made in a hurry, often without looking, and the person needs to
            // know it landed before the screen has finished opening.
            HapticFeedback.mediumImpact();
            context.push(Routes.raiseIncident);
          },
          child: Tooltip(
            // The same words as the screen it opens. Two doors into one thing
            // should not have two names.
            message: l.incidentTitle,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: roomForWords ? AppSpacing.md : AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.warning,
                    size: 20,
                    color: scheme.onErrorContainer,
                  ),
                  if (roomForWords) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l.incidentTitle,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
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
