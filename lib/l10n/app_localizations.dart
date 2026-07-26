import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Hajj Operations'**
  String get appTitle;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get commonLogout;

  /// No description provided for @commonRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonRequired;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get commonOptional;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get commonSettings;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get authLoginSubtitle;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register with your email to get started'**
  String get authRegisterSubtitle;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPassword;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authSignUp;

  /// No description provided for @authOrContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOrContinueWith;

  /// No description provided for @authGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authGoogle;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccount;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authNoAccount;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get authInvalidEmail;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get authPasswordTooShort;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordMismatch;

  /// No description provided for @authCheckEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email to confirm your account, then sign in.'**
  String get authCheckEmail;

  /// No description provided for @profileCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get profileCompleteTitle;

  /// No description provided for @profileCompleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill in your details to submit for approval'**
  String get profileCompleteSubtitle;

  /// No description provided for @profileFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get profileFirstName;

  /// No description provided for @profileSurname.
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get profileSurname;

  /// No description provided for @profileFatherName.
  ///
  /// In en, this message translates to:
  /// **'Father\'s name'**
  String get profileFatherName;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profilePhoto;

  /// No description provided for @profileJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get profileJobTitle;

  /// No description provided for @profileGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profileGender;

  /// No description provided for @profileDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get profileDateOfBirth;

  /// No description provided for @profileMissionType.
  ///
  /// In en, this message translates to:
  /// **'Mission type'**
  String get profileMissionType;

  /// No description provided for @profilePhoneSy.
  ///
  /// In en, this message translates to:
  /// **'Syrian phone number'**
  String get profilePhoneSy;

  /// No description provided for @profilePhoneSa.
  ///
  /// In en, this message translates to:
  /// **'Saudi phone number'**
  String get profilePhoneSa;

  /// No description provided for @profilePassportPhoto.
  ///
  /// In en, this message translates to:
  /// **'Passport photo'**
  String get profilePassportPhoto;

  /// No description provided for @profileVisaPhoto.
  ///
  /// In en, this message translates to:
  /// **'Visa photo'**
  String get profileVisaPhoto;

  /// No description provided for @profileNusukPhoto.
  ///
  /// In en, this message translates to:
  /// **'Nusuk card photo'**
  String get profileNusukPhoto;

  /// No description provided for @profileDocumentsSection.
  ///
  /// In en, this message translates to:
  /// **'Documents (optional)'**
  String get profileDocumentsSection;

  /// No description provided for @profilePickImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get profilePickImage;

  /// No description provided for @profileChangeImage.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get profileChangeImage;

  /// No description provided for @profileSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get profileSelectDate;

  /// No description provided for @profileSubmitForApproval.
  ///
  /// In en, this message translates to:
  /// **'Submit for approval'**
  String get profileSubmitForApproval;

  /// No description provided for @profileCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get profileCamera;

  /// No description provided for @profileGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get profileGallery;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @missionAdministrative.
  ///
  /// In en, this message translates to:
  /// **'Administrative mission'**
  String get missionAdministrative;

  /// No description provided for @missionReligious.
  ///
  /// In en, this message translates to:
  /// **'Religious mission'**
  String get missionReligious;

  /// No description provided for @missionMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical mission'**
  String get missionMedical;

  /// No description provided for @statusPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending approval'**
  String get statusPendingTitle;

  /// No description provided for @statusPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account is under review. You\'ll gain access once an administrator approves it.'**
  String get statusPendingMessage;

  /// No description provided for @statusRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account not approved'**
  String get statusRejectedTitle;

  /// No description provided for @statusRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account was not approved.'**
  String get statusRejectedMessage;

  /// No description provided for @statusRejectedReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String statusRejectedReason(String reason);

  /// No description provided for @statusEditAndResubmit.
  ///
  /// In en, this message translates to:
  /// **'Edit and resubmit'**
  String get statusEditAndResubmit;

  /// No description provided for @statusSuspendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account suspended'**
  String get statusSuspendedTitle;

  /// No description provided for @statusSuspendedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been suspended. Please contact an administrator.'**
  String get statusSuspendedMessage;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @homeWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String homeWelcome(String name);

  /// No description provided for @homeAdminSection.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get homeAdminSection;

  /// No description provided for @homeGeneralSection.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get homeGeneralSection;

  /// No description provided for @navApprovals.
  ///
  /// In en, this message translates to:
  /// **'Account approvals'**
  String get navApprovals;

  /// No description provided for @navApprovalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review pending registrations'**
  String get navApprovalsSubtitle;

  /// No description provided for @navMyProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get navMyProfile;

  /// No description provided for @approvalQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending approvals'**
  String get approvalQueueTitle;

  /// No description provided for @approvalEmpty.
  ///
  /// In en, this message translates to:
  /// **'No accounts are waiting for approval'**
  String get approvalEmpty;

  /// No description provided for @approvalPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String approvalPendingCount(int count);

  /// No description provided for @approvalDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Review account'**
  String get approvalDetailTitle;

  /// No description provided for @approvalApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approvalApprove;

  /// No description provided for @approvalReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get approvalReject;

  /// No description provided for @approvalRejectReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection'**
  String get approvalRejectReasonTitle;

  /// No description provided for @approvalRejectReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Optional — shown to the applicant'**
  String get approvalRejectReasonHint;

  /// No description provided for @approvalApproved.
  ///
  /// In en, this message translates to:
  /// **'Account approved'**
  String get approvalApproved;

  /// No description provided for @approvalRejected.
  ///
  /// In en, this message translates to:
  /// **'Account rejected'**
  String get approvalRejected;

  /// No description provided for @profileSectionPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get profileSectionPersonal;

  /// No description provided for @profileSectionContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get profileSectionContact;

  /// No description provided for @profileSectionDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get profileSectionDocuments;

  /// No description provided for @profileBadgeExternal.
  ///
  /// In en, this message translates to:
  /// **'External'**
  String get profileBadgeExternal;

  /// No description provided for @profileBadgeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get profileBadgeAdmin;

  /// No description provided for @profileFieldNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get profileFieldNotProvided;

  /// No description provided for @profileNoPhone.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get profileNoPhone;

  /// No description provided for @navPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get navPermissions;

  /// No description provided for @navPermissionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Grant permissions to employees'**
  String get navPermissionsSubtitle;

  /// No description provided for @permissionsEmployeesTitle.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get permissionsEmployeesTitle;

  /// No description provided for @permissionEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissionEditorTitle;

  /// No description provided for @employeesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No employees yet'**
  String get employeesEmpty;

  /// No description provided for @permissionSaved.
  ///
  /// In en, this message translates to:
  /// **'Permissions updated'**
  String get permissionSaved;

  /// No description provided for @permissionGrantedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} granted'**
  String permissionGrantedCount(int count, int total);

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get commonSelectAll;

  /// No description provided for @permAllGranted.
  ///
  /// In en, this message translates to:
  /// **'Full access (administrator)'**
  String get permAllGranted;

  /// No description provided for @perm_employees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get perm_employees;

  /// No description provided for @perm_approvals.
  ///
  /// In en, this message translates to:
  /// **'Account approvals'**
  String get perm_approvals;

  /// No description provided for @perm_seasons.
  ///
  /// In en, this message translates to:
  /// **'Seasons'**
  String get perm_seasons;

  /// No description provided for @perm_permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get perm_permissions;

  /// No description provided for @permEmployeesView.
  ///
  /// In en, this message translates to:
  /// **'View employees & details'**
  String get permEmployeesView;

  /// No description provided for @permEmployeesCreate.
  ///
  /// In en, this message translates to:
  /// **'Add employees'**
  String get permEmployeesCreate;

  /// No description provided for @permEmployeesSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend / reactivate accounts'**
  String get permEmployeesSuspend;

  /// No description provided for @permEmployeesExternal.
  ///
  /// In en, this message translates to:
  /// **'Manage external status'**
  String get permEmployeesExternal;

  /// No description provided for @permEmployeesDocuments.
  ///
  /// In en, this message translates to:
  /// **'View documents'**
  String get permEmployeesDocuments;

  /// No description provided for @permApprovalsDecide.
  ///
  /// In en, this message translates to:
  /// **'Approve & reject accounts'**
  String get permApprovalsDecide;

  /// No description provided for @permSeasonsManage.
  ///
  /// In en, this message translates to:
  /// **'Manage seasons'**
  String get permSeasonsManage;

  /// No description provided for @permSeasonsParticipants.
  ///
  /// In en, this message translates to:
  /// **'Manage participants'**
  String get permSeasonsParticipants;

  /// No description provided for @permPermissionsManage.
  ///
  /// In en, this message translates to:
  /// **'Grant & revoke permissions'**
  String get permPermissionsManage;

  /// No description provided for @perm_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get perm_notifications;

  /// No description provided for @permNotificationsSend.
  ///
  /// In en, this message translates to:
  /// **'Send notifications'**
  String get permNotificationsSend;

  /// No description provided for @navNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmpty;

  /// No description provided for @notificationSend.
  ///
  /// In en, this message translates to:
  /// **'Send notification'**
  String get notificationSend;

  /// No description provided for @notificationTitleField.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get notificationTitleField;

  /// No description provided for @notificationBodyField.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get notificationBodyField;

  /// No description provided for @notificationSent.
  ///
  /// In en, this message translates to:
  /// **'Notification sent'**
  String get notificationSent;

  /// No description provided for @notificationMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationMarkAllRead;

  /// No description provided for @navSeasons.
  ///
  /// In en, this message translates to:
  /// **'Seasons'**
  String get navSeasons;

  /// No description provided for @navSeasonsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Current season and archive'**
  String get navSeasonsSubtitle;

  /// No description provided for @seasonsTitle.
  ///
  /// In en, this message translates to:
  /// **'Seasons'**
  String get seasonsTitle;

  /// No description provided for @seasonCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current season'**
  String get seasonCurrentLabel;

  /// No description provided for @seasonUpcomingLabel.
  ///
  /// In en, this message translates to:
  /// **'Upcoming seasons'**
  String get seasonUpcomingLabel;

  /// No description provided for @seasonArchiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Previous seasons'**
  String get seasonArchiveLabel;

  /// No description provided for @seasonHijriYear.
  ///
  /// In en, this message translates to:
  /// **'{year} AH'**
  String seasonHijriYear(int year);

  /// No description provided for @seasonBadgeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get seasonBadgeCurrent;

  /// No description provided for @seasonParticipantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get seasonParticipantsTitle;

  /// No description provided for @seasonParticipantsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} participants'**
  String seasonParticipantsCount(int count);

  /// No description provided for @seasonManageParticipants.
  ///
  /// In en, this message translates to:
  /// **'Manage participants'**
  String get seasonManageParticipants;

  /// No description provided for @seasonNoParticipants.
  ///
  /// In en, this message translates to:
  /// **'No participants in this season yet'**
  String get seasonNoParticipants;

  /// No description provided for @seasonSetCurrent.
  ///
  /// In en, this message translates to:
  /// **'Set as current season'**
  String get seasonSetCurrent;

  /// No description provided for @seasonSetCurrentDone.
  ///
  /// In en, this message translates to:
  /// **'Current season updated'**
  String get seasonSetCurrentDone;

  /// No description provided for @seasonArchiveEmpty.
  ///
  /// In en, this message translates to:
  /// **'No previous seasons'**
  String get seasonArchiveEmpty;

  /// No description provided for @seasonSelectParticipants.
  ///
  /// In en, this message translates to:
  /// **'Select participants'**
  String get seasonSelectParticipants;

  /// No description provided for @seasonParticipantsSaved.
  ///
  /// In en, this message translates to:
  /// **'Participants updated'**
  String get seasonParticipantsSaved;

  /// No description provided for @navEmployees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get navEmployees;

  /// No description provided for @navEmployeesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Staff directory and externals'**
  String get navEmployeesSubtitle;

  /// No description provided for @employeesPermanentSection.
  ///
  /// In en, this message translates to:
  /// **'Permanent staff'**
  String get employeesPermanentSection;

  /// No description provided for @employeesExternalSection.
  ///
  /// In en, this message translates to:
  /// **'External participants'**
  String get employeesExternalSection;

  /// No description provided for @employeesExternalEmpty.
  ///
  /// In en, this message translates to:
  /// **'No external employees'**
  String get employeesExternalEmpty;

  /// No description provided for @employeeDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get employeeDetailTitle;

  /// No description provided for @employeeEditExternalTitle.
  ///
  /// In en, this message translates to:
  /// **'External status'**
  String get employeeEditExternalTitle;

  /// No description provided for @employeeIsExternal.
  ///
  /// In en, this message translates to:
  /// **'External employee'**
  String get employeeIsExternal;

  /// No description provided for @employeeIsExternalHint.
  ///
  /// In en, this message translates to:
  /// **'From another government body — not permanent staff'**
  String get employeeIsExternalHint;

  /// No description provided for @employeeOrganization.
  ///
  /// In en, this message translates to:
  /// **'Organization / ministry'**
  String get employeeOrganization;

  /// No description provided for @employeeExternalRole.
  ///
  /// In en, this message translates to:
  /// **'Role at organization'**
  String get employeeExternalRole;

  /// No description provided for @employeeExternalSaved.
  ///
  /// In en, this message translates to:
  /// **'Employee updated'**
  String get employeeExternalSaved;

  /// No description provided for @employeeSectionOrganization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get employeeSectionOrganization;

  /// No description provided for @employeeSeasonsSection.
  ///
  /// In en, this message translates to:
  /// **'Seasons taken part in'**
  String get employeeSeasonsSection;

  /// No description provided for @employeeSeasonsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Has not taken part in any season yet'**
  String get employeeSeasonsEmpty;

  /// No description provided for @employeeSeasonBadgeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get employeeSeasonBadgeCurrent;

  /// No description provided for @navMyProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and edit your details'**
  String get navMyProfileSubtitle;

  /// No description provided for @myProfileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get myProfileEdit;

  /// No description provided for @myProfileChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get myProfileChangePassword;

  /// No description provided for @myProfileNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get myProfileNewPassword;

  /// No description provided for @myProfileConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get myProfileConfirmPassword;

  /// No description provided for @myProfilePasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get myProfilePasswordChanged;

  /// No description provided for @myProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get myProfileSaved;

  /// No description provided for @myProfileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get myProfileEditTitle;

  /// No description provided for @createEmployeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Create employee'**
  String get createEmployeeTitle;

  /// No description provided for @createEmployeeCreated.
  ///
  /// In en, this message translates to:
  /// **'Employee created'**
  String get createEmployeeCreated;

  /// No description provided for @createEmployeeAccountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get createEmployeeAccountSection;

  /// No description provided for @createEmployeeSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createEmployeeSubmit;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
