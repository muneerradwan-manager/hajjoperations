import '../../l10n/app_localizations.dart';

/// Localized label for a permission code (parent sections + child actions),
/// falling back to the code itself.
String permissionLabel(AppLocalizations l, String code) => switch (code) {
  // Parents
  'employees' => l.perm_employees,
  'approvals' => l.perm_approvals,
  'seasons' => l.perm_seasons,
  'permissions' => l.perm_permissions,
  'notifications' => l.perm_notifications,
  'modules' => l.perm_modules,
  'reports' => l.perm_reports,
  // Children
  'employees.view' => l.permEmployeesView,
  'employees.create' => l.permEmployeesCreate,
  'employees.edit' => l.permEmployeesEdit,
  'employees.delete' => l.permEmployeesDelete,
  'employees.password' => l.permEmployeesPassword,
  'employees.suspend' => l.permEmployeesSuspend,
  'employees.external' => l.permEmployeesExternal,
  'employees.documents' => l.permEmployeesDocuments,
  'approvals.decide' => l.permApprovalsDecide,
  'seasons.manage' => l.permSeasonsManage,
  'seasons.participants' => l.permSeasonsParticipants,
  'permissions.manage' => l.permPermissionsManage,
  'notifications.send' => l.permNotificationsSend,
  'modules.manage' => l.permModulesManage,
  'modules.members' => l.permModulesMembers,
  'modules.types' => l.permModulesTypes,
  'reports.manage' => l.permReportsManage,
  _ => code,
};
