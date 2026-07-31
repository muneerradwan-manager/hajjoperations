/// Permission codes — must match the `permissions.code` values seeded in the DB
/// (see supabase/migrations/0013_hierarchical_permissions.sql).
///
/// Hierarchy: parent sections gate access to a module; child actions gate the
/// specific operations within it. Granting a child implies its parent is granted.
class PermissionCodes {
  const PermissionCodes._();

  // Parents (sections)
  static const employees = 'employees';
  static const approvals = 'approvals';
  static const seasons = 'seasons';
  static const permissions = 'permissions';
  static const notifications = 'notifications';
  static const modules = 'modules';
  static const reports = 'reports';

  // Children (actions)
  static const employeesView = 'employees.view';
  static const employeesCreate = 'employees.create';
  static const employeesEdit = 'employees.edit';
  static const employeesDelete = 'employees.delete';

  /// Resetting someone else's password. Deliberately not folded into
  /// [employeesEdit]: correcting a record and taking over a login are not the
  /// same trust (see migration 0072).
  static const employeesPassword = 'employees.password';
  static const employeesSuspend = 'employees.suspend';
  static const employeesExternal = 'employees.external';
  static const employeesDocuments = 'employees.documents';
  static const approvalsDecide = 'approvals.decide';
  static const seasonsManage = 'seasons.manage';
  static const seasonsParticipants = 'seasons.participants';
  static const permissionsManage = 'permissions.manage';
  static const notificationsSend = 'notifications.send';
  static const modulesManage = 'modules.manage';
  static const modulesMembers = 'modules.members';
  static const modulesTypes = 'modules.types';

  /// Reading a published report needs nothing — it is under عام. This is what
  /// entering, correcting and publishing one needs.
  static const reportsManage = 'reports.manage';
}
