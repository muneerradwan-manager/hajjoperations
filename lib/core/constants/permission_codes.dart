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

  // Children (actions)
  static const employeesView = 'employees.view';
  static const employeesCreate = 'employees.create';
  static const employeesSuspend = 'employees.suspend';
  static const employeesExternal = 'employees.external';
  static const employeesDocuments = 'employees.documents';
  static const approvalsDecide = 'approvals.decide';
  static const seasonsManage = 'seasons.manage';
  static const seasonsParticipants = 'seasons.participants';
  static const permissionsManage = 'permissions.manage';
  static const notificationsSend = 'notifications.send';
}
