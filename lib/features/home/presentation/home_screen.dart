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
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/states.dart';
import '../../auth/application/session_cubit.dart';
import '../../notifications/presentation/widgets/notification_bell.dart';
import '../../seasons/data/seasons_repository.dart';
import 'widgets/dashboard_card.dart';

/// Accent per destination, so a returning user recognises a tile by its colour
/// before they finish reading the label — which only works if no two tiles
/// share one. Three of them did: the files, their office and the employees were
/// all the same green, and the colour told you nothing.
///
/// Seven destinations, seven of the nine brand colours, and the families carry
/// the meaning:
///
///   * GREEN — the mission's own work and its people. It stays the app's
///     primary; it is the backdrop, the theme and three of these seven.
///   * GOLD — the calendar and the reference material: the season, and the
///     lists everything else is built from.
///   * RED — the two screens that decide about people.
///
/// Each is an [Accent] rather than a raw brand colour, because a print palette
/// does not divide evenly across a night mode and a paper one: every red is
/// unreadable on the dark backdrop and every gold on the light. See
/// app_accents.dart for the measurements.
const _work = Accent.green;
const _office = Accent.greenDeep;
const _people = Accent.greenDark;
const _season = Accent.gold;
const _reference = Accent.goldSoft;
const _approvals = Accent.red;
const _permissions = Accent.redDeep;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _seasons = SeasonsRepository();

  /// The Hijri year shown on the greeting badge. Starts from the device
  /// calendar so the panel is never blank, then settles on whichever season is
  /// actually current — an admin may have switched it to an earlier one.
  int _seasonYear = HijriUtils.currentYear();

  @override
  void initState() {
    super.initState();
    _loadCurrentSeason();
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

    final canApprove = session.can(PermissionCodes.approvalsDecide);
    final canManagePermissions = session.can(PermissionCodes.permissionsManage);
    final canViewEmployees = session.can(PermissionCodes.employeesView);
    final canManageReferenceData = session.can(PermissionCodes.modulesTypes);

    final canSeeSeasons = session.canSeeSeasons;
    final canManageModules = session.can(PermissionCodes.modulesManage);

    // Everything held by a PERMISSION. A person is two things at once here —
    // somebody with authority and somebody with work — and the two were mixed
    // in one list: "الملفات التشغيلية" meant his own postings to one man and
    // the season's whole paperwork to another, depending on what he held.
    // Authority lives here; the work lives below.
    final adminCards = <Widget>[
      if (canManageModules)
        DashboardCard(
          icon: AppIcons.modules,
          title: l.navModulesManage,
          subtitle: l.navModulesManageSubtitle,
          color: _office.of(context),
          onTap: () => context.push(Routes.modulesManage),
        ),
      if (canSeeSeasons)
        DashboardCard(
          icon: AppIcons.seasons,
          title: l.navSeasons,
          subtitle: l.navSeasonsSubtitle,
          color: _season.of(context),
          onTap: _openSeasons,
        ),
      if (canManageReferenceData)
        DashboardCard(
          icon: AppIcons.referenceData,
          title: l.navReferenceData,
          subtitle: l.navReferenceDataSubtitle,
          color: _reference.of(context),
          onTap: () => context.push(Routes.referenceData),
        ),
      if (canViewEmployees)
        DashboardCard(
          icon: AppIcons.employees,
          title: l.navEmployees,
          subtitle: l.navEmployeesSubtitle,
          color: _people.of(context),
          onTap: () => context.push(Routes.employees),
        ),
      if (canApprove)
        DashboardCard(
          icon: AppIcons.approvals,
          title: l.navApprovals,
          subtitle: l.navApprovalsSubtitle,
          color: _approvals.of(context),
          onTap: () => context.push(Routes.approvals),
        ),
      if (canManagePermissions)
        DashboardCard(
          icon: AppIcons.permissions,
          title: l.navPermissions,
          subtitle: l.navPermissionsSubtitle,
          color: _permissions.of(context),
          onTap: () => context.push(Routes.permissions),
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
      // No tile for the profile: the greeting panel above already carries the
      // user's face and name, and tapping a card with your own name on it is
      // where anyone looks for it first.
    ];

    return Scaffold(
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
        builder: (context) => ResponsiveCenter(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: context.scrollPadding(),
              children: staggered([
                _GreetingPanel(
                  name: profile?.firstName ?? '',
                  subtitle: profile?.jobTitleName?.of(context),
                  photoUrl: profile?.photoUrl,
                  isAdmin: session.isAdmin,
                  seasonYear: _seasonYear,
                  onTap: () => context.push(Routes.myProfile),
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(l.homeGeneralSection),
                ...generalCards.expand(
                  (c) => [c, const SizedBox(height: AppSpacing.md)],
                ),
                if (adminCards.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  SectionHeader(l.homeAdminSection, icon: AppIcons.shield),
                  ...adminCards.expand(
                    (c) => [c, const SizedBox(height: AppSpacing.md)],
                  ),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }
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
  });

  final String name;
  final String? subtitle;
  final String? photoUrl;
  final bool isAdmin;

  /// Hijri year of the season the Administration is currently working through.
  final int seasonYear;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return GlassCard(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.xl),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Ringed avatar — the brand gradient reads as a status halo.
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.primary, scheme.secondary],
                  ),
                ),
                child: ProfileAvatar(
                  photoUrl: photoUrl,
                  name: name,
                  radius: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.homeWelcome(name),
                      style: text.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    // Says where the tap goes, now that the tile that used to
                    // say it is gone.
                    Text(
                      l.navMyProfile,
                      style: text.labelSmall?.copyWith(color: scheme.primary),
                    ),
                  ],
                ),
              ),
              const NavChevron(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
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
          ),
        ],
      ),
    );
  }
}
