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

  /// No description provided for @commonConnectionErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the server'**
  String get commonConnectionErrorTitle;

  /// No description provided for @commonConnectionErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get commonConnectionErrorBody;

  /// No description provided for @commonGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get commonGenericError;

  /// No description provided for @commonLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get commonLogout;

  /// No description provided for @commonLoggingOut.
  ///
  /// In en, this message translates to:
  /// **'Signing out…'**
  String get commonLoggingOut;

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

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get commonCopied;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @commonMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// No description provided for @moduleNotifyMembers.
  ///
  /// In en, this message translates to:
  /// **'Notify everyone in this file'**
  String get moduleNotifyMembers;

  /// No description provided for @employeeNotify.
  ///
  /// In en, this message translates to:
  /// **'Send a notification'**
  String get employeeNotify;

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

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications on this device'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Turning this off only silences the device — messages still reach your inbox'**
  String get settingsNotificationsHint;

  /// No description provided for @settingsLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Log out of this device? The account leaves the quick-switch list, and signing back in will ask for the password.'**
  String get settingsLogoutConfirm;

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

  /// No description provided for @accountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsTitle;

  /// No description provided for @accountsSaved.
  ///
  /// In en, this message translates to:
  /// **'Quick sign-in'**
  String get accountsSaved;

  /// No description provided for @accountsSavedHint.
  ///
  /// In en, this message translates to:
  /// **'Accounts saved on this device — tap one to sign in without a password'**
  String get accountsSavedHint;

  /// No description provided for @accountsCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current account'**
  String get accountsCurrent;

  /// No description provided for @accountsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add another account'**
  String get accountsAdd;

  /// No description provided for @accountsAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get accountsAddTitle;

  /// No description provided for @accountsAddSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with another account — the one you are using stays saved to return to'**
  String get accountsAddSubtitle;

  /// No description provided for @accountsSwitching.
  ///
  /// In en, this message translates to:
  /// **'Switching account…'**
  String get accountsSwitching;

  /// No description provided for @accountsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from this device'**
  String get accountsRemove;

  /// No description provided for @accountsRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this device\'s list? Signing back in will ask for the password.'**
  String accountsRemoveConfirm(String name);

  /// No description provided for @accountsExpired.
  ///
  /// In en, this message translates to:
  /// **'This account\'s session on this device has expired. Sign in with it again.'**
  String get accountsExpired;

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

  /// No description provided for @profileCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get profileCity;

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

  /// No description provided for @permEmployeesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit employee records'**
  String get permEmployeesEdit;

  /// No description provided for @permEmployeesDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete employee records'**
  String get permEmployeesDelete;

  /// No description provided for @permEmployeesPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset an employee\'s password'**
  String get permEmployeesPassword;

  /// No description provided for @permEmployeesEmail.
  ///
  /// In en, this message translates to:
  /// **'Change an employee\'s email address'**
  String get permEmployeesEmail;

  /// No description provided for @permEmployeesSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend & reactivate accounts'**
  String get permEmployeesSuspend;

  /// No description provided for @permEmployeesExternal.
  ///
  /// In en, this message translates to:
  /// **'Manage external status'**
  String get permEmployeesExternal;

  /// No description provided for @permEmployeesDocuments.
  ///
  /// In en, this message translates to:
  /// **'View employee documents'**
  String get permEmployeesDocuments;

  /// No description provided for @permApprovalsView.
  ///
  /// In en, this message translates to:
  /// **'View registration requests'**
  String get permApprovalsView;

  /// No description provided for @permApprovalsDecide.
  ///
  /// In en, this message translates to:
  /// **'Approve & reject requests'**
  String get permApprovalsDecide;

  /// No description provided for @permSeasonsView.
  ///
  /// In en, this message translates to:
  /// **'View seasons'**
  String get permSeasonsView;

  /// No description provided for @permSeasonsSwitch.
  ///
  /// In en, this message translates to:
  /// **'Set the current season'**
  String get permSeasonsSwitch;

  /// No description provided for @permSeasonsParticipantsView.
  ///
  /// In en, this message translates to:
  /// **'View season participants'**
  String get permSeasonsParticipantsView;

  /// No description provided for @permSeasonsParticipantsManage.
  ///
  /// In en, this message translates to:
  /// **'Add & withdraw participants'**
  String get permSeasonsParticipantsManage;

  /// No description provided for @permPermissionsView.
  ///
  /// In en, this message translates to:
  /// **'View granted permissions'**
  String get permPermissionsView;

  /// No description provided for @permPermissionsManage.
  ///
  /// In en, this message translates to:
  /// **'Grant & revoke permissions'**
  String get permPermissionsManage;

  /// No description provided for @perm_reference.
  ///
  /// In en, this message translates to:
  /// **'Master data'**
  String get perm_reference;

  /// No description provided for @permReferenceView.
  ///
  /// In en, this message translates to:
  /// **'View master data'**
  String get permReferenceView;

  /// No description provided for @permReferenceEdit.
  ///
  /// In en, this message translates to:
  /// **'Add & edit master data'**
  String get permReferenceEdit;

  /// No description provided for @permReferenceDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete master data'**
  String get permReferenceDelete;

  /// No description provided for @permReferenceImport.
  ///
  /// In en, this message translates to:
  /// **'Copy data from another season'**
  String get permReferenceImport;

  /// No description provided for @perm_reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get perm_reports;

  /// No description provided for @permReportsViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all reports, including drafts'**
  String get permReportsViewAll;

  /// No description provided for @permReportsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create reports'**
  String get permReportsCreate;

  /// No description provided for @permReportsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit reports'**
  String get permReportsEdit;

  /// No description provided for @permReportsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete reports'**
  String get permReportsDelete;

  /// No description provided for @permReportsPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish & unpublish reports'**
  String get permReportsPublish;

  /// No description provided for @perm_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get perm_notifications;

  /// No description provided for @permNotificationsSend.
  ///
  /// In en, this message translates to:
  /// **'Notify an individual employee'**
  String get permNotificationsSend;

  /// No description provided for @permNotificationsBroadcastModule.
  ///
  /// In en, this message translates to:
  /// **'Notify a file\'s members'**
  String get permNotificationsBroadcastModule;

  /// No description provided for @permNotificationsBroadcastAll.
  ///
  /// In en, this message translates to:
  /// **'Notify everyone'**
  String get permNotificationsBroadcastAll;

  /// No description provided for @permissionRequires.
  ///
  /// In en, this message translates to:
  /// **'Requires: {names}'**
  String permissionRequires(String names);

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You don\'t hold the permission this action needs'**
  String get permissionDenied;

  /// No description provided for @navNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// No description provided for @notificationTargetGone.
  ///
  /// In en, this message translates to:
  /// **'That file is no longer available'**
  String get notificationTargetGone;

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

  /// No description provided for @notificationAudience.
  ///
  /// In en, this message translates to:
  /// **'Send to'**
  String get notificationAudience;

  /// No description provided for @notificationAudienceAll.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get notificationAudienceAll;

  /// No description provided for @notificationAudienceModule.
  ///
  /// In en, this message translates to:
  /// **'Members of a file'**
  String get notificationAudienceModule;

  /// No description provided for @notificationChooseModule.
  ///
  /// In en, this message translates to:
  /// **'Choose the file'**
  String get notificationChooseModule;

  /// No description provided for @notificationBroadcastHint.
  ///
  /// In en, this message translates to:
  /// **'Reaches everyone holding a role in the file'**
  String get notificationBroadcastHint;

  /// No description provided for @notificationAttach.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get notificationAttach;

  /// No description provided for @notificationAttachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get notificationAttachPhoto;

  /// No description provided for @notificationAttachCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get notificationAttachCamera;

  /// No description provided for @notificationAttachVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get notificationAttachVideo;

  /// No description provided for @notificationAttachAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get notificationAttachAudio;

  /// No description provided for @notificationAttachFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get notificationAttachFile;

  /// No description provided for @notificationAttachmentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attachment} other{{count} attachments}}'**
  String notificationAttachmentsCount(int count);

  /// No description provided for @attachmentImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get attachmentImage;

  /// No description provided for @attachmentVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get attachmentVideo;

  /// No description provided for @attachmentAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get attachmentAudio;

  /// No description provided for @attachmentFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get attachmentFile;

  /// No description provided for @attachmentDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get attachmentDownload;

  /// No description provided for @attachmentOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the attachment'**
  String get attachmentOpenFailed;

  /// No description provided for @modulesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search files'**
  String get modulesSearchHint;

  /// No description provided for @modulesNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No file matches'**
  String get modulesNoMatches;

  /// No description provided for @reportScanCode.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get reportScanCode;

  /// No description provided for @reportTimeFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get reportTimeFrom;

  /// No description provided for @reportTimeTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get reportTimeTo;

  /// No description provided for @reportTimeRange.
  ///
  /// In en, this message translates to:
  /// **'From {from} to {to}'**
  String reportTimeRange(String from, String to);

  /// No description provided for @reportAddTag.
  ///
  /// In en, this message translates to:
  /// **'Add an item'**
  String get reportAddTag;

  /// No description provided for @reportNumber.
  ///
  /// In en, this message translates to:
  /// **'Report number'**
  String get reportNumber;

  /// No description provided for @reportNumberBadge.
  ///
  /// In en, this message translates to:
  /// **'No. {number}'**
  String reportNumberBadge(String number);

  /// No description provided for @reportContentSection.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get reportContentSection;

  /// No description provided for @reportContentHint.
  ///
  /// In en, this message translates to:
  /// **'Build the report from the pieces below — a heading, prose, a list, a table, a link, a code to scan. They appear in the order you add them.'**
  String get reportContentHint;

  /// No description provided for @reportNoBlocks.
  ///
  /// In en, this message translates to:
  /// **'Nothing added yet'**
  String get reportNoBlocks;

  /// No description provided for @blockHeading.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get blockHeading;

  /// No description provided for @blockSubheading.
  ///
  /// In en, this message translates to:
  /// **'Subheading'**
  String get blockSubheading;

  /// No description provided for @blockParagraph.
  ///
  /// In en, this message translates to:
  /// **'Paragraph'**
  String get blockParagraph;

  /// No description provided for @blockBullets.
  ///
  /// In en, this message translates to:
  /// **'Bulleted list'**
  String get blockBullets;

  /// No description provided for @blockNumbers.
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get blockNumbers;

  /// No description provided for @blockTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get blockTable;

  /// No description provided for @blockUrl.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get blockUrl;

  /// No description provided for @blockQr.
  ///
  /// In en, this message translates to:
  /// **'QR code'**
  String get blockQr;

  /// No description provided for @blockNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get blockNote;

  /// No description provided for @blockDivider.
  ///
  /// In en, this message translates to:
  /// **'Divider'**
  String get blockDivider;

  /// No description provided for @blockMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get blockMoveUp;

  /// No description provided for @blockMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get blockMoveDown;

  /// No description provided for @blockTextShort.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get blockTextShort;

  /// No description provided for @blockTextLong.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get blockTextLong;

  /// No description provided for @blockItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get blockItems;

  /// No description provided for @blockItemsHint.
  ///
  /// In en, this message translates to:
  /// **'One per line'**
  String get blockItemsHint;

  /// No description provided for @blockLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get blockLabel;

  /// No description provided for @blockQrValue.
  ///
  /// In en, this message translates to:
  /// **'What the code carries'**
  String get blockQrValue;

  /// No description provided for @blockQrHint.
  ///
  /// In en, this message translates to:
  /// **'Usually a link'**
  String get blockQrHint;

  /// No description provided for @blockTableColumns.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get blockTableColumns;

  /// No description provided for @blockTableColumnsHint.
  ///
  /// In en, this message translates to:
  /// **'Separated by |'**
  String get blockTableColumnsHint;

  /// No description provided for @blockTableRows.
  ///
  /// In en, this message translates to:
  /// **'Rows'**
  String get blockTableRows;

  /// No description provided for @blockTableRowsHint.
  ///
  /// In en, this message translates to:
  /// **'One row per line, cells separated by |'**
  String get blockTableRowsHint;

  /// No description provided for @blockAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add an item'**
  String get blockAddItem;

  /// No description provided for @blockAddColumn.
  ///
  /// In en, this message translates to:
  /// **'Add a column'**
  String get blockAddColumn;

  /// No description provided for @blockTableNeedsColumns.
  ///
  /// In en, this message translates to:
  /// **'Name the columns first, then add rows'**
  String get blockTableNeedsColumns;

  /// No description provided for @reportNew.
  ///
  /// In en, this message translates to:
  /// **'New report'**
  String get reportNew;

  /// No description provided for @reportEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit report'**
  String get reportEdit;

  /// No description provided for @reportSaved.
  ///
  /// In en, this message translates to:
  /// **'Report saved'**
  String get reportSaved;

  /// No description provided for @reportIdentity.
  ///
  /// In en, this message translates to:
  /// **'What this report is'**
  String get reportIdentity;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get reportTitle;

  /// No description provided for @reportScopeHint.
  ///
  /// In en, this message translates to:
  /// **'General reports stay true whichever season is running'**
  String get reportScopeHint;

  /// No description provided for @reportPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get reportPublished;

  /// No description provided for @reportPublishedHint.
  ///
  /// In en, this message translates to:
  /// **'An unpublished report is visible only to whoever manages reports'**
  String get reportPublishedHint;

  /// No description provided for @reportAddRow.
  ///
  /// In en, this message translates to:
  /// **'Add a row'**
  String get reportAddRow;

  /// No description provided for @reportNoRows.
  ///
  /// In en, this message translates to:
  /// **'No rows yet'**
  String get reportNoRows;

  /// No description provided for @reportsManageEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get reportsManageEmpty;

  /// No description provided for @reportDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {title}? This cannot be undone.'**
  String reportDeleteConfirm(String title);

  /// No description provided for @reportDeleted.
  ///
  /// In en, this message translates to:
  /// **'Report deleted'**
  String get reportDeleted;

  /// No description provided for @reportRowsSection.
  ///
  /// In en, this message translates to:
  /// **'Rows ({count})'**
  String reportRowsSection(int count);

  /// No description provided for @reportRowNumber.
  ///
  /// In en, this message translates to:
  /// **'Row {number}'**
  String reportRowNumber(int number);

  /// No description provided for @navReportsManage.
  ///
  /// In en, this message translates to:
  /// **'Reports management'**
  String get navReportsManage;

  /// No description provided for @navReportsManageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter, correct and publish reports'**
  String get navReportsManageSubtitle;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Timetables and notices published to the mission'**
  String get navReportsSubtitle;

  /// No description provided for @reportsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been published yet'**
  String get reportsEmpty;

  /// No description provided for @reportsNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No report matches'**
  String get reportsNoMatches;

  /// No description provided for @reportsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search reports'**
  String get reportsSearchHint;

  /// No description provided for @reportsScopeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reportsScopeAll;

  /// No description provided for @reportsScopeSeasonal.
  ///
  /// In en, this message translates to:
  /// **'This season'**
  String get reportsScopeSeasonal;

  /// No description provided for @reportsScopeGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get reportsScopeGeneral;

  /// No description provided for @reportsDraft.
  ///
  /// In en, this message translates to:
  /// **'Unpublished'**
  String get reportsDraft;

  /// No description provided for @reportMissing.
  ///
  /// In en, this message translates to:
  /// **'That report is no longer available'**
  String get reportMissing;

  /// No description provided for @reportAboutSection.
  ///
  /// In en, this message translates to:
  /// **'About this report'**
  String get reportAboutSection;

  /// No description provided for @reportKind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get reportKind;

  /// No description provided for @reportScope.
  ///
  /// In en, this message translates to:
  /// **'Applies to'**
  String get reportScope;

  /// No description provided for @reportAbout.
  ///
  /// In en, this message translates to:
  /// **'What it covers'**
  String get reportAbout;

  /// No description provided for @reportSource.
  ///
  /// In en, this message translates to:
  /// **'The original document'**
  String get reportSource;

  /// No description provided for @reportQrFailed.
  ///
  /// In en, this message translates to:
  /// **'This code could not be drawn'**
  String get reportQrFailed;

  /// No description provided for @reportUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated {date}'**
  String reportUpdated(String date);

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

  /// No description provided for @modulePickerOnlyFree.
  ///
  /// In en, this message translates to:
  /// **'Unassigned only'**
  String get modulePickerOnlyFree;

  /// No description provided for @moduleRosterSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or role'**
  String get moduleRosterSearchHint;

  /// No description provided for @moduleRosterAllRoles.
  ///
  /// In en, this message translates to:
  /// **'All roles'**
  String get moduleRosterAllRoles;

  /// No description provided for @moduleRosterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get moduleRosterClear;

  /// No description provided for @moduleRosterShowing.
  ///
  /// In en, this message translates to:
  /// **'Showing {showing} of {total}'**
  String moduleRosterShowing(int showing, int total);

  /// No description provided for @moduleRosterNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Nobody in this file matches'**
  String get moduleRosterNoMatch;

  /// No description provided for @referenceChildCount.
  ///
  /// In en, this message translates to:
  /// **'{list} assigned'**
  String referenceChildCount(String list);

  /// No description provided for @referenceOfCapacity.
  ///
  /// In en, this message translates to:
  /// **'{total} of {capacity}'**
  String referenceOfCapacity(int total, int capacity);

  /// No description provided for @referenceOverCapacity.
  ///
  /// In en, this message translates to:
  /// **'Over capacity by {excess}'**
  String referenceOverCapacity(int excess);

  /// No description provided for @employeePermissionsSection.
  ///
  /// In en, this message translates to:
  /// **'Granted permissions'**
  String get employeePermissionsSection;

  /// No description provided for @employeePermissionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No permissions granted'**
  String get employeePermissionsEmpty;

  /// No description provided for @employeePermissionsAdmin.
  ///
  /// In en, this message translates to:
  /// **'An administrator — holds every permission, without needing to be granted them.'**
  String get employeePermissionsAdmin;

  /// No description provided for @employeeEditDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit employee details'**
  String get employeeEditDetailsTitle;

  /// No description provided for @employeeEditSaved.
  ///
  /// In en, this message translates to:
  /// **'Employee details updated'**
  String get employeeEditSaved;

  /// No description provided for @employeeEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get employeeEdit;

  /// No description provided for @employeeDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete employee'**
  String get employeeDelete;

  /// No description provided for @employeeDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this employee?'**
  String get employeeDeleteConfirmTitle;

  /// No description provided for @employeeDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed permanently, along with their account and every assignment they hold. This cannot be undone.'**
  String employeeDeleteConfirmBody(String name);

  /// No description provided for @employeeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Employee deleted'**
  String get employeeDeleted;

  /// No description provided for @employeeDeleteAdminBlocked.
  ///
  /// In en, this message translates to:
  /// **'An administrator cannot be deleted. Remove their admin role first.'**
  String get employeeDeleteAdminBlocked;

  /// No description provided for @employeePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get employeePassword;

  /// No description provided for @employeePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'New password for {name}'**
  String employeePasswordTitle(String name);

  /// No description provided for @employeePasswordHint.
  ///
  /// In en, this message translates to:
  /// **'The employee signs in with the new password from now on. Tell them yourself — no message is sent.'**
  String get employeePasswordHint;

  /// No description provided for @employeePasswordNew.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get employeePasswordNew;

  /// No description provided for @employeePasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get employeePasswordConfirm;

  /// No description provided for @employeePasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get employeePasswordChanged;

  /// No description provided for @employeePasswordAdminBlocked.
  ///
  /// In en, this message translates to:
  /// **'Only an administrator can change another administrator\'s password.'**
  String get employeePasswordAdminBlocked;

  /// No description provided for @employeeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get employeeEmail;

  /// No description provided for @employeeEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'New email for {name}'**
  String employeeEmailTitle(String name);

  /// No description provided for @employeeEmailHint.
  ///
  /// In en, this message translates to:
  /// **'The employee signs in with the new email from now on. Tell them yourself — no message is sent to either address.'**
  String get employeeEmailHint;

  /// No description provided for @employeeEmailNew.
  ///
  /// In en, this message translates to:
  /// **'New email'**
  String get employeeEmailNew;

  /// No description provided for @employeeEmailChanged.
  ///
  /// In en, this message translates to:
  /// **'Email changed'**
  String get employeeEmailChanged;

  /// No description provided for @employeeEmailAdminBlocked.
  ///
  /// In en, this message translates to:
  /// **'Only an administrator can change another administrator\'s email.'**
  String get employeeEmailAdminBlocked;

  /// No description provided for @employeeEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'This email is already used by another account.'**
  String get employeeEmailTaken;

  /// No description provided for @myProfileChangeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get myProfileChangeEmail;

  /// No description provided for @myProfileNewEmail.
  ///
  /// In en, this message translates to:
  /// **'New email'**
  String get myProfileNewEmail;

  /// No description provided for @myProfileEmailChanged.
  ///
  /// In en, this message translates to:
  /// **'Email changed. You sign in with the new address from now on.'**
  String get myProfileEmailChanged;

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

  /// No description provided for @employeeModulesSection.
  ///
  /// In en, this message translates to:
  /// **'Assigned modules'**
  String get employeeModulesSection;

  /// No description provided for @employeeModulesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Not assigned to any operational module'**
  String get employeeModulesEmpty;

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

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @perm_modules.
  ///
  /// In en, this message translates to:
  /// **'Operational files'**
  String get perm_modules;

  /// No description provided for @permModulesViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all files, including drafts'**
  String get permModulesViewAll;

  /// No description provided for @permModulesCreate.
  ///
  /// In en, this message translates to:
  /// **'Create an operational file'**
  String get permModulesCreate;

  /// No description provided for @permModulesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit a file & its structure'**
  String get permModulesEdit;

  /// No description provided for @permModulesDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete an operational file'**
  String get permModulesDelete;

  /// No description provided for @permModulesActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate & deactivate files'**
  String get permModulesActivate;

  /// No description provided for @permModulesMembers.
  ///
  /// In en, this message translates to:
  /// **'Assign members & duties'**
  String get permModulesMembers;

  /// No description provided for @permModulesReports.
  ///
  /// In en, this message translates to:
  /// **'Read members\' file reports'**
  String get permModulesReports;

  /// No description provided for @navModules.
  ///
  /// In en, this message translates to:
  /// **'Operational modules'**
  String get navModules;

  /// No description provided for @navModulesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The files you were assigned to, and your roles in them'**
  String get navModulesSubtitle;

  /// No description provided for @navReferenceData.
  ///
  /// In en, this message translates to:
  /// **'Master data'**
  String get navReferenceData;

  /// No description provided for @navReferenceDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hotels, clusters and other lists'**
  String get navReferenceDataSubtitle;

  /// No description provided for @modulesManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage operational files'**
  String get modulesManageTitle;

  /// No description provided for @modulesEmptyMine.
  ///
  /// In en, this message translates to:
  /// **'No files were assigned to you this season'**
  String get modulesEmptyMine;

  /// No description provided for @navModulesManage.
  ///
  /// In en, this message translates to:
  /// **'Manage operational files'**
  String get navModulesManage;

  /// No description provided for @navModulesManageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every file of the season, and opening a new one'**
  String get navModulesManageSubtitle;

  /// No description provided for @modulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Operational files'**
  String get modulesTitle;

  /// No description provided for @modulesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No files have been assigned to you yet'**
  String get modulesEmpty;

  /// No description provided for @modulesEmptyManager.
  ///
  /// In en, this message translates to:
  /// **'No files created yet'**
  String get modulesEmptyManager;

  /// No description provided for @moduleActiveSection.
  ///
  /// In en, this message translates to:
  /// **'Active files'**
  String get moduleActiveSection;

  /// No description provided for @moduleDraftSection.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get moduleDraftSection;

  /// No description provided for @moduleBadgeDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get moduleBadgeDraft;

  /// No description provided for @moduleNew.
  ///
  /// In en, this message translates to:
  /// **'New file'**
  String get moduleNew;

  /// No description provided for @moduleChooseType.
  ///
  /// In en, this message translates to:
  /// **'Choose a file type'**
  String get moduleChooseType;

  /// No description provided for @moduleNoTypes.
  ///
  /// In en, this message translates to:
  /// **'No file types have been defined yet'**
  String get moduleNoTypes;

  /// No description provided for @moduleAllTypesUsed.
  ///
  /// In en, this message translates to:
  /// **'Every file type has already been opened for this season'**
  String get moduleAllTypesUsed;

  /// No description provided for @moduleOnePerSeason.
  ///
  /// In en, this message translates to:
  /// **'A file of a kind is created once per season, and its type is its name'**
  String get moduleOnePerSeason;

  /// No description provided for @moduleSeasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get moduleSeasonLabel;

  /// No description provided for @moduleDecisionBadge.
  ///
  /// In en, this message translates to:
  /// **'Decision {number}'**
  String moduleDecisionBadge(String number);

  /// No description provided for @moduleDecisionNumber.
  ///
  /// In en, this message translates to:
  /// **'Decision / file number'**
  String get moduleDecisionNumber;

  /// No description provided for @moduleDecisionNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Optional — added when the decision is issued'**
  String get moduleDecisionNumberHint;

  /// No description provided for @moduleEndDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get moduleEndDate;

  /// No description provided for @moduleEndDateHint.
  ///
  /// In en, this message translates to:
  /// **'Optional — the file ends at the close of this day'**
  String get moduleEndDateHint;

  /// No description provided for @moduleEndDateClear.
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get moduleEndDateClear;

  /// No description provided for @moduleEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'The end date is before the start date'**
  String get moduleEndBeforeStart;

  /// No description provided for @moduleStartDate.
  ///
  /// In en, this message translates to:
  /// **'Work starts on'**
  String get moduleStartDate;

  /// No description provided for @moduleReportCadence.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get moduleReportCadence;

  /// No description provided for @moduleReportCadenceHint.
  ///
  /// In en, this message translates to:
  /// **'How often the people in this file file one'**
  String get moduleReportCadenceHint;

  /// No description provided for @cadenceNone.
  ///
  /// In en, this message translates to:
  /// **'No reports'**
  String get cadenceNone;

  /// No description provided for @cadenceDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get cadenceDaily;

  /// No description provided for @cadenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get cadenceWeekly;

  /// No description provided for @cadenceOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get cadenceOnce;

  /// No description provided for @moduleRatingSection.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get moduleRatingSection;

  /// No description provided for @moduleRatingMine.
  ///
  /// In en, this message translates to:
  /// **'My rating in this file'**
  String get moduleRatingMine;

  /// No description provided for @moduleRatingNone.
  ///
  /// In en, this message translates to:
  /// **'Nobody has rated you in this file yet'**
  String get moduleRatingNone;

  /// No description provided for @moduleRatingValue.
  ///
  /// In en, this message translates to:
  /// **'{average} of 5 · {count, plural, =1{1 rating} other{{count} ratings}}'**
  String moduleRatingValue(String average, int count);

  /// No description provided for @moduleRatingRate.
  ///
  /// In en, this message translates to:
  /// **'Rate your colleagues in this file'**
  String get moduleRatingRate;

  /// No description provided for @moduleRatingAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Ratings are anonymous — a colleague sees his average and how many rated him, never who gave what'**
  String get moduleRatingAnonymous;

  /// No description provided for @moduleRatingSaved.
  ///
  /// In en, this message translates to:
  /// **'Rating saved'**
  String get moduleRatingSaved;

  /// No description provided for @moduleRatingCleared.
  ///
  /// In en, this message translates to:
  /// **'Rating withdrawn'**
  String get moduleRatingCleared;

  /// No description provided for @moduleReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get moduleReports;

  /// No description provided for @moduleReportWrite.
  ///
  /// In en, this message translates to:
  /// **'File a report'**
  String get moduleReportWrite;

  /// No description provided for @moduleReportEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit my report'**
  String get moduleReportEdit;

  /// No description provided for @moduleReportNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get moduleReportNotes;

  /// No description provided for @moduleReportNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional — anything to add about what you attached'**
  String get moduleReportNotesHint;

  /// No description provided for @moduleReportAttachHint.
  ///
  /// In en, this message translates to:
  /// **'The report is what you upload: photos, files or a voice note'**
  String get moduleReportAttachHint;

  /// No description provided for @moduleReportNothingAttached.
  ///
  /// In en, this message translates to:
  /// **'Nothing attached'**
  String get moduleReportNothingAttached;

  /// No description provided for @moduleReportSaved.
  ///
  /// In en, this message translates to:
  /// **'Report filed'**
  String get moduleReportSaved;

  /// No description provided for @moduleReportsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reports filed yet'**
  String get moduleReportsEmpty;

  /// No description provided for @moduleReportPeriodDay.
  ///
  /// In en, this message translates to:
  /// **'Report for {date}'**
  String moduleReportPeriodDay(String date);

  /// No description provided for @moduleReportPeriodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week of {date}'**
  String moduleReportPeriodWeek(String date);

  /// No description provided for @moduleStartCondition.
  ///
  /// In en, this message translates to:
  /// **'Work begins'**
  String get moduleStartCondition;

  /// No description provided for @moduleEndCondition.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get moduleEndCondition;

  /// No description provided for @moduleStepInfo.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get moduleStepInfo;

  /// No description provided for @moduleStepSectors.
  ///
  /// In en, this message translates to:
  /// **'Sectors'**
  String get moduleStepSectors;

  /// No description provided for @moduleStepTowers.
  ///
  /// In en, this message translates to:
  /// **'Towers'**
  String get moduleStepTowers;

  /// No description provided for @moduleStepMembers.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get moduleStepMembers;

  /// No description provided for @moduleNodeName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get moduleNodeName;

  /// No description provided for @moduleNodeAdd.
  ///
  /// In en, this message translates to:
  /// **'Add {level}'**
  String moduleNodeAdd(String level);

  /// No description provided for @moduleNodeEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit {level}'**
  String moduleNodeEdit(String level);

  /// No description provided for @moduleNodeDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete {level}'**
  String moduleNodeDelete(String level);

  /// No description provided for @moduleNodeDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”? Everything inside it goes with it.'**
  String moduleNodeDeleteConfirm(String name);

  /// No description provided for @moduleNodeSuggestedName.
  ///
  /// In en, this message translates to:
  /// **'{level} {number}'**
  String moduleNodeSuggestedName(String level, int number);

  /// No description provided for @moduleSectorsImport.
  ///
  /// In en, this message translates to:
  /// **'Import sectors'**
  String get moduleSectorsImport;

  /// No description provided for @moduleSectorsImportPick.
  ///
  /// In en, this message translates to:
  /// **'Copy the sectors from another file in this season — the name, the supervisor and his deputy. The copies are independent: deleting a sector here does not touch the other file.'**
  String get moduleSectorsImportPick;

  /// No description provided for @moduleSectorsImported.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No new sectors} =1{Imported 1 sector} other{Imported {count} sectors}}'**
  String moduleSectorsImported(int count);

  /// No description provided for @moduleSectorsImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not import the sectors'**
  String get moduleSectorsImportFailed;

  /// No description provided for @moduleSectorsImportNoSources.
  ///
  /// In en, this message translates to:
  /// **'No other file in this season has sectors'**
  String get moduleSectorsImportNoSources;

  /// No description provided for @moduleNoNodes.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been added yet'**
  String get moduleNoNodes;

  /// No description provided for @moduleSectorsFirst.
  ///
  /// In en, this message translates to:
  /// **'Add the sectors first, then place the hotels in them'**
  String get moduleSectorsFirst;

  /// No description provided for @moduleBuildTree.
  ///
  /// In en, this message translates to:
  /// **'Add sectors & towers'**
  String get moduleBuildTree;

  /// No description provided for @moduleNoLevels.
  ///
  /// In en, this message translates to:
  /// **'This file type has no structure defined yet'**
  String get moduleNoLevels;

  /// No description provided for @moduleSectionInfo.
  ///
  /// In en, this message translates to:
  /// **'File information'**
  String get moduleSectionInfo;

  /// No description provided for @moduleSectionTasks.
  ///
  /// In en, this message translates to:
  /// **'My role & duties'**
  String get moduleSectionTasks;

  /// No description provided for @moduleSectionTasksOf.
  ///
  /// In en, this message translates to:
  /// **'{name} — role & duties'**
  String moduleSectionTasksOf(String name);

  /// No description provided for @moduleJobDescription.
  ///
  /// In en, this message translates to:
  /// **'Job description'**
  String get moduleJobDescription;

  /// No description provided for @moduleNoTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks are defined for this role yet'**
  String get moduleNoTasks;

  /// No description provided for @moduleAssignedTasks.
  ///
  /// In en, this message translates to:
  /// **'Assigned duties'**
  String get moduleAssignedTasks;

  /// No description provided for @moduleAssignedTasksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} duties'**
  String moduleAssignedTasksCount(int count, int total);

  /// No description provided for @moduleNoAssignedTasks.
  ///
  /// In en, this message translates to:
  /// **'No duties assigned yet'**
  String get moduleNoAssignedTasks;

  /// No description provided for @moduleNoAssignedTasksMine.
  ///
  /// In en, this message translates to:
  /// **'You have not been handed any duty from this role\'s list yet'**
  String get moduleNoAssignedTasksMine;

  /// No description provided for @moduleTeamPick.
  ///
  /// In en, this message translates to:
  /// **'Choose members'**
  String get moduleTeamPick;

  /// No description provided for @moduleNoTeamMembers.
  ///
  /// In en, this message translates to:
  /// **'No one has been put on this team yet'**
  String get moduleNoTeamMembers;

  /// No description provided for @moduleNoRoles.
  ///
  /// In en, this message translates to:
  /// **'This file type has no roles defined yet'**
  String get moduleNoRoles;

  /// No description provided for @moduleMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String moduleMembersCount(int count);

  /// No description provided for @moduleNoMembers.
  ///
  /// In en, this message translates to:
  /// **'No one has been assigned here yet'**
  String get moduleNoMembers;

  /// No description provided for @moduleRoleUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get moduleRoleUnassigned;

  /// No description provided for @moduleSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get moduleSaved;

  /// No description provided for @moduleActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate file'**
  String get moduleActivate;

  /// No description provided for @moduleDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate file'**
  String get moduleDeactivate;

  /// No description provided for @moduleActivated.
  ///
  /// In en, this message translates to:
  /// **'File activated — members have been notified'**
  String get moduleActivated;

  /// No description provided for @moduleDeactivated.
  ///
  /// In en, this message translates to:
  /// **'File deactivated'**
  String get moduleDeactivated;

  /// No description provided for @moduleAttachPdf.
  ///
  /// In en, this message translates to:
  /// **'Attach PDF'**
  String get moduleAttachPdf;

  /// No description provided for @moduleReplacePdf.
  ///
  /// In en, this message translates to:
  /// **'Replace file'**
  String get moduleReplacePdf;

  /// No description provided for @moduleOpenPdf.
  ///
  /// In en, this message translates to:
  /// **'Open PDF'**
  String get moduleOpenPdf;

  /// No description provided for @moduleNoPdf.
  ///
  /// In en, this message translates to:
  /// **'No file attached'**
  String get moduleNoPdf;

  /// No description provided for @modulePdfOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the file'**
  String get modulePdfOpenFailed;

  /// No description provided for @moduleDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete file'**
  String get moduleDelete;

  /// No description provided for @moduleDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this file? Everything in it — its members, the duties they were handed, and its attachments — goes with it.'**
  String get moduleDeleteConfirm;

  /// No description provided for @moduleDeleted.
  ///
  /// In en, this message translates to:
  /// **'File deleted'**
  String get moduleDeleted;

  /// No description provided for @moduleNoCurrentSeason.
  ///
  /// In en, this message translates to:
  /// **'Set a current season before creating files'**
  String get moduleNoCurrentSeason;

  /// No description provided for @moduleNoParticipants.
  ///
  /// In en, this message translates to:
  /// **'The current season has no participants yet'**
  String get moduleNoParticipants;

  /// No description provided for @moduleContactSy.
  ///
  /// In en, this message translates to:
  /// **'Syrian number'**
  String get moduleContactSy;

  /// No description provided for @moduleContactSa.
  ///
  /// In en, this message translates to:
  /// **'Saudi number'**
  String get moduleContactSa;

  /// No description provided for @modulePickerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or job title'**
  String get modulePickerSearchHint;

  /// No description provided for @modulePickerAll.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get modulePickerAll;

  /// No description provided for @modulePickerInternal.
  ///
  /// In en, this message translates to:
  /// **'Mission staff'**
  String get modulePickerInternal;

  /// No description provided for @modulePickerExternal.
  ///
  /// In en, this message translates to:
  /// **'External'**
  String get modulePickerExternal;

  /// No description provided for @modulePickerNoMatches.
  ///
  /// In en, this message translates to:
  /// **'Nobody matches that search'**
  String get modulePickerNoMatches;

  /// No description provided for @modulePickerFree.
  ///
  /// In en, this message translates to:
  /// **'Not in any file'**
  String get modulePickerFree;

  /// No description provided for @modulePickerAlreadyIn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Already in 1 file} other{Already in {count} files}}'**
  String modulePickerAlreadyIn(int count);

  /// No description provided for @modulePickerConfirm.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Confirm with nobody chosen} =1{Confirm 1 person} other{Confirm {count} people}}'**
  String modulePickerConfirm(int count);

  /// No description provided for @referenceDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Master data'**
  String get referenceDataTitle;

  /// No description provided for @referenceItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String referenceItemsCount(int count);

  /// No description provided for @referenceImport.
  ///
  /// In en, this message translates to:
  /// **'Import from another season'**
  String get referenceImport;

  /// No description provided for @referenceImportPick.
  ///
  /// In en, this message translates to:
  /// **'Copy the list from an earlier season. The copies are independent — deleting one here does not touch the other season.'**
  String get referenceImportPick;

  /// No description provided for @referenceImported.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} entries'**
  String referenceImported(int count);

  /// No description provided for @referenceImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get referenceImportFailed;

  /// No description provided for @referenceImportNoSeasons.
  ///
  /// In en, this message translates to:
  /// **'No other seasons'**
  String get referenceImportNoSeasons;

  /// No description provided for @referenceAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get referenceAddItem;

  /// No description provided for @referenceItemName.
  ///
  /// In en, this message translates to:
  /// **'Name (Arabic)'**
  String get referenceItemName;

  /// No description provided for @referenceItemNameEn.
  ///
  /// In en, this message translates to:
  /// **'Name (English)'**
  String get referenceItemNameEn;

  /// No description provided for @referenceItemSaved.
  ///
  /// In en, this message translates to:
  /// **'Entry saved'**
  String get referenceItemSaved;

  /// No description provided for @referenceItemDeleted.
  ///
  /// In en, this message translates to:
  /// **'Entry deleted'**
  String get referenceItemDeleted;

  /// No description provided for @referenceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get referenceEmpty;

  /// No description provided for @referenceDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String referenceDeleteConfirm(String name);

  /// No description provided for @referenceInUse.
  ///
  /// In en, this message translates to:
  /// **'This entry is used by a module and cannot be deleted'**
  String get referenceInUse;

  /// No description provided for @referenceDuplicate.
  ///
  /// In en, this message translates to:
  /// **'An entry with this name already exists in the list'**
  String get referenceDuplicate;

  /// No description provided for @referenceOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get referenceOpenLink;

  /// No description provided for @locationPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Set location'**
  String get locationPickerTitle;

  /// No description provided for @locationPickOnMap.
  ///
  /// In en, this message translates to:
  /// **'On the map'**
  String get locationPickOnMap;

  /// No description provided for @locationUseCurrent.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get locationUseCurrent;

  /// No description provided for @locationOrPasteLink.
  ///
  /// In en, this message translates to:
  /// **'Or paste a map link'**
  String get locationOrPasteLink;

  /// No description provided for @locationTapToPlace.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to place the pin'**
  String get locationTapToPlace;

  /// No description provided for @locationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm this location'**
  String get locationConfirm;

  /// No description provided for @locationCaptured.
  ///
  /// In en, this message translates to:
  /// **'Current location captured'**
  String get locationCaptured;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location access was not granted'**
  String get locationPermissionDenied;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are turned off'**
  String get locationServiceDisabled;

  /// No description provided for @locationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not determine your location'**
  String get locationFailed;

  /// No description provided for @locationOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open on map'**
  String get locationOpenMap;

  /// No description provided for @referenceCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get referenceCall;

  /// No description provided for @referenceLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link'**
  String get referenceLinkFailed;

  /// No description provided for @referenceDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get referenceDetailsTitle;

  /// No description provided for @profileSectionPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get profileSectionPermissions;

  /// No description provided for @profilePermissionsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator — every permission'**
  String get profilePermissionsAdmin;

  /// No description provided for @profilePermissionsNone.
  ///
  /// In en, this message translates to:
  /// **'No administrative permissions'**
  String get profilePermissionsNone;

  /// No description provided for @profilePermissionsNoneHint.
  ///
  /// In en, this message translates to:
  /// **'Which is the ordinary case: an operational file reaches you by assignment, not by permission.'**
  String get profilePermissionsNoneHint;

  /// No description provided for @profilePermissionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{one permission} other{{count} permissions}}'**
  String profilePermissionsCount(int count);

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The season from above'**
  String get navDashboardSubtitle;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardSeason.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get dashboardSeason;

  /// No description provided for @dashboardNoSeason.
  ///
  /// In en, this message translates to:
  /// **'No season yet'**
  String get dashboardNoSeason;

  /// No description provided for @dashboardNothingToShow.
  ///
  /// In en, this message translates to:
  /// **'You hold no permission that shows figures here'**
  String get dashboardNothingToShow;

  /// No description provided for @dashboardSectionPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get dashboardSectionPeople;

  /// No description provided for @dashboardSectionModules.
  ///
  /// In en, this message translates to:
  /// **'Operational files'**
  String get dashboardSectionModules;

  /// No description provided for @dashboardSectionWork.
  ///
  /// In en, this message translates to:
  /// **'The work'**
  String get dashboardSectionWork;

  /// No description provided for @dashboardSectionQueue.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get dashboardSectionQueue;

  /// No description provided for @dashboardSectionCentralReports.
  ///
  /// In en, this message translates to:
  /// **'Central reports'**
  String get dashboardSectionCentralReports;

  /// No description provided for @dashboardCentralPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get dashboardCentralPublished;

  /// No description provided for @dashboardCentralDrafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get dashboardCentralDrafts;

  /// No description provided for @dashboardCentralGeneral.
  ///
  /// In en, this message translates to:
  /// **'General (all seasons)'**
  String get dashboardCentralGeneral;

  /// No description provided for @dashboardCentralByType.
  ///
  /// In en, this message translates to:
  /// **'By type'**
  String get dashboardCentralByType;

  /// No description provided for @dashboardCentralSplit.
  ///
  /// In en, this message translates to:
  /// **'Published vs drafts'**
  String get dashboardCentralSplit;

  /// No description provided for @dashboardSectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get dashboardSectionNotifications;

  /// No description provided for @dashboardNotifMessages30.
  ///
  /// In en, this message translates to:
  /// **'Messages (30 days)'**
  String get dashboardNotifMessages30;

  /// No description provided for @dashboardNotifRecipients.
  ///
  /// In en, this message translates to:
  /// **'Recipients'**
  String get dashboardNotifRecipients;

  /// No description provided for @dashboardNotifReadShare.
  ///
  /// In en, this message translates to:
  /// **'Read rate'**
  String get dashboardNotifReadShare;

  /// No description provided for @dashboardNotifTrend.
  ///
  /// In en, this message translates to:
  /// **'Messages, last 30 days'**
  String get dashboardNotifTrend;

  /// No description provided for @dashboardNotifTrendEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages in the last 30 days'**
  String get dashboardNotifTrendEmpty;

  /// No description provided for @dashboardNotifAllTime.
  ///
  /// In en, this message translates to:
  /// **'{n} messages all-time'**
  String dashboardNotifAllTime(Object n);

  /// No description provided for @dashboardSectionReference.
  ///
  /// In en, this message translates to:
  /// **'Master data'**
  String get dashboardSectionReference;

  /// No description provided for @dashboardRefSets.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get dashboardRefSets;

  /// No description provided for @dashboardRefItems.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get dashboardRefItems;

  /// No description provided for @dashboardRefActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get dashboardRefActive;

  /// No description provided for @dashboardRefSeasonSplit.
  ///
  /// In en, this message translates to:
  /// **'Seasonal vs general'**
  String get dashboardRefSeasonSplit;

  /// No description provided for @dashboardRefSeasonItems.
  ///
  /// In en, this message translates to:
  /// **'This season'**
  String get dashboardRefSeasonItems;

  /// No description provided for @dashboardRefGeneralItems.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get dashboardRefGeneralItems;

  /// No description provided for @dashboardRefBySet.
  ///
  /// In en, this message translates to:
  /// **'Entries per list'**
  String get dashboardRefBySet;

  /// No description provided for @dashboardSectionPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get dashboardSectionPermissions;

  /// No description provided for @dashboardPermAdmins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get dashboardPermAdmins;

  /// No description provided for @dashboardPermGrantees.
  ///
  /// In en, this message translates to:
  /// **'Employees with grants'**
  String get dashboardPermGrantees;

  /// No description provided for @dashboardPermGrants.
  ///
  /// In en, this message translates to:
  /// **'Grants held'**
  String get dashboardPermGrants;

  /// No description provided for @dashboardPermBySection.
  ///
  /// In en, this message translates to:
  /// **'Grants by section'**
  String get dashboardPermBySection;

  /// No description provided for @dashboardParticipants.
  ///
  /// In en, this message translates to:
  /// **'On this season'**
  String get dashboardParticipants;

  /// No description provided for @dashboardWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get dashboardWithdrawn;

  /// No description provided for @dashboardWithdrawnCaption.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{nobody withdrew} =1{and one withdrew} other{and {count} withdrew}}'**
  String dashboardWithdrawnCaption(int count);

  /// No description provided for @dashboardInternal.
  ///
  /// In en, this message translates to:
  /// **'Of the mission'**
  String get dashboardInternal;

  /// No description provided for @dashboardExternal.
  ///
  /// In en, this message translates to:
  /// **'From outside'**
  String get dashboardExternal;

  /// No description provided for @dashboardUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not stated'**
  String get dashboardUnknown;

  /// No description provided for @dashboardByMission.
  ///
  /// In en, this message translates to:
  /// **'By mission type'**
  String get dashboardByMission;

  /// No description provided for @dashboardByGender.
  ///
  /// In en, this message translates to:
  /// **'By gender'**
  String get dashboardByGender;

  /// No description provided for @dashboardByJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Largest trades'**
  String get dashboardByJobTitle;

  /// No description provided for @dashboardFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get dashboardFiles;

  /// No description provided for @dashboardFilesCaption.
  ///
  /// In en, this message translates to:
  /// **'{active} active, {draft} draft'**
  String dashboardFilesCaption(int active, int draft);

  /// No description provided for @dashboardRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get dashboardRunning;

  /// No description provided for @dashboardEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get dashboardEnded;

  /// No description provided for @dashboardNodes.
  ///
  /// In en, this message translates to:
  /// **'Sectors and towers'**
  String get dashboardNodes;

  /// No description provided for @dashboardMembers.
  ///
  /// In en, this message translates to:
  /// **'Hold a posting'**
  String get dashboardMembers;

  /// No description provided for @dashboardUnstaffed.
  ///
  /// In en, this message translates to:
  /// **'Files with nobody in them'**
  String get dashboardUnstaffed;

  /// No description provided for @dashboardUnstaffedCaption.
  ///
  /// In en, this message translates to:
  /// **'Nobody assigned yet'**
  String get dashboardUnstaffedCaption;

  /// No description provided for @dashboardByType.
  ///
  /// In en, this message translates to:
  /// **'By file type'**
  String get dashboardByType;

  /// No description provided for @dashboardActiveDraft.
  ///
  /// In en, this message translates to:
  /// **'Active against draft'**
  String get dashboardActiveDraft;

  /// No description provided for @dashboardReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get dashboardReports;

  /// No description provided for @dashboardReportsCaption.
  ///
  /// In en, this message translates to:
  /// **'{authors, plural, =0{from nobody} =1{from one author} other{from {authors} authors}}'**
  String dashboardReportsCaption(int authors);

  /// No description provided for @dashboardReportsTrend.
  ///
  /// In en, this message translates to:
  /// **'Reports over 30 days'**
  String get dashboardReportsTrend;

  /// No description provided for @dashboardReportsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reports filed in this stretch'**
  String get dashboardReportsEmpty;

  /// No description provided for @dashboardRatings.
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get dashboardRatings;

  /// No description provided for @dashboardAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get dashboardAverage;

  /// No description provided for @dashboardRatedPeople.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{nobody rated} =1{about one person} other{about {count} people}}'**
  String dashboardRatedPeople(int count);

  /// No description provided for @dashboardRatingDistribution.
  ///
  /// In en, this message translates to:
  /// **'Star distribution'**
  String get dashboardRatingDistribution;

  /// No description provided for @dashboardPending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval'**
  String get dashboardPending;

  /// No description provided for @dashboardApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get dashboardApproved;

  /// No description provided for @dashboardRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get dashboardRejected;

  /// No description provided for @dashboardIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Profile incomplete'**
  String get dashboardIncomplete;
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
