import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_cubit.dart';
import '../../notifications/presentation/widgets/notification_bell.dart';
import '../../outbox/presentation/widgets/outbox_badge.dart';
import '../../prayer_times/application/prayer_times_cubit.dart';
import '../../prayer_times/data/prayer_times_repository.dart';
import '../../prayer_times/presentation/widgets/prayer_times_card.dart';
import 'widgets/dashboard_card.dart';

// Accent per destination, so a returning user recognises a tile by its colour
// before they finish reading the label — which only works if the colours are
// spread. They were not: green held nine of the thirteen tiles, on a green
// backdrop, under a green app bar, beside a green greeting ring. A colour that
// covers three quarters of a screen is not an accent, it is the paper.
//
// The families carry the meaning, and all three are now actually spent:
//
//   * GREEN — the mission's own work. It stays the app's primary — it is the
//     backdrop, the theme and the app bar — which is exactly why it now takes
//     three of these thirteen rather than nine. A tile is green here when it is
//     the work itself, not merely when it is ours.
//   * GOLD — the calendar and the reference material: the season, the lists
//     everything else is built from, and the times published to the whole
//     mission.
//   * RED — people, and what is said and decided about them: the employees,
//     the approvals, a person's own complaints, and — in the deepest of the
//     reds — the record that keeps all of it.
//
// Each is an [Accent] rather than a raw brand colour, because a print palette
// does not divide evenly across a night mode and a paper one: every red is
// unreadable on the dark backdrop and every gold on the light. See
// app_accents.dart for the measurements.

/// The العام tiles, one colour each, by the same families the الإدارة grid
/// uses below.
///
/// These three were one green block, which was the largest single run of one
/// colour on the screen — and it sat directly under a green backdrop, a green
/// theme and a green greeting ring, so the section read as a wash rather than
/// as three doors. The families already say what each one is: the files are the
/// mission's own work, مواعيد الوجبات is published reference material, and a
/// complaint is a thing said about a person.
const _generalPalette = <Accent>[
  Accent.green,
  // The second: the person's own task list — work, like the files above it,
  // but theirs alone.
  Accent.gold,
  Accent.goldSoft,
  Accent.red,
  // The fourth: an evaluation somebody was asked to write. Red again, because
  // what a mark is about is a person or a thing being judged — one step deeper
  // than the complaint beside it, which is the only other tile here that is
  // about a judgement rather than about work.
  Accent.plum,
  // The fifth: where this person has stood, and the act of saying so. Green
  // again, and the darkest of the three — being somewhere is the most literal
  // work on this list, and the only card here that DOES something as well as
  // opening something.
  Accent.greenDark,
];

/// A shelf in الإدارة: a name, a colour, and the tiles that belong under it.
///
/// A reader holding every permission is handed TWELVE tiles here, and twelve
/// doors in one undivided grid is not a menu, it is a wall. He knows what he
/// came for; what he cannot do is find it, because nothing on the page says
/// where that kind of thing is kept. So the section is shelved, and each shelf
/// is named and coloured — the name does the finding, and the colour is what he
/// remembers the second time.
///
/// The shelf is DECLARED by each entry rather than derived from its position,
/// which is the other half of the fix and the less visible one. The colour used
/// to be assigned by index — two tiles to a colour, counting down the filtered
/// list — so a reader without `approvals.view` shifted every pair below the gap
/// onto a different colour, and two people describing this screen to each other
/// were describing different screens. It also had to grow a sixth entry the
/// moment a twelfth tile appeared, or the list wrapped and started the colours
/// again. A shelf is a property of what the tile IS; it survives the filter,
/// and nothing has to be counted.
///
/// Four shelves, four families — see the note at the head of this file. Adding
/// a tile means naming its shelf and nothing else.
enum _AdminGroup {
  /// The paperwork itself: the season's files, the reports drawn from them, the
  /// blank forms the office writes, and the complaints register. Green, the
  /// mission's own work.
  ///
  /// The complaints belong here rather than on the shelf below because of what
  /// is DONE with them. A register that is replied to, dismissed and locked is
  /// a standing file being worked through, not a record being looked back at.
  files(Accent.greenDeep),

  /// Everybody with an account, and what each of them may do. Red, which is
  /// what red is for here.
  people(Accent.red),

  /// The year, and the lists everything else is built from.
  season(Accent.gold),

  /// Looking at all of it: the numbers from above, the acts in order, and the
  /// urgent reports. The deepest red there is.
  ///
  /// It used to be described as the shelf that only ever looks BACK, and two of
  /// the things on it have since left for that reason — the complaints and the
  /// evaluations register are both worked through rather than read after the
  /// fact. What remains is the season seen whole, plus the one screen here that
  /// is read while it is still happening.
  oversight(Accent.plum);

  const _AdminGroup(this.accent);

  final Accent accent;

  String title(AppLocalizations l) => switch (this) {
    files => l.homeAdminGroupFiles,
    people => l.homeAdminGroupPeople,
    season => l.homeAdminGroupSeason,
    oversight => l.homeAdminGroupOversight,
  };
}

/// One beat of the entry cascade.
const _step = Duration(milliseconds: 70);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Owned by the screen rather than created inside the card, so that the
  /// pull-to-refresh gesture — which is handled up here, above anything the
  /// card could provide — can reach it.
  late final _prayer = PrayerTimesCubit(PrayerTimesRepository());

  // No season is fetched here any more. This screen used to ask the server for
  // the current season on every open and every pull, to print one Hijri year on
  // a badge; the badge now shows today's date, which the device knows, and the
  // request went with it.

  @override
  void dispose() {
    _prayer.close();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<SessionCubit>().reload(),
      // Never prompts. A drag on a list is a request for newer numbers, not a
      // gesture anybody would expect to raise a permission dialog.
      _prayer.refresh(),
    ]);
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
    // Declared as entries rather than built as widgets, because they have to be
    // sorted onto their shelves — see [_AdminGroup] — after the reader's
    // permissions have decided which of them exist at all.
    final admin =
        <({
          _AdminGroup group,
          IconData icon,
          String title,
          String subtitle,
          VoidCallback onTap,
        })>[
          if (canManageModules)
            (
              group: _AdminGroup.files,
              icon: AppIcons.modules,
              title: l.navModulesManage,
              subtitle: l.navModulesManageSubtitle,
              onTap: () => context.push(Routes.modulesManage),
            ),
          if (canManageReports)
            (
              group: _AdminGroup.files,
              icon: AppIcons.reports,
              title: l.navReportsManage,
              subtitle: l.navReportsManageSubtitle,
              onTap: () => context.push(Routes.reportsManage),
            ),
          if (canViewEmployees)
            (
              group: _AdminGroup.people,
              icon: AppIcons.employees,
              title: l.navEmployees,
              subtitle: l.navEmployeesSubtitle,
              onTap: () => context.push(Routes.employees),
            ),
          if (canApprove)
            (
              group: _AdminGroup.people,
              icon: AppIcons.approvals,
              title: l.navApprovals,
              subtitle: l.navApprovalsSubtitle,
              onTap: () => context.push(Routes.approvals),
            ),
          // Beside the permissions, and for the same reason: writing a task
          // onto somebody's list is an act aimed at a PERSON, and whoever came
          // here came looking for him. Not on the files shelf — this system
          // has no relation to the operational files (0105).
          if (session.can(PermissionCodes.tasksAssign))
            (
              group: _AdminGroup.people,
              icon: AppIcons.tasks,
              title: l.navTasksManage,
              subtitle: l.navTasksManageSubtitle,
              onTap: () => context.push(Routes.tasksManage),
            ),
          // With the people rather than on a shelf of its own: what a man may
          // do is a fact about the man, and somebody who came here to change it
          // came looking for HIM.
          if (canManagePermissions)
            (
              group: _AdminGroup.people,
              icon: AppIcons.permissions,
              title: l.navPermissions,
              subtitle: l.navPermissionsSubtitle,
              onTap: () => context.push(Routes.permissions),
            ),
          if (canSeeSeasons)
            (
              group: _AdminGroup.season,
              icon: AppIcons.seasons,
              title: l.navSeasons,
              subtitle: l.navSeasonsSubtitle,
              onTap: () => context.push(Routes.seasons),
            ),
          if (canManageReferenceData)
            (
              group: _AdminGroup.season,
              icon: AppIcons.referenceData,
              title: l.navReferenceData,
              subtitle: l.navReferenceDataSubtitle,
              onTap: () => context.push(Routes.referenceData),
            ),
          // No longer standing apart beside the greeting. It is one of these —
          // the season from above — and it heads the shelf of things that look
          // at the season rather than do anything to it.
          if (canSeeDashboard)
            (
              group: _AdminGroup.oversight,
              icon: AppIcons.dashboard,
              title: l.navDashboard,
              subtitle: l.navDashboardSubtitle,
              onTap: () => context.push(Routes.dashboard),
            ),
          // Beside the dashboard, and the pairing is the meaning: one is the
          // season from above, the other is the season act by act.
          if (session.can(PermissionCodes.auditView))
            (
              group: _AdminGroup.oversight,
              icon: AppIcons.auditLog,
              title: l.navAuditLog,
              subtitle: l.navAuditLogSubtitle,
              onTap: () => context.push(Routes.auditLog),
            ),
          // The whole register, which is oversight and belongs here. Filing one
          // and reading your own are not — those are everybody's, and stand
          // below under العام beside the rest of a person's own work.
          // إدارة الشكاوى sits with the paperwork, not on the oversight shelf.
          //
          // It moved because of what the shelf is FOR: الإشراف والسجلات is what
          // you read after the fact — the numbers from above, the acts in
          // order. A complaint register is not read that way. It is worked
          // THROUGH — replied to, dismissed, locked — which makes it one of the
          // office's standing files, beside the reports and the blank forms.
          if (session.can(PermissionCodes.complaintsView))
            (
              group: _AdminGroup.files,
              icon: AppIcons.complaints,
              title: l.navComplaints,
              subtitle: l.navComplaintsSubtitle,
              onTap: () => context.push(Routes.complaintsManage),
            ),
          // The season drawn. It belongs on the oversight shelf beside the
          // dashboard and for the same reason — both are the season seen whole
          // rather than a thing to go and do — and it is the only one of them
          // that is read while the season is still happening.
          //
          // Gated since 0100. The RPC still answers per reader and that is
          // untouched; what changed is that the season laid out whole is an
          // operations-room view, and a member does not need one to serve in
          // his own tower.
          if (session.can(PermissionCodes.mapView))
            (
              group: _AdminGroup.oversight,
              icon: AppIcons.checkIn,
              title: l.seasonMapTitle,
              subtitle: l.seasonMapSubtitle,
              onTap: () => context.push(Routes.seasonMap),
            ),
          // Taking data out of the app. It belongs on the oversight shelf and
          // not in settings: settings is where a person adjusts how the app
          // behaves FOR HIM — the language, the theme, whether it may notify
          // him. An export is not a preference, it is work done ON the
          // season's records, and it sits with the other screens that look at
          // all of them at once.
          //
          // Gated since 0100, and it is the grant that most needs a door. It
          // used to gate itself by offering only what the reader could already
          // open; `export.data` now widens the row policies themselves, so a
          // holder takes out what he cannot see on any screen.
          if (session.can(PermissionCodes.exportData))
            (
              group: _AdminGroup.oversight,
              icon: AppIcons.upload,
              title: l.exportTitle,
              subtitle: l.exportSubtitle,
              onTap: () => context.push(Routes.export),
            ),
          // The operations room's own screen. Oversight, but of a different
          // kind from the rest of this group: everything else here is read
          // after the fact, and this one is read while it is still happening.
          if (session.can(PermissionCodes.incidentsReceive))
            (
              group: _AdminGroup.oversight,
              icon: AppIcons.warning,
              title: l.incidentsTitle,
              subtitle: l.incidentsEmptyHint,
              onTap: () => context.push(Routes.incidents),
            ),
          // Beside the map, and for the same reason: both are the season seen
          // whole while it is still happening. The map says where the places
          // are and this says who is in them.
          if (session.can(PermissionCodes.checkinBoard))
            (
              group: _AdminGroup.oversight,
              icon: AppIcons.checkIn,
              title: l.presenceTitle,
              subtitle: l.presenceSubtitle,
              onTap: () => context.push(Routes.presence),
            ),
          // The two halves of التقييم, and they are deliberately two tiles
          // rather than one section with a switch. The paper and the marks are
          // different trusts: whoever writes the questions need not read
          // anybody's answers. Which is also why they land on different
          // shelves — the register is oversight, and the blank form is the
          // office's own stationery, filed with the rest of the paperwork.
          // Filling one is neither; that is an errand, and it stands below
          // under العام with the rest of a person's own work.
          // سجل التقييمات is deliberately NOT a tile here any more.
          //
          // It is reached from inside إدارة التقييمات, where the forms are —
          // and that is where somebody looking for it actually goes, because
          // the register only makes sense next to the papers it was written
          // from. Two doors to it from the home screen made إدارة a list of
          // forms with no way out and the register an orphan beside it.
          //
          // The permission has not changed: `/evaluations/manage` is still
          // guarded by `evaluations.view` in sectionGuards, so nothing was
          // opened by taking the tile away.
          if (session.can(PermissionCodes.evaluationsTemplates))
            (
              group: _AdminGroup.files,
              icon: AppIcons.evaluationForms,
              title: l.navEvaluationForms,
              subtitle: l.navEvaluationFormsSubtitle,
              onTap: () => context.push(Routes.evaluationForms),
            ),
        ];

    // One shelf per group that has anything on it, in the enum's own order.
    //
    // A group with nothing under it produces no heading — a reader who may see
    // the seasons but not the reference lists gets الموسم والمراجع with one
    // tile under it, and a reader who may see neither is never told the shelf
    // exists.
    final adminShelves = <(_AdminGroup, List<Widget>)>[
      for (final group in _AdminGroup.values)
        if (admin.any((entry) => entry.group == group))
          (
            group,
            [
              for (final entry in admin)
                if (entry.group == group)
                  CompactDashboardCard(
                    icon: entry.icon,
                    title: entry.title,
                    subtitle: entry.subtitle,
                    color: group.accent.of(context),
                    onTap: entry.onTap,
                  ),
            ],
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
        color: _generalPalette[0].of(context),
        onTap: () => context.push(Routes.modules),
      ),
      // Gated by nothing: everyone owns a task list by existing (0105), and
      // what was assigned to them arrived by name, not by grant. No relation
      // to the operational files — that is the whole point of the card.
      DashboardCard(
        icon: AppIcons.tasks,
        title: l.navTasks,
        subtitle: l.navTasksSubtitle,
        color: _generalPalette[1].of(context),
        onTap: () => context.push(Routes.tasks),
        action: () => context.push('${Routes.tasks}?compose=1'),
        actionTooltip: l.tasksNew,
      ),
      // Published to everybody, and gated by nothing: مواعيد الوجبات is not
      // an assignment, it is information the whole mission needs. Reading is
      // open to any approved account; entering one is what needs a permission.
      DashboardCard(
        icon: AppIcons.reports,
        title: l.navReports,
        subtitle: l.navReportsSubtitle,
        color: _generalPalette[2].of(context),
        onTap: () => context.push(Routes.reports),
      ),
      // Gated by nothing, and that is the point: complaining is not a
      // permission somebody grants. This card is what a person filed and the
      // way to file another. What was filed ABOUT them is not here — that lives
      // on their own profile, which is where a man looks for what is being said
      // about him, and is the one door that hands it over without a name on it.
      DashboardCard(
        icon: AppIcons.complaints,
        title: l.navMyComplaints,
        subtitle: l.navMyComplaintsSubtitle,
        color: _generalPalette[3].of(context),
        onTap: () => context.push(Routes.complaints),
        action: () => context.push('${Routes.complaints}?compose=1'),
        actionTooltip: l.complaintsNew,
      ),
      // Gated by nothing, like the three above it, and for a reason of its
      // own: an evaluation reaches its evaluator by NAME. There is no
      // permission to fill one, so there is nothing to hide this card behind —
      // and a person with no errands opens it to an empty list, which is the
      // true answer rather than a missing door. What was written ABOUT them is
      // not here either; that lives on their own profile, which is the one door
      // that hands over the marks with no name on them.
      DashboardCard(
        icon: AppIcons.evaluations,
        title: l.navEvaluations,
        subtitle: l.navEvaluationsSubtitle,
        color: _generalPalette[4].of(context),
        onTap: () => context.push(Routes.evaluations),
      ),
      // Where this person has been, and the way to add to it. Two verbs on one
      // card, and they belong together: the man about to scan a code is the
      // same man wondering whether last night's scan registered, and until now
      // those were a button under the prayer card and no screen at all.
      //
      // Gated by nothing, twice over. Filing your own arrival needs no grant —
      // the code on the wall and the phone's position are the credential, and a
      // system in which only certain people may report where they are is a
      // system that does not know where anybody is. Reading your own record
      // needs none either: `place_check_ins` opens its policy with
      // `profile_id = auth.uid()`, and §30.3 of 0098 says so in words.
      DashboardCard(
        icon: AppIcons.auditLog,
        title: l.myCheckInsTitle,
        subtitle: l.navMyCheckInsSubtitle,
        color: _generalPalette[5].of(context),
        onTap: () => context.push(Routes.myCheckIns),
        // The act, raised out of the card. It was a full-width button under the
        // prayer card, which put it among the facts about the moment rather
        // than among the things a person does — and left the record it produces
        // with nowhere to live. Now the record is the card and the act is on it.
        action: () => context.push(Routes.checkIn),
        actionTooltip: l.checkInAction,
        actionIcon: AppIcons.qrCode,
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
          // The outbox first, and only when it has something in it. What the
          // app is still holding of yours outranks what it has been told.
          actions: const [OutboxBadge(), NotificationBell()],
          // The one bar in the app without it. Every other screen carries the
          // urgent report as an icon here because it has nowhere better; this
          // page has somewhere better — the full-width red button below, beside
          // check-in. Two doors to one screen, a hand's width apart, read as
          // two different things.
          showIncidentButton: false,
        ),
        // The emergency button is NOT a floating one. It sits under the prayer
        // card, in the body — see `prayer` below.
        //
        // A floating button covers the last row of whatever is beneath it, and
        // it covers a different row on every window width. This one is wanted
        // in a place a person learns once: directly under the two things at the
        // top of the page that are already about the present moment.
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
                    _ShelfHeader(
                      title: group.title(l),
                      color: group.accent.of(context),
                    ),
                    AdaptiveGrid(
                      // Small tiles, so the grid is told to pack them: at 340
                      // — the width a tile with a subtitle and a chevron needs
                      // — a phone gets one column and the whole point of the
                      // compact card is lost. At 150 a phone gets two, a
                      // tablet three or four, and a monitor the four it is
                      // capped at.
                      minTileWidth: 150,
                      children: tiles,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ];

              final greeting = _GreetingPanel(
                name: profile?.firstName ?? '',
                subtitle: profile?.jobTitleName?.of(context),
                photoUrl: profile?.photoUrl,
                isAdmin: session.isAdmin,
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
              // The prayer card and the emergency button travel together,
              // because they are the same kind of thing on this page: facts
              // and acts about the moment the reader is standing in, rather
              // than places to go. Bundled here rather than added to each
              // layout, so the wide arrangement — where this sits in the side
              // panel — cannot drift from the narrow one.
              const prayer = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrayerTimesCard(),
                  SizedBox(height: AppSpacing.sm),
                  // Only the emergency now. Check-in used to sit here beside
                  // it, on the argument that they are the two things a man does
                  // standing in a place — which is true, and was the wrong
                  // conclusion: an arrival produces a RECORD, and the record had
                  // nowhere to live. It moved onto its own card in العام, with
                  // the act raised on it, so the thing you do and the thing it
                  // writes are one place. An emergency produces no record its
                  // author reads, so it stays here.
                  _RaiseIncidentButton(),
                ],
              );

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

class _RaiseIncidentButton extends StatelessWidget {
  const _RaiseIncidentButton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.error,
        foregroundColor: scheme.onError,
        minimumSize: const Size.fromHeight(48),
      ),
      onPressed: () => context.push(Routes.raiseIncident),
      icon: const Icon(AppIcons.warning, size: 20),
      label: Text(context.l10n.incidentTitle),
    );
  }
}

/// The name of one shelf inside الإدارة, in that shelf's colour.
///
/// Deliberately NOT a [SectionHeader]: that one names عام and الإدارة, the two
/// halves of the page, and a heading that looks the same as those would say
/// these four shelves are its equals rather than its contents. Smaller, in the
/// group's own accent rather than the page's grey, with a rule running off to
/// the edge to tie the tiles under it into one band.
///
/// The colour is the point of the rule. It is the same colour as the four
/// medallions below it, so the band reads as one thing at arm's length, before
/// a single word of it has been read.
class _ShelfHeader extends StatelessWidget {
  const _ShelfHeader({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: text.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Container(
              height: 1,
              color: color.withValues(alpha: 0.22),
            ),
          ),
        ],
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
    required this.onTap,
    required this.layout,
  });

  final String name;
  final String? subtitle;
  final String? photoUrl;

  /// Whether this person runs the Administration — written into the job title
  /// line rather than worn as a badge of its own. See [_Identity].
  final bool isAdmin;

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
              child: _Identity(
                name: name,
                subtitle: subtitle,
                isAdmin: isAdmin,
              ),
            ),
            if (inlineBadges) ...[
              const SizedBox(width: AppSpacing.lg),
              const _Badges(),
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
          const _Badges(),
        ],
      ],
    );
  }

  Widget _column(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
          isAdmin: isAdmin,
          align: CrossAxisAlignment.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
        const SizedBox(height: AppSpacing.md),
        const _Badges(alignment: WrapAlignment.center),
        
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
    required this.isAdmin,
    this.align = CrossAxisAlignment.start,
  });

  final String name;
  final String? subtitle;

  /// Whether this person runs the Administration.
  ///
  /// It used to be a badge of its own, standing beside the season's on the row
  /// below. It reads better in parentheses after the job title, because that is
  /// what it IS — a second thing this person is called, not a fact about the
  /// day — and it left the badge row to the two dates alone.
  final bool isAdmin;

  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final centred = align == CrossAxisAlignment.center;
    final textAlign = centred ? TextAlign.center : TextAlign.start;

    final job = subtitle != null && subtitle!.isNotEmpty ? subtitle : null;

    // The job title in the grey the rest of this line is written in, and the
    // rank after it in a colour of its own — "مشرف ميداني (مدير)", where only
    // the bracketed half is coloured. Two spans rather than two widgets so the
    // pair ellipsises as one line and wraps as one line.
    //
    // Red, from the family this palette gives to people and to what they are
    // answerable for. Neither the green on the Gregorian badge below nor the
    // gold on the Hijri one: a rank that borrows a date's colour reads as
    // belonging to the date.
    //
    // An admin with no job title on file gets "مدير" with no brackets — a lone
    // "(مدير)" is punctuation with nothing to qualify.
    final rank = !isAdmin
        ? null
        : job == null
        ? l.profileBadgeAdmin
        : l.profileTitleBadgeSuffix(l.profileBadgeAdmin);

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
        if (job != null || rank != null) ...[
          const SizedBox(height: 3),
          Text.rich(
            TextSpan(
              children: [
                if (job != null) TextSpan(text: rank == null ? job : '$job '),
                if (rank != null)
                  TextSpan(
                    text: rank,
                    style: TextStyle(
                      color: Accent.red.of(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
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

/// Today's date, in both calendars, side by side.
///
/// Two badges rather than one line, because they are two answers to the same
/// question and a reader wants whichever one they think in — the mission runs
/// on the Hijri date and the rest of the world writes the other on a form.
/// Neither is a subtitle of the other, so neither is set below the other.
///
/// The pair replaced the season's Hijri YEAR, which used to stand here and was
/// a different kind of fact: which year the Administration is working through
/// is a setting, not the day it is, and a bare "1447 هـ" beside a man's name
/// read as today's date to everyone who saw it. The season lives on its own
/// screen, where it can be changed — and this card no longer asks the server
/// for it on every open.
///
/// Gold and green rather than two of a kind: the calendar is the gold family
/// everywhere else in this app, and the two badges still have to be told apart
/// when the words in them run to the same length.
class _Badges extends StatelessWidget {
  const _Badges({this.alignment = WrapAlignment.start});

  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    // The language the reader chose, not the device's: the app carries its own
    // locale setting, and a phone set to English with the app set to Arabic
    // must not print half the card in each.
    final language = Localizations.localeOf(context).languageCode;

    // Read at build time rather than held in state. A greeting card is rebuilt
    // on every session change, every refresh and every theme flip; a date that
    // was captured once in initState would be the day the app was opened, which
    // for a phone left running on a bedside table in Mina is yesterday.
    final now = DateTime.now();

    return Wrap(
      alignment: alignment,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        GlassBadge(
          label: l.homeHijriDate(HijriUtils.todayInWords(language)),
          color: scheme.secondary,
          icon: AppIcons.hijriDate,
        ),
        GlassBadge(
          // `d MMMM y`, not the numeric form: the badge beside it spells its
          // month out, and "صفر" against "2026-08-04" is two different habits
          // of writing on one card.
          label: l.homeGregorianDate(
            DateFormat('d MMMM y', language).format(now),
          ),
          color: scheme.primary,
          icon: AppIcons.gregorianDate,
        ),
      ],
    );
  }
}
