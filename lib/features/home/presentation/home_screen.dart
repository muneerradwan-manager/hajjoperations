import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animations/animations.dart';
import '../../../core/constants/permission_codes.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_accents.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/utils/hijri_utils.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/states.dart';
import '../../auth/application/session_cubit.dart';
import '../../notifications/presentation/widgets/notification_bell.dart';
import '../../prayer_times/application/prayer_times_cubit.dart';
import '../../prayer_times/data/prayer_times_repository.dart';
import '../../prayer_times/presentation/widgets/prayer_times_card.dart';
import '../../seasons/data/seasons_repository.dart';
import 'widgets/dashboard_card.dart';

/// Accent per destination, so a returning user recognises a tile by its colour
/// before they finish reading the label — which only works if no two tiles
/// share one. Three of them did: the files, their office and the employees were
/// all the same green, and the colour told you nothing.
///
/// Eight destinations, eight of the nine brand colours, and the families carry
/// the meaning:
///
///   * GREEN — the mission's own work and its people. It stays the app's
///     primary; it is the backdrop, the theme and three of these seven.
///   * GOLD — the calendar and the reference material: the season, and the
///     lists everything else is built from.
///   * RED — the two screens that decide about people, and — in the deepest of
///     the reds, the one colour that had never been given a legible pair — the
///     dashboard, which decides nothing and is about all of it.
///
/// Each is an [Accent] rather than a raw brand colour, because a print palette
/// does not divide evenly across a night mode and a paper one: every red is
/// unreadable on the dark backdrop and every gold on the light. See
/// app_accents.dart for the measurements.
const _work = Accent.green;

/// The الإدارة tiles, two to a colour.
///
/// Grouped rather than one-per-tile: eight different colours in one grid is a
/// swatch card, not a menu. A pair shares a colour because the two of them are
/// one kind of thing — the paperwork, the people, the year and its lists, and
/// oversight — so the colour says something rather than merely differing.
const _adminPalette = <Accent>[
  Accent.greenDeep,
  Accent.greenDark,
  Accent.gold,
  Accent.redDeep,
];

/// One beat of the entry cascade.
const _step = Duration(milliseconds: 70);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _seasons = SeasonsRepository();

  /// Owned by the screen rather than created inside the card, so that the
  /// pull-to-refresh gesture — which is handled up here, above anything the
  /// card could provide — can reach it.
  late final _prayer = PrayerTimesCubit(PrayerTimesRepository());

  /// The Hijri year shown on the greeting badge. Starts from the device
  /// calendar so the panel is never blank, then settles on whichever season is
  /// actually current — an admin may have switched it to an earlier one.
  int _seasonYear = HijriUtils.currentYear();

  @override
  void initState() {
    super.initState();
    _loadCurrentSeason();
  }

  @override
  void dispose() {
    _prayer.close();
    super.dispose();
  }

  Future<void> _loadCurrentSeason() async {
    try {
      final season = await _seasons.fetchCurrentSeason();
      if (season != null && mounted) {
        setState(() => _seasonYear = season.hijriYear);
      }
    } catch (_) {
      // Keep the calendar-derived fallback.
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<SessionCubit>().reload(),
      _loadCurrentSeason(),
      // Never prompts. A drag on a list is a request for newer numbers, not a
      // gesture anybody would expect to raise a permission dialog.
      _prayer.refresh(),
    ]);
  }

  Future<void> _openSeasons() async {
    await context.push(Routes.seasons);
    // The current season may have been switched while in there.
    await _loadCurrentSeason();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = context.watch<SessionCubit>().state;
    final profile = session.profile;

    final canApprove = session.can(PermissionCodes.approvalsView);
    final canManagePermissions = session.can(PermissionCodes.permissionsView);
    final canViewEmployees = session.can(PermissionCodes.employeesView);
    final canManageReferenceData = session.can(PermissionCodes.referenceView);

    final canSeeSeasons = session.canSeeSeasons;
    final canManageModules = session.can(PermissionCodes.modulesViewAll);
    final canManageReports = session.can(PermissionCodes.reportsViewAll);

    // The dashboard has a section per permission and drops the rest, so the
    // door opens for anyone holding any one of them. Listed here rather than
    // asked of the page, because a tile that leads to an empty page is worse
    // than no tile.
    final canSeeDashboard =
        canViewEmployees ||
        canApprove ||
        canManageModules ||
        session.can(PermissionCodes.modulesMembers);

    // Everything held by a PERMISSION, the dashboard among them. A person is
    // two things at once here — somebody with authority and somebody with work
    // — and the two were mixed in one list: "الملفات التشغيلية" meant his own
    // postings to one man and the season's whole paperwork to another,
    // depending on what he held. Authority lives here; the work lives below.
    //
    // Declared as entries rather than built as widgets, because the COLOUR is
    // not a property of the entry — it is a property of where the entry lands
    // once the reader's permissions have been applied. See [_adminPalette].
    final admin = <({IconData icon, String title, String subtitle, VoidCallback onTap})>[
      // Paired by meaning as well as by position: the paperwork, the people,
      // the year and its lists, then oversight. Two to a colour, in this order.
      if (canManageModules)
        (
          icon: AppIcons.modules,
          title: l.navModulesManage,
          subtitle: l.navModulesManageSubtitle,
          onTap: () => context.push(Routes.modulesManage),
        ),
      if (canManageReports)
        (
          icon: AppIcons.reports,
          title: l.navReportsManage,
          subtitle: l.navReportsManageSubtitle,
          onTap: () => context.push(Routes.reportsManage),
        ),
      if (canViewEmployees)
        (
          icon: AppIcons.employees,
          title: l.navEmployees,
          subtitle: l.navEmployeesSubtitle,
          onTap: () => context.push(Routes.employees),
        ),
      if (canApprove)
        (
          icon: AppIcons.approvals,
          title: l.navApprovals,
          subtitle: l.navApprovalsSubtitle,
          onTap: () => context.push(Routes.approvals),
        ),
      if (canSeeSeasons)
        (
          icon: AppIcons.seasons,
          title: l.navSeasons,
          subtitle: l.navSeasonsSubtitle,
          onTap: _openSeasons,
        ),
      if (canManageReferenceData)
        (
          icon: AppIcons.referenceData,
          title: l.navReferenceData,
          subtitle: l.navReferenceDataSubtitle,
          onTap: () => context.push(Routes.referenceData),
        ),
      if (canManagePermissions)
        (
          icon: AppIcons.permissions,
          title: l.navPermissions,
          subtitle: l.navPermissionsSubtitle,
          onTap: () => context.push(Routes.permissions),
        ),
      // No longer standing apart beside the greeting. It is one of these — the
      // season from above — and eight tiles in a list read better than seven
      // and an orphan.
      if (canSeeDashboard)
        (
          icon: AppIcons.dashboard,
          title: l.navDashboard,
          subtitle: l.navDashboardSubtitle,
          onTap: () => context.push(Routes.dashboard),
        ),
      // The dashboard's pair, and the pairing is the meaning: one is the
      // season from above, the other is the season act by act. Together they
      // are the oversight colour.
      if (session.can(PermissionCodes.auditView))
        (
          icon: AppIcons.auditLog,
          title: l.navAuditLog,
          subtitle: l.navAuditLogSubtitle,
          onTap: () => context.push(Routes.auditLog),
        ),
    ];

    // Two tiles to a colour, by POSITION in the list the reader actually gets.
    //
    // Which is why the colour could not be written beside each entry: a reader
    // without `approvals.decide` is shown seven tiles, not eight, and every
    // pair after the missing one shifts. Assigning here — after the list is
    // filtered — is what keeps the pairs paired.
    //
    // The rule reads the same in both arrangements the page uses: side by side
    // on two columns, one above the other on one.
    final adminCards = <Widget>[
      for (var i = 0; i < admin.length; i++)
        DashboardCard(
          icon: admin[i].icon,
          title: admin[i].title,
          subtitle: admin[i].subtitle,
          color: _adminPalette[(i ~/ 2) % _adminPalette.length].of(context),
          onTap: admin[i].onTap,
        ),
    ];

    // The work, and it is everybody's: a file reaches its members through
    // assignment, not through a permission. This card lists what THIS person
    // was put into — the same handful for a manager as for anyone else, because
    // being allowed to open every file does not make every file his work.
    final generalCards = <Widget>[
      DashboardCard(
        icon: AppIcons.modules,
        title: l.navModules,
        subtitle: l.navModulesSubtitle,
        color: _work.of(context),
        onTap: () => context.push(Routes.modules),
      ),
      // Published to everybody, and gated by nothing: مواعيد الوجبات is not
      // an assignment, it is information the whole mission needs. Reading is
      // open to any approved account; entering one is what needs a permission.
      DashboardCard(
        icon: AppIcons.reports,
        title: l.navReports,
        subtitle: l.navReportsSubtitle,
        color: _work.of(context),
        onTap: () => context.push(Routes.reports),
      ),
      // No tile for the profile: the greeting panel above already carries the
      // user's face and name, and tapping a card with your own name on it is
      // where anyone looks for it first.
    ];

    // Provided here rather than inside the card, so that `_refresh` — which
    // lives above anything the card could provide — can reach the same cubit.
    return BlocProvider.value(
      value: _prayer,
      child: Scaffold(
        // Content frosts as it passes under the bar instead of vanishing behind
        // an opaque strip.
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          title: Text(l.homeTitle),
          automaticallyImplyLeading: false,
          // Settings on the leading side, the bell on the trailing one: two
          // things, at opposite ends, neither buried in a menu. Logging out moved
          // into settings, where a confirmation can sit beside it.
          leading: IconButton(
            tooltip: l.commonSettings,
            onPressed: () => context.push(Routes.settings),
            icon: const Icon(AppIcons.settings),
          ),
          actions: const [NotificationBell()],
        ),
        body: Builder(
          // Inside the Scaffold body, so `scrollPadding` sees the inset the
          // Scaffold reserves for the app bar it is extending behind.
          builder: (context) => ResponsivePage(
            builder: (context, size) {
              // The admin header's beat, which depends on how many tiles the
              // cascade has already spent above it — the dashboard band included,
              // since it arrives before the first heading does.
              final adminBeat = _step * (3 + generalCards.length);

              // Not a tile among the tiles. Every other card on this screen is a
              // place to go and do something; this one is about all of them at
              // once, and standing it in a row of three as the leftmost of equals
              // said the opposite. So it gets a row of its own, above the first
              // heading — and where there is a panel, it goes in the panel under
              // the greeting, which is the other thing on this screen that is
              // about the season rather than about a task.
              //
              final sections = <Widget>[
                FadeSlideIn(
                  delay: _step * 2,
                  child: SectionHeader(l.homeGeneralSection),
                ),
                AdaptiveGrid(
                  children: staggered(generalCards, start: _step * 3),
                ),
                if (adminCards.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  FadeSlideIn(
                    delay: adminBeat,
                    child: SectionHeader(
                      l.homeAdminSection,
                      icon: AppIcons.shield,
                    ),
                  ),
                  AdaptiveGrid(
                    children: staggered(adminCards, start: adminBeat + _step),
                  ),
                ],
              ];

              final greeting = _GreetingPanel(
                name: profile?.firstName ?? '',
                subtitle: profile?.jobTitleName?.of(context),
                photoUrl: profile?.photoUrl,
                isAdmin: session.isAdmin,
                seasonYear: _seasonYear,
                onTap: () => context.push(Routes.myProfile),
                layout: switch (size) {
                  // Beside the tiles it is a tall, narrow card, so the face goes
                  // on top of the name rather than beside it.
                  _ when size.hasSidePanel => _GreetingLayout.column,
                  // One column, but a thousand pixels of it: the badges come up
                  // onto the name's line instead of leaving that line half empty
                  // and sitting under a divider of their own.
                  _ when size.isAtLeast(WindowSize.expanded) =>
                    _GreetingLayout.wide,
                  _ => _GreetingLayout.stacked,
                },
              );

              // Under the greeting, and above the first heading, in both
              // arrangements — because it belongs to the same half of this screen
              // that the greeting does. Everything below a heading is a place to
              // go; these two are facts about the moment the reader is standing
              // in. Where there is a panel it stands in the panel for exactly
              // that reason, beside the season badge rather than among the tiles.
              const prayer = PrayerTimesCard();

              return size.hasSidePanel
                  ? TwoPaneLayout(
                      gutter: size.gutter,
                      panel: FadeSlideIn(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            greeting,
                            const SizedBox(height: AppSpacing.md),
                            prayer,
                          ],
                        ),
                      ),
                      onRefresh: _refresh,
                      children: sections,
                    )
                  : SinglePaneLayout(
                      gutter: size.gutter,
                      onRefresh: _refresh,
                      children: [
                        FadeSlideIn(child: greeting),
                        const SizedBox(height: AppSpacing.md),
                        // The beat between the greeting and the first heading,
                        // which the cascade had left empty.
                        const FadeSlideIn(delay: _step, child: prayer),
                        const SizedBox(height: AppSpacing.xl),
                        ...sections,
                      ],
                    );
            },
          ),
        ),
      ),
    );
  }
}

/// How much room the greeting has, which decides whether the face sits beside
/// the name or above it, and where the badges go.
enum _GreetingLayout {
  /// A phone's width: face beside name, badges on their own line below.
  stacked,

  /// A wide single column: badges move up onto the name's line, because a
  /// thousand-pixel row with a name at one end and nothing at the other is the
  /// emptiness this whole layout exists to remove.
  wide,

  /// A tall, narrow panel beside the tiles: face above name, everything
  /// centred.
  column,
}

/// The screen's anchor: who you are, what you do, and which season the
/// Administration is currently working through.
///
/// It is also the way into your own profile — a card showing your face and your
/// name is where anyone reaches for that, so a separate tile below would be a
/// second door to the same room.
class _GreetingPanel extends StatelessWidget {
  const _GreetingPanel({
    required this.name,
    required this.subtitle,
    required this.photoUrl,
    required this.isAdmin,
    required this.seasonYear,
    required this.onTap,
    required this.layout,
  });

  final String name;
  final String? subtitle;
  final String? photoUrl;
  final bool isAdmin;

  /// Hijri year of the season the Administration is currently working through.
  final int seasonYear;

  final VoidCallback onTap;

  final _GreetingLayout layout;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.xl),
      onTap: onTap,
      child: switch (layout) {
        _GreetingLayout.column => _column(context),
        _ => _row(context),
      },
    );
  }

  Widget _row(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final inlineBadges = layout == _GreetingLayout.wide;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Ring(photoUrl: photoUrl, name: name, radius: 28),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _Identity(name: name, subtitle: subtitle),
            ),
            if (inlineBadges) ...[
              const SizedBox(width: AppSpacing.lg),
              _Badges(isAdmin: isAdmin, seasonYear: seasonYear),
              const SizedBox(width: AppSpacing.lg),
            ] else
              const SizedBox(width: AppSpacing.sm),
            const NavChevron(),
          ],
        ),
        if (!inlineBadges) ...[
          const SizedBox(height: AppSpacing.lg),
          Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.md),
          _Badges(isAdmin: isAdmin, seasonYear: seasonYear),
        ],
      ],
    );
  }

  Widget _column(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: _Ring(photoUrl: photoUrl, name: name, radius: 40),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Identity(
          name: name,
          subtitle: subtitle,
          align: CrossAxisAlignment.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
        const SizedBox(height: AppSpacing.md),
        _Badges(
          isAdmin: isAdmin,
          seasonYear: seasonYear,
          alignment: WrapAlignment.center,
        ),
        const SizedBox(height: AppSpacing.md),
        // The chevron cannot sit at the end of a row that no longer exists, so
        // the way in is spelled out along the card's bottom edge instead.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l.navMyProfile,
              style: text.labelSmall?.copyWith(color: scheme.primary),
            ),
            NavChevron(color: scheme.primary),
          ],
        ),
      ],
    );
  }
}

/// The avatar in its brand-gradient ring, which reads as a status halo.
class _Ring extends StatelessWidget {
  const _Ring({
    required this.photoUrl,
    required this.name,
    required this.radius,
  });

  final String? photoUrl;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.secondary],
        ),
      ),
      child: ProfileAvatar(photoUrl: photoUrl, name: name, radius: radius),
    );
  }
}

/// The name, the job title, and — in the row forms — the line that says where
/// tapping the card goes, now that the tile which used to say it is gone.
class _Identity extends StatelessWidget {
  const _Identity({
    required this.name,
    required this.subtitle,
    this.align = CrossAxisAlignment.start,
  });

  final String name;
  final String? subtitle;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final centred = align == CrossAxisAlignment.center;
    final textAlign = centred ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          l.homeWelcome(name),
          style: text.titleLarge,
          textAlign: textAlign,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: textAlign,
            maxLines: centred ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (!centred) ...[
          const SizedBox(height: 4),
          Text(
            l.navMyProfile,
            style: text.labelSmall?.copyWith(color: scheme.primary),
          ),
        ],
      ],
    );
  }
}

/// The season the Administration is working through, and whether this person
/// runs it.
class _Badges extends StatelessWidget {
  const _Badges({
    required this.isAdmin,
    required this.seasonYear,
    this.alignment = WrapAlignment.start,
  });

  final bool isAdmin;
  final int seasonYear;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      alignment: alignment,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        GlassBadge(
          label: l.seasonHijriYear(seasonYear),
          color: scheme.secondary,
          icon: AppIcons.seasons,
        ),
        if (isAdmin)
          GlassBadge(
            label: l.profileBadgeAdmin,
            color: scheme.primary,
            icon: AppIcons.shield,
          ),
      ],
    );
  }
}
