import 'package:go_router/go_router.dart';

import '../../features/auth/application/session_cubit.dart';
import '../../features/approval/presentation/approval_queue_screen.dart';
import '../../features/audit/presentation/audit_log_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/complaints/application/complaints_cubit.dart';
import '../../features/complaints/presentation/complaints_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/reports/presentation/reports_manage_screen.dart';
import '../../features/employees/presentation/employees_directory_screen.dart';
import '../../features/evaluations/application/evaluations_cubit.dart';
import '../../features/evaluations/presentation/evaluation_forms_screen.dart';
import '../../features/evaluations/presentation/evaluations_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/checkin/presentation/check_in_screen.dart';
import '../../features/checkin/presentation/presence_board_screen.dart';
import '../../features/incidents/presentation/incidents_screen.dart';
import '../../features/map/presentation/season_map_screen.dart';
import '../../features/incidents/presentation/raise_incident_screen.dart';
import '../../features/modules/application/modules_cubit.dart';
import '../../features/modules/presentation/modules_screen.dart';
import '../../features/modules/presentation/reference_data_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/export/presentation/export_screen.dart';
import '../../features/outbox/presentation/outbox_screen.dart';
import '../../features/permissions/presentation/permissions_employees_screen.dart';
import '../../features/profile/presentation/my_profile_screen.dart';
import '../../features/profile/presentation/profile_completion_screen.dart';
import '../../features/seasons/presentation/seasons_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/status/presentation/pending_screen.dart';
import '../../features/status/presentation/rejected_screen.dart';
import '../../features/status/presentation/splash_screen.dart';
import '../../features/status/presentation/suspended_screen.dart';
import '../../features/tasks/presentation/tasks_manage_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../animations/animations.dart';
import '../constants/permission_codes.dart';
import 'go_router_refresh_stream.dart';

/// Route paths.
abstract class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const completeProfile = '/profile/complete';
  static const pending = '/pending';
  static const rejected = '/rejected';
  static const home = '/';
  static const approvals = '/approvals';
  static const permissions = '/permissions';
  static const seasons = '/seasons';
  static const suspended = '/suspended';
  static const employees = '/employees';
  static const myProfile = '/my-profile';
  static const notifications = '/notifications';
  static const modules = '/modules';
  static const reports = '/reports';
  static const reportsManage = '/reports/manage';
  static const modulesManage = '/modules/manage';
  static const referenceData = '/reference-data';
  static const settings = '/settings';
  static const dashboard = '/dashboard';
  static const auditLog = '/audit-log';
  static const complaints = '/complaints';
  static const complaintsManage = '/complaints/manage';
  static const evaluations = '/evaluations';
  static const evaluationsManage = '/evaluations/manage';
  static const evaluationForms = '/evaluations/forms';

  /// Deliberately absent from [_sectionGuards] below: what is waiting here is
  /// the reader's OWN work, held by his own device. There is no permission to
  /// hold for seeing what you yourself wrote.
  static const outbox = '/outbox';

  /// Taking data out. **Guarded since 0100**, and the old argument for leaving
  /// it open is the reason it had to change: it offered only what the reader
  /// could already open, so it could not widen anything. `export.data` now
  /// widens the row policies themselves, which makes this the door to a senior
  /// read rather than a second view of what is already visible.
  static const export = '/export';

  /// Raising an urgent report. Unguarded on purpose and for the same reason
  /// filing a complaint is: a system in which only certain people may say that
  /// a bus has broken down is a system that does not find out about the bus.
  static const raiseIncident = '/incident';

  /// The register. Guarded — see [_sectionGuards].
  static const incidents = '/incidents';

  /// The season drawn. **Guarded since 0100.** The RPC still narrows per reader
  /// — a member would get the places of files he is in — and that narrowing is
  /// untouched; this decides who may open the PAGE. The season laid out whole
  /// is an operations-room view, and a member does not need one to serve in his
  /// tower.
  static const seasonMap = '/map';

  /// Reporting that you have arrived somewhere. Unguarded, for `/incident`'s
  /// reason: a system in which only certain people may report where they are is
  /// a system that does not know where anybody is. What stands in the way is
  /// physical — the code on the wall and the phone's position — not a grant.
  static const checkIn = '/check-in';

  /// Who is present, everywhere. Guarded — see [_sectionGuards]. Reading your
  /// OWN arrivals never needed a grant and still does not; this is the room's
  /// view of everybody's.
  static const presence = '/presence';

  /// One person's task list (0105). Unguarded on purpose: everyone owns a
  /// list by existing, and what was assigned to them arrives by name, not by
  /// grant.
  static const tasks = '/tasks';

  /// Writing tasks onto OTHER people's lists, and following them up. Guarded
  /// — see [sectionGuards]. A separate door from [tasks] rather than a button
  /// on it: that page is a person's work, this one is authority over other
  /// people's, and the two were never the same screen.
  static const tasksManage = '/tasks/manage';
}

/// What each administered section asks of whoever tries to open it.
///
/// One table rather than a run of `if`s, so that "is every managed section
/// closed?" is a question you answer by reading a list instead of by trusting
/// that nobody forgot. Each line is the same rule its card on the home screen
/// is drawn by; keeping them side by side is what stops the two from drifting
/// into a section that is hidden but open, or shown but shut.
///
/// Matched exactly, never by prefix. `/employees` is the directory and belongs
/// to whoever keeps it, while an employee's own page is opened from inside an
/// operational file by people who run files and may not keep the directory —
/// so the page is pushed rather than routed, and closing the directory does not
/// close the person.
///
/// Four sections are deliberately absent:
///   * `/modules` and `/reports` — the first is everyone's own assigned work,
///     the second is what the whole mission may read. What belongs to somebody
///     is the paperwork behind them, and that is `/modules/manage` and
///     `/reports/manage`, both listed here.
///   * `/dashboard` — not one screen but a row of sections, each one answered
///     for separately by `dashboard_stats` on the server. Anyone with any of
///     them may open it, and sees only the ones they have.
///   * `/complaints` — what this person filed. Complaining is not a permission
///     and neither is reading your own; the register of EVERYONE's is
///     `/complaints/manage`, and that one is listed here.
///   * `/evaluations` — the sheets this person was ASKED to fill. Being named
///     to an evaluation is an assignment, not a grant, so there is nothing to
///     guard it with; the register of everyone's is `/evaluations/manage` and
///     the forms behind them are `/evaluations/forms`, both listed here.
final sectionGuards = <String, bool Function(SessionState)>{
  Routes.seasons: (s) => s.canSeeSeasons,
  Routes.modulesManage: (s) => s.can(PermissionCodes.modulesViewAll),
  Routes.reportsManage: (s) => s.can(PermissionCodes.reportsViewAll),
  Routes.employees: (s) => s.can(PermissionCodes.employeesView),
  Routes.approvals: (s) => s.can(PermissionCodes.approvalsView),
  Routes.permissions: (s) => s.can(PermissionCodes.permissionsView),
  Routes.referenceData: (s) => s.can(PermissionCodes.referenceView),
  Routes.auditLog: (s) => s.can(PermissionCodes.auditView),
  Routes.complaintsManage: (s) => s.can(PermissionCodes.complaintsView),
  Routes.evaluationsManage: (s) => s.can(PermissionCodes.evaluationsView),
  // Two codes, and it is the only door in this table that takes either.
  // إدارة التقييم is where a form is written AND where an evaluation is
  // opened on one — the register issues nothing — so shutting it to
  // `evaluations.assign` would leave that permission with no way to be
  // exercised at all. What each of the two may DO in there still differs:
  // the editing controls ask for `templates` and the assign action asks for
  // `assign`, and the server refuses either to the wrong holder anyway.
  Routes.evaluationForms: (s) =>
      s.can(PermissionCodes.evaluationsTemplates) ||
      s.can(PermissionCodes.evaluationsAssign),
  // The register of urgent reports — the operations room's screen. RAISING one
  // is `/incident` and is deliberately not in this table: anybody may say that
  // something has gone wrong.
  Routes.incidents: (s) => s.can(PermissionCodes.incidentsReceive),

  // Who is where, across the season. Filing your own arrival is `/check-in` and
  // is deliberately not in this table, for the same reason raising an incident
  // is not.
  Routes.presence: (s) => s.can(PermissionCodes.checkinBoard),

  // Both of these were open, and both comments above say why they no longer
  // are. The export one is the one that matters: `export.data` widens the row
  // policies in 0100, so this door leads somewhere the reader could not
  // otherwise go — which is exactly the case a guard is for.
  Routes.export: (s) => s.can(PermissionCodes.exportData),
  Routes.seasonMap: (s) => s.can(PermissionCodes.mapView),

  // Assigning tasks to other people. `/tasks` — a person's own list — is
  // deliberately not in this table, for the same reason `/complaints` is not:
  // owning a list is not a permission somebody grants.
  Routes.tasksManage: (s) => s.can(PermissionCodes.tasksAssign),
};

GoRouter buildRouter(SessionCubit session) {
  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: GoRouterRefreshStream(session.stream),
    redirect: (context, state) {
      final status = session.state.status;
      final loc = state.matchedLocation;

      // Still resolving the session — show the splash.
      if (status == SessionStatus.unknown) {
        return loc == Routes.splash ? null : Routes.splash;
      }

      final onAuthPage = loc == Routes.login || loc == Routes.register;

      // Adding a second account is the one time the sign-in form is wanted by
      // somebody who is already signed in. The session is deliberately left
      // running — switching accounts must never sign the current one out, or
      // its saved token would be revoked and the switcher could not bring it
      // back — so without this the redirect would send them straight home.
      //
      // A query parameter and not a separate route, because it is the same
      // screen doing the same thing; only the way back differs.
      //
      // The parameter carries the id of the account that opened it, so the
      // exemption ends by itself: the moment a different account signs in, it
      // stops matching and the ordinary rules take over and send them home. A
      // bare flag would have held the screen open over the session it was there
      // to create.
      final addingFor = state.uri.queryParameters['add'];
      if (onAuthPage && addingFor != null && addingFor == session.userId) {
        return null;
      }

      switch (status) {
        case SessionStatus.unauthenticated:
          return onAuthPage ? null : Routes.login;
        case SessionStatus.incomplete:
          return loc == Routes.completeProfile ? null : Routes.completeProfile;
        case SessionStatus.pending:
          return loc == Routes.pending ? null : Routes.pending;
        case SessionStatus.rejected:
          // Allow editing the profile again from the rejected screen.
          if (loc == Routes.rejected || loc == Routes.completeProfile) {
            return null;
          }
          return Routes.rejected;
        case SessionStatus.suspended:
          return loc == Routes.suspended ? null : Routes.suspended;
        case SessionStatus.approved:
          if (onAuthPage ||
              loc == Routes.splash ||
              loc == Routes.pending ||
              loc == Routes.rejected ||
              loc == Routes.suspended ||
              loc == Routes.completeProfile) {
            return Routes.home;
          }
          // A section that is hidden has to be closed as well. The home screen
          // already leaves the card out, and this is what makes that a rule
          // rather than a decoration: the route refuses too, so a section
          // cannot be reached by a link, by a location restored from the last
          // run, or by a card added somewhere later by someone who did not
          // know to ask.
          final guard = sectionGuards[loc];
          if (guard != null && !guard(session.state)) {
            return Routes.home;
          }
          return null;
        case SessionStatus.unknown:
          return null;
      }
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: Routes.login,
        pageBuilder: (c, s) => fadeThroughPage(
          key: s.pageKey,
          child: LoginScreen(
            addingForUserId: s.uri.queryParameters['add'],
          ),
        ),
      ),
      GoRoute(
        path: Routes.register,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const RegisterScreen()),
      ),
      GoRoute(
        path: Routes.completeProfile,
        pageBuilder: (c, s) => fadeThroughPage(
          key: s.pageKey,
          child: const ProfileCompletionScreen(),
        ),
      ),
      GoRoute(
        path: Routes.pending,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const PendingScreen()),
      ),
      GoRoute(
        path: Routes.rejected,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const RejectedScreen()),
      ),
      GoRoute(
        path: Routes.suspended,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const SuspendedScreen()),
      ),
      GoRoute(
        path: Routes.home,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const HomeScreen()),
      ),
      GoRoute(
        path: Routes.notifications,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const NotificationsScreen()),
      ),
      GoRoute(
        path: Routes.settings,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const SettingsScreen()),
      ),
      GoRoute(
        path: Routes.outbox,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const OutboxScreen()),
      ),
      GoRoute(
        path: Routes.export,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const ExportScreen()),
      ),
      GoRoute(
        path: Routes.raiseIncident,
        pageBuilder: (c, s) => fadeThroughPage(
          key: s.pageKey,
          child: RaiseIncidentScreen(
            moduleId: s.uri.queryParameters['module'],
            nodeId: s.uri.queryParameters['node'],
          ),
        ),
      ),
      GoRoute(
        path: Routes.incidents,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const IncidentsScreen()),
      ),
      GoRoute(
        path: Routes.checkIn,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const CheckInScreen()),
      ),
      GoRoute(
        path: Routes.presence,
        pageBuilder: (c, s) => fadeThroughPage(
          key: s.pageKey,
          // `place` narrows the board to one entry — how the map's pin and a
          // hotel's page reach it. Absent, it is the whole season.
          child: PresenceBoardScreen(
            itemId: s.uri.queryParameters['place'],
            placeName: s.uri.queryParameters['name'],
          ),
        ),
      ),
      GoRoute(
        path: Routes.seasonMap,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const SeasonMapScreen()),
      ),
      GoRoute(
        path: Routes.tasks,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const TasksScreen()),
      ),
      GoRoute(
        path: Routes.tasksManage,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const TasksManageScreen()),
      ),
      GoRoute(
        path: Routes.reports,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const ReportsScreen()),
      ),
      GoRoute(
        path: Routes.reportsManage,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const ReportsManageScreen()),
      ),
      GoRoute(
        path: Routes.dashboard,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const DashboardScreen()),
      ),
      GoRoute(
        path: Routes.approvals,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const ApprovalQueueScreen()),
      ),
      GoRoute(
        path: Routes.permissions,
        pageBuilder: (c, s) => fadeThroughPage(
          key: s.pageKey,
          child: const PermissionsEmployeesScreen(),
        ),
      ),
      GoRoute(
        path: Routes.seasons,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const SeasonsScreen()),
      ),
      GoRoute(
        path: Routes.employees,
        pageBuilder: (c, s) => fadeThroughPage(
          key: s.pageKey,
          child: const EmployeesDirectoryScreen(),
        ),
      ),
      GoRoute(
        path: Routes.modules,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const ModulesScreen()),
      ),
      // The same screen asked the other question. A separate route rather than
      // a flag on the first, so the office and the work each have a place of
      // their own to return to.
      GoRoute(
        path: Routes.modulesManage,
        pageBuilder: (c, s) => fadeThroughPage(
          key: s.pageKey,
          child: const ModulesScreen(view: ModulesView.manage),
        ),
      ),
      GoRoute(
        path: Routes.referenceData,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const ReferenceDataScreen()),
      ),
      GoRoute(
        path: Routes.auditLog,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const AuditLogScreen()),
      ),
      GoRoute(
        path: Routes.myProfile,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const MyProfileScreen()),
      ),
      // The same screen asked the other question, as with files and reports:
      // one is what this person filed, the other is the whole register.
      GoRoute(
        path: Routes.complaints,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const ComplaintsScreen()),
      ),
      GoRoute(
        path: Routes.complaintsManage,
        pageBuilder: (c, s) => fadeThroughPage(
          key: s.pageKey,
          child: const ComplaintsScreen(scope: ComplaintsScope.all),
        ),
      ),
      // The same pair again, for the same reason: one is what this person was
      // asked to fill, the other is the whole register. The forms behind both
      // are a third door, because writing the paper and reading the marks are
      // two different trusts.
      GoRoute(
        path: Routes.evaluations,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const EvaluationsScreen()),
      ),
      GoRoute(
        path: Routes.evaluationsManage,
        pageBuilder: (c, s) => fadeThroughPage(
          key: s.pageKey,
          child: const EvaluationsScreen(scope: EvaluationsScope.all),
        ),
      ),
      GoRoute(
        path: Routes.evaluationForms,
        pageBuilder: (c, s) => fadeThroughPage(
          key: s.pageKey,
          child: const EvaluationFormsScreen(),
        ),
      ),
    ],
  );
}
