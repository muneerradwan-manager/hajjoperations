// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Hajj Operations';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonLogout => 'Log out';

  @override
  String get commonRequired => 'Required';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonOptional => 'Optional';

  @override
  String get commonNext => 'Next';

  @override
  String get commonBack => 'Back';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonSettings => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get authLoginTitle => 'Welcome back';

  @override
  String get authLoginSubtitle => 'Sign in to continue';

  @override
  String get authRegisterTitle => 'Create account';

  @override
  String get authRegisterSubtitle => 'Register with your email to get started';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authConfirmPassword => 'Confirm password';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignUp => 'Sign up';

  @override
  String get authOrContinueWith => 'or';

  @override
  String get authGoogle => 'Continue with Google';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authInvalidEmail => 'Enter a valid email';

  @override
  String get authPasswordTooShort => 'Password must be at least 8 characters';

  @override
  String get authPasswordMismatch => 'Passwords do not match';

  @override
  String get authCheckEmail =>
      'Check your email to confirm your account, then sign in.';

  @override
  String get profileCompleteTitle => 'Complete your profile';

  @override
  String get profileCompleteSubtitle =>
      'Fill in your details to submit for approval';

  @override
  String get profileFirstName => 'First name';

  @override
  String get profileSurname => 'Surname';

  @override
  String get profileFatherName => 'Father\'s name';

  @override
  String get profilePhoto => 'Profile photo';

  @override
  String get profileJobTitle => 'Job title';

  @override
  String get profileGender => 'Gender';

  @override
  String get profileDateOfBirth => 'Date of birth';

  @override
  String get profileMissionType => 'Mission type';

  @override
  String get profilePhoneSy => 'Syrian phone number';

  @override
  String get profilePhoneSa => 'Saudi phone number';

  @override
  String get profilePassportPhoto => 'Passport photo';

  @override
  String get profileVisaPhoto => 'Visa photo';

  @override
  String get profileNusukPhoto => 'Nusuk card photo';

  @override
  String get profileDocumentsSection => 'Documents (optional)';

  @override
  String get profilePickImage => 'Choose image';

  @override
  String get profileChangeImage => 'Change';

  @override
  String get profileSelectDate => 'Select date';

  @override
  String get profileSubmitForApproval => 'Submit for approval';

  @override
  String get profileCamera => 'Camera';

  @override
  String get profileGallery => 'Gallery';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get missionAdministrative => 'Administrative mission';

  @override
  String get missionReligious => 'Religious mission';

  @override
  String get missionMedical => 'Medical mission';

  @override
  String get statusPendingTitle => 'Pending approval';

  @override
  String get statusPendingMessage =>
      'Your account is under review. You\'ll gain access once an administrator approves it.';

  @override
  String get statusRejectedTitle => 'Account not approved';

  @override
  String get statusRejectedMessage => 'Your account was not approved.';

  @override
  String statusRejectedReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get statusEditAndResubmit => 'Edit and resubmit';

  @override
  String get statusSuspendedTitle => 'Account suspended';

  @override
  String get statusSuspendedMessage =>
      'Your account has been suspended. Please contact an administrator.';

  @override
  String get homeTitle => 'Home';

  @override
  String homeWelcome(String name) {
    return 'Welcome, $name';
  }

  @override
  String get homeAdminSection => 'Administration';

  @override
  String get homeGeneralSection => 'General';

  @override
  String get navApprovals => 'Account approvals';

  @override
  String get navApprovalsSubtitle => 'Review pending registrations';

  @override
  String get navMyProfile => 'My profile';

  @override
  String get approvalQueueTitle => 'Pending approvals';

  @override
  String get approvalEmpty => 'No accounts are waiting for approval';

  @override
  String approvalPendingCount(int count) {
    return '$count pending';
  }

  @override
  String get approvalDetailTitle => 'Review account';

  @override
  String get approvalApprove => 'Approve';

  @override
  String get approvalReject => 'Reject';

  @override
  String get approvalRejectReasonTitle => 'Reason for rejection';

  @override
  String get approvalRejectReasonHint => 'Optional — shown to the applicant';

  @override
  String get approvalApproved => 'Account approved';

  @override
  String get approvalRejected => 'Account rejected';

  @override
  String get profileSectionPersonal => 'Personal information';

  @override
  String get profileSectionContact => 'Contact';

  @override
  String get profileSectionDocuments => 'Documents';

  @override
  String get profileBadgeExternal => 'External';

  @override
  String get profileBadgeAdmin => 'Admin';

  @override
  String get profileFieldNotProvided => 'Not provided';

  @override
  String get profileNoPhone => '—';

  @override
  String get navPermissions => 'Permissions';

  @override
  String get navPermissionsSubtitle => 'Grant permissions to employees';

  @override
  String get permissionsEmployeesTitle => 'Employees';

  @override
  String get permissionEditorTitle => 'Permissions';

  @override
  String get employeesEmpty => 'No employees yet';

  @override
  String get permissionSaved => 'Permissions updated';

  @override
  String permissionGrantedCount(int count, int total) {
    return '$count of $total granted';
  }

  @override
  String get commonSearch => 'Search';

  @override
  String get commonSelectAll => 'Select all';

  @override
  String get permAllGranted => 'Full access (administrator)';

  @override
  String get perm_employees => 'Employees';

  @override
  String get perm_approvals => 'Account approvals';

  @override
  String get perm_seasons => 'Seasons';

  @override
  String get perm_permissions => 'Permissions';

  @override
  String get permEmployeesView => 'View employees & details';

  @override
  String get permEmployeesCreate => 'Add employees';

  @override
  String get permEmployeesSuspend => 'Suspend / reactivate accounts';

  @override
  String get permEmployeesExternal => 'Manage external status';

  @override
  String get permEmployeesDocuments => 'View documents';

  @override
  String get permApprovalsDecide => 'Approve & reject accounts';

  @override
  String get permSeasonsManage => 'Manage seasons';

  @override
  String get permSeasonsParticipants => 'Manage participants';

  @override
  String get permPermissionsManage => 'Grant & revoke permissions';

  @override
  String get perm_notifications => 'Notifications';

  @override
  String get permNotificationsSend => 'Send notifications';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications yet';

  @override
  String get notificationSend => 'Send notification';

  @override
  String get notificationTitleField => 'Title';

  @override
  String get notificationBodyField => 'Message';

  @override
  String get notificationSent => 'Notification sent';

  @override
  String get notificationMarkAllRead => 'Mark all as read';

  @override
  String get navSeasons => 'Seasons';

  @override
  String get navSeasonsSubtitle => 'Current season and archive';

  @override
  String get seasonsTitle => 'Seasons';

  @override
  String get seasonCurrentLabel => 'Current season';

  @override
  String get seasonUpcomingLabel => 'Upcoming seasons';

  @override
  String get seasonArchiveLabel => 'Previous seasons';

  @override
  String seasonHijriYear(int year) {
    return '$year AH';
  }

  @override
  String get seasonBadgeCurrent => 'Current';

  @override
  String get seasonParticipantsTitle => 'Participants';

  @override
  String seasonParticipantsCount(int count) {
    return '$count participants';
  }

  @override
  String get seasonManageParticipants => 'Manage participants';

  @override
  String get seasonNoParticipants => 'No participants in this season yet';

  @override
  String get seasonSetCurrent => 'Set as current season';

  @override
  String get seasonSetCurrentDone => 'Current season updated';

  @override
  String get seasonArchiveEmpty => 'No previous seasons';

  @override
  String get seasonSelectParticipants => 'Select participants';

  @override
  String get seasonParticipantsSaved => 'Participants updated';

  @override
  String get navEmployees => 'Employees';

  @override
  String get navEmployeesSubtitle => 'Staff directory and externals';

  @override
  String get employeesPermanentSection => 'Permanent staff';

  @override
  String get employeesExternalSection => 'External participants';

  @override
  String get employeesExternalEmpty => 'No external employees';

  @override
  String get employeeDetailTitle => 'Employee';

  @override
  String get employeeEditExternalTitle => 'External status';

  @override
  String get employeeIsExternal => 'External employee';

  @override
  String get employeeIsExternalHint =>
      'From another government body — not permanent staff';

  @override
  String get employeeOrganization => 'Organization / ministry';

  @override
  String get employeeExternalRole => 'Role at organization';

  @override
  String get employeeExternalSaved => 'Employee updated';

  @override
  String get employeeSectionOrganization => 'Organization';

  @override
  String get employeeSeasonsSection => 'Seasons taken part in';

  @override
  String get employeeSeasonsEmpty => 'Has not taken part in any season yet';

  @override
  String get employeeSeasonBadgeCurrent => 'Current';

  @override
  String get navMyProfileSubtitle => 'View and edit your details';

  @override
  String get myProfileEdit => 'Edit profile';

  @override
  String get myProfileChangePassword => 'Change password';

  @override
  String get myProfileNewPassword => 'New password';

  @override
  String get myProfileConfirmPassword => 'Confirm new password';

  @override
  String get myProfilePasswordChanged => 'Password changed';

  @override
  String get myProfileSaved => 'Profile updated';

  @override
  String get myProfileEditTitle => 'Edit profile';

  @override
  String get createEmployeeTitle => 'Create employee';

  @override
  String get createEmployeeCreated => 'Employee created';

  @override
  String get createEmployeeAccountSection => 'Account';

  @override
  String get createEmployeeSubmit => 'Create account';
}
