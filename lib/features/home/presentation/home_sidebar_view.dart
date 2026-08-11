import 'package:flutter/material.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/responsive.dart';
import '../../auth/application/session_cubit.dart';
import '../../notifications/presentation/widgets/notification_bell.dart';
import '../../outbox/presentation/widgets/outbox_badge.dart';
import 'widgets/home_pieces.dart';
import 'widgets/season_roadmap_view.dart';

/// The home page under the sidebar arrangement: the season's roadmap, and
/// nothing that the rail beside it already carries.
///
/// The rail itself is NOT here. It belongs to [AppShell], one level above the
/// router's navigator, so that it survives every page this app can open rather
/// than being rebuilt each time somebody comes back to the roadmap. What is
/// left in this file is a page like any other — which is exactly what it should
/// have been from the start.
class HomeSidebarView extends StatelessWidget {
  const HomeSidebarView({
    super.key,
    required this.session,
    required this.onRefresh,
  });

  final SessionState session;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text(l.roadmapTitle),
        // Nothing in the leading slot of its own. On a wide window there is a
        // rail standing where a leading control would be; on a narrow one the
        // bar puts the menu button there itself — see the shell scope
        // [GlassAppBar] reads. Settings has moved into the rail's foot either
        // way, which is where a menu keeps it.
        actions: const [OutboxBadge(), NotificationBell()],
      ),
      body: Builder(
        // Inside the Scaffold body so `scrollPadding` sees the inset the
        // Scaffold reserves for the bar it is extending behind.
        builder: (context) => ResponsivePage(
          // Narrower than the window class would allow, because what is on this
          // page is PROSE. The roadmap is five paragraphs and twenty-four
          // explanations, and a line of text stops being readable past roughly
          // seventy characters — on the way back the eye loses which line comes
          // next. On a 1920 monitor the pane left over beside the rail is 1600
          // wide, and 1600 is two and a half of those.
          //
          // The other screens in this app cap at their window class because
          // their content is CARDS, which tile; this one caps at a column
          // because its content is read.
          builder: (context, size) => SinglePaneLayout(
            gutter: size.gutter,
            onRefresh: onRefresh,
            children: [
              // No greeting card here, and its absence is the point.
              //
              // The face, the name, the job title and both of today's dates are
              // in the rail, on the glass at all times. Drawing them again at
              // the top of the page would be the same duplication the roadmap
              // replaced the guide to escape — and it would push the first
              // phase of the season below the fold to say something the reader
              // is already looking at.
              //
              // What stays is the moment: the coming prayer, and the red
              // button. Neither is in the rail, and neither could be — one is a
              // fact that changes through the day and the other is an act that
              // must be a hand's width from the thumb on every screen.
              const MomentPanel(),
              const SizedBox(height: AppSpacing.xl),
              SeasonRoadmapView(session: session),
            ],
          ),
        ),
      ),
    );
  }
}
