/// Permission codes — must match the `permissions.code` values seeded in the DB
/// (see supabase/migrations/0073_granular_permissions.sql).
///
/// One code per action. Sections (`employees`, `seasons`, …) are headings in
/// the catalog, not grants: the `.view` action of a section is what opens it.
/// What an action needs before it works (assigning members needs seeing
/// employees, deciding needs seeing the queue) lives in the DB table
/// `permission_prerequisites`, which both the editor UI and two DB triggers
/// enforce — a grant cannot exist without its ground.
class PermissionCodes {
  const PermissionCodes._();

  // -------------------------------------------------------------- employees
  static const employeesView = 'employees.view';
  static const employeesCreate = 'employees.create';
  static const employeesEdit = 'employees.edit';
  static const employeesDelete = 'employees.delete';
  static const employeesSuspend = 'employees.suspend';
  static const employeesExternal = 'employees.external';
  static const employeesDocuments = 'employees.documents';

  /// Resetting someone else's password. Deliberately not folded into
  /// [employeesEdit]: correcting a record and taking over a login are not the
  /// same trust (see migration 0072).
  static const employeesPassword = 'employees.password';

  /// Changing someone else's email address — the login itself. Its own code
  /// for the same reason the password has one (see migration 0076).
  static const employeesEmail = 'employees.email';

  // -------------------------------------------------------------- approvals
  static const approvalsView = 'approvals.view';
  static const approvalsDecide = 'approvals.decide';

  // ---------------------------------------------------------------- seasons
  static const seasonsView = 'seasons.view';

  /// Setting the current season — the highest-leverage single action in the
  /// app: it reslices files, master data, reports and the dashboard for
  /// everyone at once.
  static const seasonsSwitch = 'seasons.switch';
  static const seasonsParticipantsView = 'seasons.participants_view';
  static const seasonsParticipantsManage = 'seasons.participants_manage';

  // ---------------------------------------------------------------- modules
  static const modulesViewAll = 'modules.view_all';
  static const modulesCreate = 'modules.create';
  static const modulesEdit = 'modules.edit';
  static const modulesDelete = 'modules.delete';

  /// Releasing a file to its members (and taking it back). Separate from
  /// [modulesEdit] because activation notifies everyone assigned — it is a
  /// send, not a correction.
  static const modulesActivate = 'modules.activate';
  static const modulesMembers = 'modules.members';
  static const modulesReports = 'modules.reports';

  // -------------------------------------------------------------- reference
  static const referenceView = 'reference.view';
  static const referenceEdit = 'reference.edit';
  static const referenceDelete = 'reference.delete';
  static const referenceImport = 'reference.import';

  // ---------------------------------------------------------------- reports
  static const reportsViewAll = 'reports.view_all';
  static const reportsCreate = 'reports.create';
  static const reportsEdit = 'reports.edit';
  static const reportsDelete = 'reports.delete';

  /// Publishing puts a report before the whole mission; correcting a cell does
  /// not. Two different trusts, two codes.
  static const reportsPublish = 'reports.publish';

  // ---------------------------------------------------------- notifications
  /// One person.
  static const notificationsSend = 'notifications.send';

  /// Everyone in one operational file.
  static const notificationsBroadcastModule = 'notifications.broadcast_module';

  /// Everyone with a working account.
  static const notificationsBroadcastAll = 'notifications.broadcast_all';

  // ------------------------------------------------------------ permissions
  static const permissionsView = 'permissions.view';
  static const permissionsManage = 'permissions.manage';
}
