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
  String get commonConnectionErrorTitle => 'Couldn\'t reach the server';

  @override
  String get commonConnectionErrorBody =>
      'Check your internet connection and try again.';

  @override
  String get commonGenericError => 'Something went wrong. Please try again.';

  @override
  String get commonLogout => 'Log out';

  @override
  String get commonLoggingOut => 'Signing out…';

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
  String get commonDone => 'Done';

  @override
  String get commonCopied => 'Copied';

  @override
  String get profileEmail => 'Email';

  @override
  String get commonMore => 'More';

  @override
  String get moduleNotifyMembers => 'Notify everyone in this file';

  @override
  String get employeeNotify => 'Send a notification';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonSettings => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsNotifications => 'Notifications on this device';

  @override
  String get settingsNotificationsHint =>
      'Turning this off only silences the device — messages still reach your inbox';

  @override
  String get settingsLogoutConfirm =>
      'Log out of this device? The account leaves the quick-switch list, and signing back in will ask for the password.';

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
  String get accountsTitle => 'Accounts';

  @override
  String get accountsSaved => 'Quick sign-in';

  @override
  String get accountsSavedHint =>
      'Accounts saved on this device — tap one to sign in without a password';

  @override
  String get accountsCurrent => 'Current account';

  @override
  String get accountsAdd => 'Add another account';

  @override
  String get accountsAddTitle => 'Add account';

  @override
  String get accountsAddSubtitle =>
      'Sign in with another account — the one you are using stays saved to return to';

  @override
  String get accountsSwitching => 'Switching account…';

  @override
  String get accountsRemove => 'Remove from this device';

  @override
  String accountsRemoveConfirm(String name) {
    return 'Remove $name from this device\'s list? Signing back in will ask for the password.';
  }

  @override
  String get accountsExpired =>
      'This account\'s session on this device has expired. Sign in with it again.';

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
  String get profileCity => 'City';

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
  String get permEmployeesEdit => 'Edit employee records';

  @override
  String get permEmployeesDelete => 'Delete employee records';

  @override
  String get permEmployeesPassword => 'Reset an employee\'s password';

  @override
  String get permEmployeesEmail => 'Change an employee\'s email address';

  @override
  String get permEmployeesSuspend => 'Suspend & reactivate accounts';

  @override
  String get permEmployeesExternal => 'Manage external status';

  @override
  String get permEmployeesDocuments => 'View employee documents';

  @override
  String get permApprovalsView => 'View registration requests';

  @override
  String get permApprovalsDecide => 'Approve & reject requests';

  @override
  String get permSeasonsView => 'View seasons';

  @override
  String get permSeasonsSwitch => 'Set the current season';

  @override
  String get permSeasonsParticipantsView => 'View season participants';

  @override
  String get permSeasonsParticipantsManage => 'Add & withdraw participants';

  @override
  String get permPermissionsView => 'View granted permissions';

  @override
  String get permPermissionsManage => 'Grant & revoke permissions';

  @override
  String get perm_reference => 'Master data';

  @override
  String get permReferenceView => 'View master data';

  @override
  String get permReferenceEdit => 'Add & edit master data';

  @override
  String get permReferenceDelete => 'Delete master data';

  @override
  String get permReferenceImport => 'Copy data from another season';

  @override
  String get perm_reports => 'Reports';

  @override
  String get permReportsViewAll => 'View all reports, including drafts';

  @override
  String get permReportsCreate => 'Create reports';

  @override
  String get permReportsEdit => 'Edit reports';

  @override
  String get permReportsDelete => 'Delete reports';

  @override
  String get permReportsPublish => 'Publish & unpublish reports';

  @override
  String get perm_notifications => 'Notifications';

  @override
  String get permNotificationsSend => 'Notify an individual employee';

  @override
  String get permNotificationsBroadcastModule => 'Notify a file\'s members';

  @override
  String get permNotificationsBroadcastAll => 'Notify everyone';

  @override
  String get perm_audit => 'Audit log';

  @override
  String get permAuditView => 'Read the record of who did what';

  @override
  String get perm_complaints => 'Complaints';

  @override
  String get permComplaintsView => 'View every complaint filed';

  @override
  String get permComplaintsReply => 'Take part in any complaint thread';

  @override
  String get permComplaintsLock => 'Close a complaint to further replies';

  @override
  String get permComplaintsDismiss => 'Dismiss a complaint as unfounded';

  @override
  String get permComplaintsDelete => 'Delete a complaint';

  @override
  String permissionRequires(String names) {
    return 'Requires: $names';
  }

  @override
  String get permissionDenied =>
      'You don\'t hold the permission this action needs';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get notificationTargetGone => 'That file is no longer available';

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
  String get notificationAudience => 'Send to';

  @override
  String get notificationAudienceAll => 'Everyone';

  @override
  String get notificationAudienceModule => 'Members of a file';

  @override
  String get notificationChooseModule => 'Choose the file';

  @override
  String get notificationBroadcastHint =>
      'Reaches everyone holding a role in the file';

  @override
  String get notificationAttach => 'Attach';

  @override
  String get notificationAttachPhoto => 'Photo';

  @override
  String get notificationAttachCamera => 'Take a photo';

  @override
  String get notificationAttachVideo => 'Video';

  @override
  String get notificationAttachAudio => 'Audio';

  @override
  String get notificationAttachFile => 'File';

  @override
  String notificationAttachmentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attachments',
      one: '1 attachment',
    );
    return '$_temp0';
  }

  @override
  String get attachmentImage => 'Image';

  @override
  String get attachmentVideo => 'Video';

  @override
  String get attachmentAudio => 'Audio';

  @override
  String get attachmentFile => 'File';

  @override
  String get attachmentDownload => 'Download';

  @override
  String get attachmentOpenFailed => 'Could not open the attachment';

  @override
  String get modulesSearchHint => 'Search files';

  @override
  String get modulesNoMatches => 'No file matches';

  @override
  String get reportScanCode => 'Scan';

  @override
  String get reportTimeFrom => 'From';

  @override
  String get reportTimeTo => 'To';

  @override
  String reportTimeRange(String from, String to) {
    return 'From $from to $to';
  }

  @override
  String get reportAddTag => 'Add an item';

  @override
  String get reportNumber => 'Report number';

  @override
  String reportNumberBadge(String number) {
    return 'No. $number';
  }

  @override
  String get reportContentSection => 'Content';

  @override
  String get reportContentHint =>
      'Build the report from the pieces below — a heading, prose, a list, a table, a link, a code to scan. They appear in the order you add them.';

  @override
  String get reportNoBlocks => 'Nothing added yet';

  @override
  String get blockHeading => 'Heading';

  @override
  String get blockSubheading => 'Subheading';

  @override
  String get blockParagraph => 'Paragraph';

  @override
  String get blockBullets => 'Bulleted list';

  @override
  String get blockNumbers => 'Numbered list';

  @override
  String get blockTable => 'Table';

  @override
  String get blockUrl => 'Link';

  @override
  String get blockQr => 'QR code';

  @override
  String get blockNote => 'Note';

  @override
  String get blockDivider => 'Divider';

  @override
  String get blockMoveUp => 'Move up';

  @override
  String get blockMoveDown => 'Move down';

  @override
  String get blockTextShort => 'Text';

  @override
  String get blockTextLong => 'Text';

  @override
  String get blockItems => 'Items';

  @override
  String get blockItemsHint => 'One per line';

  @override
  String get blockLabel => 'Label';

  @override
  String get blockQrValue => 'What the code carries';

  @override
  String get blockQrHint => 'Usually a link';

  @override
  String get blockTableColumns => 'Columns';

  @override
  String get blockTableColumnsHint => 'Separated by |';

  @override
  String get blockTableRows => 'Rows';

  @override
  String get blockTableRowsHint => 'One row per line, cells separated by |';

  @override
  String get blockAddItem => 'Add an item';

  @override
  String get blockAddColumn => 'Add a column';

  @override
  String get blockTableNeedsColumns => 'Name the columns first, then add rows';

  @override
  String get reportNew => 'New report';

  @override
  String get reportEdit => 'Edit report';

  @override
  String get reportSaved => 'Report saved';

  @override
  String get reportIdentity => 'What this report is';

  @override
  String get reportTitle => 'Title';

  @override
  String get reportScopeHint =>
      'General reports stay true whichever season is running';

  @override
  String get reportOncePerSeason =>
      'This kind of report is created only once per season, and it already exists — edit the existing one instead of creating another';

  @override
  String get reportPublished => 'Published';

  @override
  String get reportPublishedHint =>
      'An unpublished report is visible only to whoever manages reports';

  @override
  String get reportAddRow => 'Add a row';

  @override
  String get reportNoRows => 'No rows yet';

  @override
  String get reportsManageEmpty => 'No reports yet';

  @override
  String reportDeleteConfirm(String title) {
    return 'Delete $title? This cannot be undone.';
  }

  @override
  String get reportDeleted => 'Report deleted';

  @override
  String reportRowsSection(int count) {
    return 'Rows ($count)';
  }

  @override
  String reportRowNumber(int number) {
    return 'Row $number';
  }

  @override
  String get navReportsManage => 'Reports management';

  @override
  String get navReportsManageSubtitle => 'Enter, correct and publish reports';

  @override
  String get navReports => 'Reports';

  @override
  String get navReportsSubtitle =>
      'Timetables and notices published to the mission';

  @override
  String get reportsEmpty => 'Nothing has been published yet';

  @override
  String get reportsNoMatches => 'No report matches';

  @override
  String get reportsSearchHint => 'Search reports';

  @override
  String get reportsScopeAll => 'All';

  @override
  String get reportsScopeSeasonal => 'This season';

  @override
  String get reportsScopeGeneral => 'General';

  @override
  String get reportsDraft => 'Unpublished';

  @override
  String get reportMissing => 'That report is no longer available';

  @override
  String get reportAboutSection => 'About this report';

  @override
  String get reportKind => 'Kind';

  @override
  String get reportScope => 'Applies to';

  @override
  String get reportAbout => 'What it covers';

  @override
  String get reportSource => 'The original document';

  @override
  String get reportQrFailed => 'This code could not be drawn';

  @override
  String reportUpdated(String date) {
    return 'Last updated $date';
  }

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
  String get modulePickerOnlyFree => 'Unassigned only';

  @override
  String get moduleRosterSearchHint => 'Search by name or role';

  @override
  String get moduleRosterAllRoles => 'All roles';

  @override
  String get moduleRosterClear => 'Clear';

  @override
  String moduleRosterShowing(int showing, int total) {
    return 'Showing $showing of $total';
  }

  @override
  String get moduleRosterNoMatch => 'Nobody in this file matches';

  @override
  String referenceChildCount(String list) {
    return '$list assigned';
  }

  @override
  String referenceOfCapacity(int total, int capacity) {
    return '$total of $capacity';
  }

  @override
  String referenceOverCapacity(int excess) {
    return 'Over capacity by $excess';
  }

  @override
  String get employeePermissionsSection => 'Granted permissions';

  @override
  String get employeePermissionsEmpty => 'No permissions granted';

  @override
  String get employeePermissionsAdmin =>
      'An administrator — holds every permission, without needing to be granted them.';

  @override
  String get employeeEditDetailsTitle => 'Edit employee details';

  @override
  String get employeeEditSaved => 'Employee details updated';

  @override
  String get employeeEdit => 'Edit details';

  @override
  String get employeeDelete => 'Delete employee';

  @override
  String get employeeDeleteConfirmTitle => 'Delete this employee?';

  @override
  String employeeDeleteConfirmBody(String name) {
    return '$name will be removed permanently, along with their account and every assignment they hold. This cannot be undone.';
  }

  @override
  String get employeeDeleted => 'Employee deleted';

  @override
  String get employeeDeleteAdminBlocked =>
      'An administrator cannot be deleted. Remove their admin role first.';

  @override
  String get employeePassword => 'Change password';

  @override
  String employeePasswordTitle(String name) {
    return 'New password for $name';
  }

  @override
  String get employeePasswordHint =>
      'The employee signs in with the new password from now on. Tell them yourself — no message is sent.';

  @override
  String get employeePasswordNew => 'New password';

  @override
  String get employeePasswordConfirm => 'Confirm password';

  @override
  String get employeePasswordChanged => 'Password changed';

  @override
  String get employeePasswordAdminBlocked =>
      'Only an administrator can change another administrator\'s password.';

  @override
  String get employeeEmail => 'Change email';

  @override
  String employeeEmailTitle(String name) {
    return 'New email for $name';
  }

  @override
  String get employeeEmailHint =>
      'The employee signs in with the new email from now on. Tell them yourself — no message is sent to either address.';

  @override
  String get employeeEmailNew => 'New email';

  @override
  String get employeeEmailChanged => 'Email changed';

  @override
  String get employeeEmailAdminBlocked =>
      'Only an administrator can change another administrator\'s email.';

  @override
  String get employeeEmailTaken =>
      'This email is already used by another account.';

  @override
  String get myProfileChangeEmail => 'Change email';

  @override
  String get myProfileNewEmail => 'New email';

  @override
  String get myProfileEmailChanged =>
      'Email changed. You sign in with the new address from now on.';

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
  String get employeeModulesSection => 'Assigned modules';

  @override
  String get employeeModulesEmpty => 'Not assigned to any operational module';

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

  @override
  String get commonDelete => 'Delete';

  @override
  String get perm_modules => 'Operational files';

  @override
  String get permModulesViewAll => 'View all files, including drafts';

  @override
  String get permModulesCreate => 'Create an operational file';

  @override
  String get permModulesEdit => 'Edit a file & its structure';

  @override
  String get permModulesDelete => 'Delete an operational file';

  @override
  String get permModulesActivate => 'Activate & deactivate files';

  @override
  String get permModulesMembers => 'Assign members & duties';

  @override
  String get permModulesReports => 'Read members\' file reports';

  @override
  String get navModules => 'Operational modules';

  @override
  String get navModulesSubtitle =>
      'The files you were assigned to, and your roles in them';

  @override
  String get navReferenceData => 'Master data';

  @override
  String get navReferenceDataSubtitle => 'Hotels, clusters and other lists';

  @override
  String get modulesManageTitle => 'Manage operational files';

  @override
  String get modulesEmptyMine => 'No files were assigned to you this season';

  @override
  String get navModulesManage => 'Manage operational files';

  @override
  String get navModulesManageSubtitle =>
      'Every file of the season, and opening a new one';

  @override
  String get modulesTitle => 'Operational files';

  @override
  String get modulesEmpty => 'No files have been assigned to you yet';

  @override
  String get modulesEmptyManager => 'No files created yet';

  @override
  String get moduleActiveSection => 'Active files';

  @override
  String get moduleDraftSection => 'Drafts';

  @override
  String get moduleBadgeDraft => 'Draft';

  @override
  String get moduleNew => 'New file';

  @override
  String get moduleChooseType => 'Choose a file type';

  @override
  String get moduleNoTypes => 'No file types have been defined yet';

  @override
  String get moduleAllTypesUsed =>
      'Every file type has already been opened for this season';

  @override
  String get moduleOnePerSeason =>
      'A file of a kind is created once per season, and its type is its name';

  @override
  String get moduleSeasonLabel => 'Season';

  @override
  String moduleDecisionBadge(String number) {
    return 'Decision $number';
  }

  @override
  String get moduleDecisionNumber => 'Decision / file number';

  @override
  String get moduleDecisionNumberHint =>
      'Optional — added when the decision is issued';

  @override
  String get moduleEndDate => 'End date';

  @override
  String get moduleEndDateHint =>
      'Optional — the file ends at the close of this day';

  @override
  String get moduleEndDateClear => 'No end date';

  @override
  String get moduleEndBeforeStart => 'The end date is before the start date';

  @override
  String get moduleStartDate => 'Work starts on';

  @override
  String get moduleReportCadence => 'Reports';

  @override
  String get moduleReportCadenceHint =>
      'How often the people in this file file one';

  @override
  String get cadenceNone => 'No reports';

  @override
  String get cadenceDaily => 'Daily';

  @override
  String get cadenceWeekly => 'Weekly';

  @override
  String get cadenceOnce => 'Once';

  @override
  String get moduleRatingSection => 'Rating';

  @override
  String get moduleRatingMine => 'My rating in this file';

  @override
  String get moduleRatingNone => 'Nobody has rated you in this file yet';

  @override
  String moduleRatingValue(String average, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ratings',
      one: '1 rating',
    );
    return '$average of 5 · $_temp0';
  }

  @override
  String get moduleRatingRate => 'Rate your colleagues in this file';

  @override
  String get moduleRatingAnonymous =>
      'Ratings are anonymous — a colleague sees his average and how many rated him, never who gave what';

  @override
  String get moduleRatingSaved => 'Rating saved';

  @override
  String get moduleRatingCleared => 'Rating withdrawn';

  @override
  String get moduleReports => 'Reports';

  @override
  String get moduleReportWrite => 'File a report';

  @override
  String get moduleReportEdit => 'Edit my report';

  @override
  String get moduleReportNotes => 'Notes';

  @override
  String get moduleReportNotesHint =>
      'Optional — anything to add about what you attached';

  @override
  String get moduleReportAttachHint =>
      'The report is what you upload: photos, files or a voice note';

  @override
  String get moduleReportNothingAttached => 'Nothing attached';

  @override
  String get moduleReportSaved => 'Report filed';

  @override
  String get moduleReportsEmpty => 'No reports filed yet';

  @override
  String moduleReportPeriodDay(String date) {
    return 'Report for $date';
  }

  @override
  String moduleReportPeriodWeek(String date) {
    return 'Week of $date';
  }

  @override
  String get moduleStartCondition => 'Work begins';

  @override
  String get moduleEndCondition => 'Ends';

  @override
  String get moduleStepInfo => 'File';

  @override
  String get moduleStepSectors => 'Sectors';

  @override
  String get moduleStepTowers => 'Towers';

  @override
  String get moduleStepMembers => 'Team';

  @override
  String get moduleNodeName => 'Name';

  @override
  String moduleNodeAdd(String level) {
    return 'Add $level';
  }

  @override
  String moduleNodeEdit(String level) {
    return 'Edit $level';
  }

  @override
  String moduleNodeDelete(String level) {
    return 'Delete $level';
  }

  @override
  String moduleNodeDeleteConfirm(String name) {
    return 'Delete “$name”? Everything inside it goes with it.';
  }

  @override
  String moduleNodeSuggestedName(String level, int number) {
    return '$level $number';
  }

  @override
  String get moduleSectorsImport => 'Import sectors';

  @override
  String get moduleSectorsImportPick =>
      'Copy the sectors from another file in this season — the name, the supervisor and his deputy. The copies are independent: deleting a sector here does not touch the other file.';

  @override
  String moduleSectorsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count sectors',
      one: 'Imported 1 sector',
      zero: 'No new sectors',
    );
    return '$_temp0';
  }

  @override
  String get moduleSectorsImportFailed => 'Could not import the sectors';

  @override
  String get moduleSectorsImportNoSources =>
      'No other file in this season has sectors';

  @override
  String get moduleNoNodes => 'Nothing has been added yet';

  @override
  String get moduleSectorsFirst =>
      'Add the sectors first, then place the hotels in them';

  @override
  String get moduleBuildTree => 'Add sectors & towers';

  @override
  String get moduleNoLevels => 'This file type has no structure defined yet';

  @override
  String get moduleSectionInfo => 'File information';

  @override
  String get moduleSectionTasks => 'My role & duties';

  @override
  String moduleSectionTasksOf(String name) {
    return '$name — role & duties';
  }

  @override
  String get moduleJobDescription => 'Job description';

  @override
  String get moduleNoTasks => 'No tasks are defined for this role yet';

  @override
  String get moduleAssignedTasks => 'Assigned duties';

  @override
  String moduleAssignedTasksCount(int count, int total) {
    return '$count of $total duties';
  }

  @override
  String get moduleNoAssignedTasks => 'No duties assigned yet';

  @override
  String get moduleNoAssignedTasksMine =>
      'You have not been handed any duty from this role\'s list yet';

  @override
  String get moduleTeamPick => 'Choose members';

  @override
  String get moduleNoTeamMembers => 'No one has been put on this team yet';

  @override
  String get moduleNoRoles => 'This file type has no roles defined yet';

  @override
  String moduleMembersCount(int count) {
    return '$count members';
  }

  @override
  String get moduleNoMembers => 'No one has been assigned here yet';

  @override
  String get moduleRoleUnassigned => 'Not assigned';

  @override
  String get moduleSaved => 'Saved';

  @override
  String get moduleActivate => 'Activate file';

  @override
  String get moduleDeactivate => 'Deactivate file';

  @override
  String get moduleActivated => 'File activated — members have been notified';

  @override
  String get moduleDeactivated => 'File deactivated';

  @override
  String get moduleAttachPdf => 'Attach PDF';

  @override
  String get moduleReplacePdf => 'Replace file';

  @override
  String get moduleOpenPdf => 'Open PDF';

  @override
  String get moduleNoPdf => 'No file attached';

  @override
  String get modulePdfOpenFailed => 'Could not open the file';

  @override
  String get moduleDelete => 'Delete file';

  @override
  String get moduleDeleteConfirm =>
      'Delete this file? Everything in it — its members, the duties they were handed, and its attachments — goes with it.';

  @override
  String get moduleDeleted => 'File deleted';

  @override
  String get moduleNoCurrentSeason =>
      'Set a current season before creating files';

  @override
  String get moduleNoParticipants =>
      'The current season has no participants yet';

  @override
  String get moduleContactSy => 'Syrian number';

  @override
  String get moduleContactSa => 'Saudi number';

  @override
  String get modulePickerSearchHint => 'Search by name or job title';

  @override
  String get modulePickerAll => 'Everyone';

  @override
  String get modulePickerInternal => 'Mission staff';

  @override
  String get modulePickerExternal => 'External';

  @override
  String get modulePickerNoMatches => 'Nobody matches that search';

  @override
  String get modulePickerFree => 'Not in any file';

  @override
  String modulePickerAlreadyIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Already in $count files',
      one: 'Already in 1 file',
    );
    return '$_temp0';
  }

  @override
  String modulePickerConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Confirm $count people',
      one: 'Confirm 1 person',
      zero: 'Confirm with nobody chosen',
    );
    return '$_temp0';
  }

  @override
  String get referenceDataTitle => 'Master data';

  @override
  String referenceItemsCount(int count) {
    return '$count entries';
  }

  @override
  String get referenceImport => 'Import from another season';

  @override
  String get referenceImportPick =>
      'Copy the list from an earlier season. The copies are independent — deleting one here does not touch the other season.';

  @override
  String referenceImported(int count) {
    return 'Imported $count entries';
  }

  @override
  String get referenceImportFailed => 'Import failed';

  @override
  String get referenceImportNoSeasons => 'No other seasons';

  @override
  String get referenceAddItem => 'Add entry';

  @override
  String get referenceItemName => 'Name (Arabic)';

  @override
  String get referenceItemNameEn => 'Name (English)';

  @override
  String get referenceItemSaved => 'Entry saved';

  @override
  String get referenceItemDeleted => 'Entry deleted';

  @override
  String get referenceEmpty => 'No entries yet';

  @override
  String referenceDeleteConfirm(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get referenceInUse =>
      'This entry is used by a module and cannot be deleted';

  @override
  String get referenceDuplicate =>
      'An entry with this name already exists in the list';

  @override
  String get referenceDeleteAll => 'Delete all';

  @override
  String referenceDeleteAllConfirm(int count, String name) {
    return 'This permanently deletes $count entries from “$name”. It cannot be undone.';
  }

  @override
  String referenceDeleteAllDone(int count) {
    return 'Deleted $count entries';
  }

  @override
  String referenceDeleteAllPartial(int deleted, int kept) {
    return 'Deleted $deleted; $kept kept because they are used by modules or other lists';
  }

  @override
  String get referenceDeleteAllNone =>
      'Nothing was deleted: every entry is used by a module or another list';

  @override
  String get referenceDeletingAll => 'Deleting…';

  @override
  String get referenceOpenLink => 'Open link';

  @override
  String get locationPickerTitle => 'Set location';

  @override
  String get locationPickOnMap => 'On the map';

  @override
  String get locationUseCurrent => 'My location';

  @override
  String get locationOrPasteLink => 'Or paste a map link';

  @override
  String get locationTapToPlace => 'Tap the map to place the pin';

  @override
  String get locationConfirm => 'Confirm this location';

  @override
  String get locationCaptured => 'Current location captured';

  @override
  String get locationPermissionDenied => 'Location access was not granted';

  @override
  String get locationServiceDisabled => 'Location services are turned off';

  @override
  String get locationFailed => 'Could not determine your location';

  @override
  String get locationOpenMap => 'Open on map';

  @override
  String get referenceCall => 'Call';

  @override
  String get referenceLinkFailed => 'Could not open the link';

  @override
  String get referenceDetailsTitle => 'Details';

  @override
  String get profileSectionPermissions => 'Permissions';

  @override
  String get profilePermissionsAdmin => 'Administrator — every permission';

  @override
  String get profilePermissionsNone => 'No administrative permissions';

  @override
  String get profilePermissionsNoneHint =>
      'Which is the ordinary case: an operational file reaches you by assignment, not by permission.';

  @override
  String profilePermissionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count permissions',
      one: 'one permission',
    );
    return '$_temp0';
  }

  @override
  String get navAuditLog => 'Activity log';

  @override
  String get navAuditLogSubtitle => 'Who did what, and when';

  @override
  String get auditEmptyTitle => 'No events yet';

  @override
  String get auditEmptyBody => 'Every change made in the app is recorded here.';

  @override
  String get auditSearchHint => 'Search by person or record…';

  @override
  String get auditActionInsert => 'Added';

  @override
  String get auditActionUpdate => 'Edited';

  @override
  String get auditActionDelete => 'Deleted';

  @override
  String get auditActionLogin => 'Signed in';

  @override
  String get auditActionLogout => 'Signed out';

  @override
  String get auditFilterAction => 'Action';

  @override
  String get auditFilterEntity => 'Section';

  @override
  String get auditFilterActor => 'Person';

  @override
  String get auditFilterDate => 'Period';

  @override
  String get auditClearFilters => 'Clear filters';

  @override
  String get auditSystem => 'System';

  @override
  String get auditDetails => 'Event details';

  @override
  String get auditActor => 'Done by';

  @override
  String get auditChanges => 'What changed';

  @override
  String get auditRecordData => 'Record data';

  @override
  String get auditDeletedData => 'Deleted record';

  @override
  String auditRecipients(int count) {
    return '$count recipients';
  }

  @override
  String get auditYes => 'Yes';

  @override
  String get auditNo => 'No';

  @override
  String get auditNoDetails => 'This event carries no further details.';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navDashboardSubtitle => 'The season from above';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardSeason => 'Season';

  @override
  String get dashboardNoSeason => 'No season yet';

  @override
  String get dashboardNothingToShow =>
      'You hold no permission that shows figures here';

  @override
  String get dashboardSectionPeople => 'People';

  @override
  String get dashboardSectionModules => 'Operational files';

  @override
  String get dashboardSectionWork => 'The work';

  @override
  String get dashboardSectionQueue => 'Approvals';

  @override
  String get dashboardSectionCentralReports => 'Central reports';

  @override
  String get dashboardCentralPublished => 'Published';

  @override
  String get dashboardCentralDrafts => 'Drafts';

  @override
  String get dashboardCentralGeneral => 'General (all seasons)';

  @override
  String get dashboardCentralByType => 'By type';

  @override
  String get dashboardCentralSplit => 'Published vs drafts';

  @override
  String get dashboardSectionNotifications => 'Notifications';

  @override
  String get dashboardNotifMessages30 => 'Messages (30 days)';

  @override
  String get dashboardNotifRecipients => 'Recipients';

  @override
  String get dashboardNotifReadShare => 'Read rate';

  @override
  String get dashboardNotifTrend => 'Messages, last 30 days';

  @override
  String get dashboardNotifTrendEmpty => 'No messages in the last 30 days';

  @override
  String dashboardNotifAllTime(Object n) {
    return '$n messages all-time';
  }

  @override
  String get dashboardSectionReference => 'Master data';

  @override
  String get dashboardRefSets => 'Lists';

  @override
  String get dashboardRefItems => 'Entries';

  @override
  String get dashboardRefActive => 'Active';

  @override
  String get dashboardRefSeasonSplit => 'Seasonal vs general';

  @override
  String get dashboardRefSeasonItems => 'This season';

  @override
  String get dashboardRefGeneralItems => 'General';

  @override
  String get dashboardRefBySet => 'Entries per list';

  @override
  String get dashboardSectionPermissions => 'Permissions';

  @override
  String get dashboardPermAdmins => 'Admins';

  @override
  String get dashboardPermGrantees => 'Employees with grants';

  @override
  String get dashboardPermGrants => 'Grants held';

  @override
  String get dashboardPermBySection => 'Grants by section';

  @override
  String get dashboardParticipants => 'On this season';

  @override
  String get dashboardWithdrawn => 'Withdrawn';

  @override
  String dashboardWithdrawnCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'and $count withdrew',
      one: 'and one withdrew',
      zero: 'nobody withdrew',
    );
    return '$_temp0';
  }

  @override
  String get dashboardInternal => 'Of the mission';

  @override
  String get dashboardExternal => 'From outside';

  @override
  String get dashboardUnknown => 'Not stated';

  @override
  String get dashboardByMission => 'By mission type';

  @override
  String get dashboardByGender => 'By gender';

  @override
  String get dashboardByJobTitle => 'Largest trades';

  @override
  String get dashboardFiles => 'Files';

  @override
  String dashboardFilesCaption(int active, int draft) {
    return '$active active, $draft draft';
  }

  @override
  String get dashboardRunning => 'Running';

  @override
  String get dashboardEnded => 'Ended';

  @override
  String get dashboardNodes => 'Sectors and towers';

  @override
  String get dashboardMembers => 'Hold a posting';

  @override
  String get dashboardUnstaffed => 'Files with nobody in them';

  @override
  String get dashboardUnstaffedCaption => 'Nobody assigned yet';

  @override
  String get dashboardByType => 'By file type';

  @override
  String get dashboardActiveDraft => 'Active against draft';

  @override
  String get dashboardReports => 'Reports';

  @override
  String dashboardReportsCaption(int authors) {
    String _temp0 = intl.Intl.pluralLogic(
      authors,
      locale: localeName,
      other: 'from $authors authors',
      one: 'from one author',
      zero: 'from nobody',
    );
    return '$_temp0';
  }

  @override
  String get dashboardReportsTrend => 'Reports over 30 days';

  @override
  String get dashboardReportsEmpty => 'No reports filed in this stretch';

  @override
  String get dashboardRatings => 'Ratings';

  @override
  String get dashboardAverage => 'Average';

  @override
  String dashboardRatedPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'about $count people',
      one: 'about one person',
      zero: 'nobody rated',
    );
    return '$_temp0';
  }

  @override
  String get dashboardRatingDistribution => 'Star distribution';

  @override
  String get dashboardPending => 'Awaiting approval';

  @override
  String get dashboardApproved => 'Approved';

  @override
  String get dashboardRejected => 'Rejected';

  @override
  String get dashboardIncomplete => 'Profile incomplete';

  @override
  String get prayerTimesTitle => 'Prayer times';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerSunrise => 'Sunrise';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

  @override
  String get prayerNextLabel => 'Next prayer';

  @override
  String get prayerFajrEndsLabel => 'Fajr time ends';

  @override
  String get prayerRemainingLabel => 'remaining';

  @override
  String get prayerNowLabel => 'Now';

  @override
  String get prayerAm => 'AM';

  @override
  String get prayerPm => 'PM';

  @override
  String get prayerTomorrow => 'tomorrow';

  @override
  String get prayerSunriseGapNote => 'Sunrise — no prayer is due until Dhuhr';

  @override
  String get prayerLocating => 'Finding you…';

  @override
  String get prayerApproximate => 'Approximate';

  @override
  String get prayerYourLocation => 'Your location';

  @override
  String get prayerPlaceMakkah => 'Makkah';

  @override
  String get prayerPlaceMina => 'Mina';

  @override
  String get prayerPlaceMuzdalifah => 'Muzdalifah';

  @override
  String get prayerPlaceArafat => 'Arafat';

  @override
  String get prayerPlaceMadinah => 'Madinah';

  @override
  String get prayerPlaceJeddah => 'Jeddah';

  @override
  String get navMyComplaints => 'My complaints';

  @override
  String get navMyComplaintsSubtitle => 'What you filed, and what came back';

  @override
  String get navComplaints => 'Complaints';

  @override
  String get navComplaintsSubtitle =>
      'Every complaint filed across the mission';

  @override
  String get complaintsTitle => 'Complaints';

  @override
  String get complaintsMineTitle => 'My complaints';

  @override
  String get complaintsAgainstMeTitle => 'Complaints about me';

  @override
  String get complaintsNew => 'File a complaint';

  @override
  String get complaintsEmpty => 'No complaints filed';

  @override
  String get complaintsEmptyAll => 'Nothing has been filed yet';

  @override
  String get complaintsAgainstMeEmpty => 'Nothing has been filed about you';

  @override
  String get complaintsNoMatches => 'No complaint matches this';

  @override
  String get complaintsSearchHint => 'Search complaints';

  @override
  String get complaintsFilterAll => 'All';

  @override
  String get complaintsShowDismissed => 'Include dismissed';

  @override
  String get complaintTarget => 'About';

  @override
  String get complaintTargetEmployee => 'An employee';

  @override
  String get complaintTargetModule => 'An operational file';

  @override
  String get complaintTargetReport => 'A report';

  @override
  String get complaintTargetHotel => 'A hotel';

  @override
  String get complaintTargetCluster => 'A cluster';

  @override
  String get complaintTargetGroup => 'A group';

  @override
  String get complaintTargetOther => 'Something else';

  @override
  String get complaintTargetPick => 'Choose what this is about';

  @override
  String complaintTargetPicked(String name) {
    return 'Selected: $name';
  }

  @override
  String get complaintBody => 'What happened';

  @override
  String get complaintBodyHint => 'Describe it in your own words';

  @override
  String get complaintBodyRequired => 'Write what happened';

  @override
  String get complaintTargetRequired => 'Choose what the complaint is about';

  @override
  String get complaintSubmit => 'Send the complaint';

  @override
  String get complaintSubmitted => 'Your complaint was filed';

  @override
  String get complaintAnonymousNote =>
      'The person you are complaining about will read this, but will not be told who filed it.';

  @override
  String get complaintReply => 'Reply';

  @override
  String get complaintReplyHint => 'Write a reply';

  @override
  String get complaintReplySent => 'Reply sent';

  @override
  String complaintReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count replies',
      one: '1 reply',
      zero: 'No replies',
    );
    return '$_temp0';
  }

  @override
  String get complaintRoleComplainant => 'The complainant';

  @override
  String get complaintRoleAccused => 'The employee complained about';

  @override
  String get complaintRoleManager => 'Oversight';

  @override
  String get complaintLocked => 'This complaint is closed to replies';

  @override
  String get complaintLock => 'Close to replies';

  @override
  String get complaintUnlock => 'Reopen for replies';

  @override
  String get complaintDismissed => 'Dismissed';

  @override
  String get complaintDismiss => 'Dismiss as unfounded';

  @override
  String get complaintUndismiss => 'Reinstate';

  @override
  String get complaintDismissReason => 'Why it is being dismissed (optional)';

  @override
  String get complaintDismissConfirm =>
      'A dismissed complaint no longer counts toward an automatic suspension, and may lift one already in force. Dismiss it?';

  @override
  String get complaintDelete => 'Delete the complaint';

  @override
  String get complaintDeleteConfirm =>
      'Delete this complaint and everything attached to it? This cannot be undone.';

  @override
  String get complaintDeleted => 'Complaint deleted';

  @override
  String get complaintWithdraw => 'Withdraw';

  @override
  String get complaintMissing => 'This complaint is no longer there';

  @override
  String complaintFiledOn(String date) {
    return 'Filed $date';
  }

  @override
  String get complaintsSectionAgainst => 'Complaints about this employee';

  @override
  String complaintsAgainstCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count complaints',
      one: '1 complaint',
      zero: 'None',
    );
    return '$_temp0';
  }

  @override
  String complaintsDistinctComplainants(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count different people',
      one: '1 person',
      zero: 'no one',
    );
    return '$_temp0';
  }

  @override
  String get complaintsAutoSuspended => 'Suspended automatically by complaints';

  @override
  String get complaintsAutoSuspendNear =>
      'One more complainant suspends this account automatically';

  @override
  String complaintsDismissedCount(int count) {
    return '$count dismissed';
  }
}
