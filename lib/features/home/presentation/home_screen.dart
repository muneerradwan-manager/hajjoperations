import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animations/animations.dart';
import '../../../core/constants/permission_codes.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/utils/hijri_utils.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/states.dart';
import '../../auth/application/session_cubit.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/widgets/settings_menu_button.dart';
import '../../notifications/presentation/widgets/notification_bell.dart';
import '../../seasons/data/seasons_repository.dart';
import 'widgets/dashboard_card.dart';

/// Accent per destination, so a returning user recognises a tile by its colour
/// before they finish reading the label. All four are brand colours — the
/// green family carries the everyday destinations, gold marks the season and
/// red the one screen that changes what other people can do.
const _accentGreen = AppColors.lightGreen;
const _accentGreenDeep = AppColors.mediumGreen;
const _accentGold = AppColors.darkGold;
const _accentRed = AppColors.mediumRed;
const _accentGreenDark = AppColors.darkGreen;

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

    final adminCards = <Widget>[
      if (canManageReferenceData)
        DashboardCard(
          icon: AppIcons.referenceData,
          title: l.navReferenceData,
          subtitle: l.navReferenceDataSubtitle,
          color: _accentGreenDark,
          onTap: () => context.push(Routes.referenceData),
        ),
      if (canViewEmployees)
        DashboardCard(
          icon: AppIcons.employees,
          title: l.navEmployees,
          subtitle: l.navEmployeesSubtitle,
          color: _accentGreenDeep,
          onTap: () => context.push(Routes.employees),
        ),
      if (canApprove)
        DashboardCard(
          icon: AppIcons.approvals,
          title: l.navApprovals,
          subtitle: l.navApprovalsSubtitle,
          color: _accentGreen,
          onTap: () => context.push(Routes.approvals),
        ),
      if (canManagePermissions)
        DashboardCard(
          icon: AppIcons.permissions,
          title: l.navPermissions,
          subtitle: l.navPermissionsSubtitle,
          color: _accentRed,
          onTap: () => context.push(Routes.permissions),
        ),
    ];

    // Available to every approved user — a module reaches its members through
    // assignment, not through a permission.
    final generalCards = <Widget>[
      DashboardCard(
        icon: AppIcons.modules,
        title: l.navModules,
        subtitle: l.navModulesSubtitle,
        color: _accentGreenDeep,
        onTap: () => context.push(Routes.modules),
      ),
      DashboardCard(
        icon: AppIcons.seasons,
        title: l.navSeasons,
        subtitle: l.navSeasonsSubtitle,
        color: _accentGold,
        onTap: _openSeasons,
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
        actions: [
          const NotificationBell(),
          IconButton(
            tooltip: l.commonLogout,
            onPressed: () => context.read<AuthRepository>().signOut(),
            icon: const Icon(AppIcons.logout),
          ),
          const SettingsMenuButton(),
        ],
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
                  subtitle: profile?.jobTitleName,
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
