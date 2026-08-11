import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/states.dart';
import '../../auth/application/session_cubit.dart';
import '../../notifications/presentation/widgets/notification_bell.dart';
import '../../outbox/presentation/widgets/outbox_badge.dart';
import '../domain/home_destinations.dart';
import 'widgets/dashboard_card.dart';
import 'widgets/greeting_panel.dart';
import 'widgets/home_pieces.dart';

/// One beat of the entry cascade.
const _step = Duration(milliseconds: 70);

/// The original home page, and still the default: every door this person holds,
/// laid out on the page at once.
///
/// Nothing about it has changed except where its list comes from. It used to
/// declare its own doors inline; it now reads [homeDestinations], which is what
/// lets the sidebar arrangement offer exactly the same set under exactly the
/// same permissions. See the head of that file.
class HomeGridView extends StatelessWidget {
  const HomeGridView({
    super.key,
    required this.session,
    required this.onRefresh,
  });

  final SessionState session;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final profile = session.profile;

    final destinations = homeDestinations(session, l);
    final shelves = homeShelves(destinations);

    // العام, drawn full-width with its explanation on the card. Three or four
    // tiles can afford to explain themselves.
    final generalCards = <Widget>[
      for (final d in destinations)
        if (d.group == HomeGroup.general)
          DashboardCard(
            icon: d.icon,
            title: d.title,
            subtitle: d.subtitle,
            color: d.colorOf(context),
            onTap: () => context.push(d.route),
            action: d.action == null ? null : () => context.push(d.action!),
            actionTooltip: d.actionLabel,
            actionIcon: d.actionIcon,
          ),
    ];

    // الإدارة, shelf by shelf, in small tiles: a reader with every permission
    // is handed a dozen of these, and twelve full-width rows is four screens of
    // scrolling. The explanation comes off the tile and onto the shelf heading
    // above it — it survives as the tooltip and as what is read aloud.
    final adminShelves = <(HomeGroup, List<Widget>)>[
      for (final shelf in shelves)
        if (shelf.group.isAdmin)
          (
            shelf.group,
            [
              for (final d in shelf.destinations)
                CompactDashboardCard(
                  icon: d.icon,
                  title: d.title,
                  subtitle: d.subtitle,
                  color: d.colorOf(context),
                  onTap: () => context.push(d.route),
                ),
            ],
          ),
    ];

    return Scaffold(
      // Content frosts as it passes under the bar instead of vanishing behind
      // an opaque strip.
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text(l.homeTitle),
        automaticallyImplyLeading: false,
        // Settings on the leading side, the bell on the trailing one: two
        // things, at opposite ends, neither buried in a menu. Logging out lives
        // inside settings, where a confirmation can sit beside it.
        leading: IconButton(
          tooltip: l.commonSettings,
          onPressed: () => context.push(Routes.settings),
          icon: const Icon(AppIcons.settings),
        ),
        // The outbox first, and only when it has something in it. What the app
        // is still holding of yours outranks what it has been told.
        actions: const [OutboxBadge(), NotificationBell()],

        // The one bar in the app without the urgent report on it. Every other
        // screen carries it as an icon here because it has nowhere better; this
        // page has somewhere better — the full-width red button below. Two
        // doors to one screen, a hand's width apart, read as two different
        // things.
      ),
      // The emergency button is NOT a floating one — see [RaiseIncidentButton].
      body: Builder(
        // Inside the Scaffold body, so `scrollPadding` sees the inset the
        // Scaffold reserves for the app bar it is extending behind.
        builder: (context) => ResponsivePage(
          builder: (context, size) {
            // The admin header's beat, which depends on how many tiles the
            // cascade has already spent above it.
            final adminBeat = _step * (3 + generalCards.length);

            final sections = <Widget>[
              FadeSlideIn(
                delay: _step * 2,
                child: SectionHeader(l.homeGeneralSection),
              ),
              AdaptiveGrid(children: staggered(generalCards, start: _step * 3)),
              if (adminShelves.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                FadeSlideIn(
                  delay: adminBeat,
                  child: SectionHeader(
                    l.homeAdminSection,
                    icon: AppIcons.shield,
                  ),
                ),
                for (final (group, tiles) in adminShelves) ...[
                  ShelfHeader(
                    title: group.title(l),
                    color: group.accent.of(context),
                  ),
                  AdaptiveGrid(
                    // Small tiles, so the grid is told to pack them: at 340 —
                    // the width a tile with a subtitle and a chevron needs — a
                    // phone gets one column and the whole point of the compact
                    // card is lost. At 150 a phone gets two, a tablet three or
                    // four, and a monitor the four it is capped at.
                    minTileWidth: 150,
                    children: tiles,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ];

            final greeting = GreetingPanel(
              name: profile?.firstName ?? '',
              subtitle: profile?.jobTitleName?.of(context),
              photoUrl: profile?.photoUrl,
              isAdmin: session.isAdmin,
              onTap: () => context.push(Routes.myProfile),
              layout: switch (size) {
                // Beside the tiles it is a tall, narrow card, so the face goes
                // on top of the name rather than beside it.
                _ when size.hasSidePanel => GreetingLayout.column,
                // One column, but a thousand pixels of it: the badges come up
                // onto the name's line instead of leaving that line half empty
                // and sitting under a divider of their own.
                _ when size.isAtLeast(WindowSize.expanded) =>
                  GreetingLayout.wide,
                _ => GreetingLayout.stacked,
              },
            );

            // Under the greeting, and above the first heading, in both
            // arrangements — because it belongs to the same half of this screen
            // that the greeting does. Everything below a heading is a place to
            // go; these two are facts about the moment the reader is standing
            // in. Where there is a panel they stand in the panel for exactly
            // that reason, beside the dates rather than among the tiles.
            const moment = MomentPanel();

            return size.hasSidePanel
                ? TwoPaneLayout(
                    gutter: size.gutter,
                    panel: FadeSlideIn(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          greeting,
                          const SizedBox(height: AppSpacing.md),
                          moment,
                        ],
                      ),
                    ),
                    onRefresh: onRefresh,
                    children: sections,
                  )
                : SinglePaneLayout(
                    gutter: size.gutter,
                    onRefresh: onRefresh,
                    children: [
                      FadeSlideIn(child: greeting),
                      const SizedBox(height: AppSpacing.md),
                      // The beat between the greeting and the first heading,
                      // which the cascade had left empty.
                      const FadeSlideIn(delay: _step, child: moment),
                      const SizedBox(height: AppSpacing.xl),
                      ...sections,
                    ],
                  );
          },
        ),
      ),
    );
  }
}
