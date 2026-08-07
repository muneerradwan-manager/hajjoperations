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

  /// No description provided for @homeHijriDate.
  ///
  /// In en, this message translates to:
  /// **'{date} AH'**
  String homeHijriDate(String date);

  /// No description provided for @homeGregorianDate.
  ///
  /// In en, this message translates to:
  /// **'{date} CE'**
  String homeGregorianDate(String date);

  /// No description provided for @profileTitleBadgeSuffix.
  ///
  /// In en, this message translates to:
  /// **'({badge})'**
  String profileTitleBadgeSuffix(String badge);

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

  /// No description provided for @homeAdminGroupFiles.
  ///
  /// In en, this message translates to:
  /// **'Files, decisions & circulars'**
  String get homeAdminGroupFiles;

  /// No description provided for @homeAdminGroupPeople.
  ///
  /// In en, this message translates to:
  /// **'People & permissions'**
  String get homeAdminGroupPeople;

  /// No description provided for @homeAdminGroupSeason.
  ///
  /// In en, this message translates to:
  /// **'Season & reference data'**
  String get homeAdminGroupSeason;

  /// No description provided for @homeAdminGroupOversight.
  ///
  /// In en, this message translates to:
  /// **'Oversight & records'**
  String get homeAdminGroupOversight;

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

  /// No description provided for @contactWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Message on WhatsApp'**
  String get contactWhatsApp;

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
  /// **'Decisions and circulars'**
  String get perm_reports;

  /// No description provided for @permReportsViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all decisions, including drafts'**
  String get permReportsViewAll;

  /// No description provided for @permReportsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create decisions'**
  String get permReportsCreate;

  /// No description provided for @permReportsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit decisions'**
  String get permReportsEdit;

  /// No description provided for @permReportsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete decisions'**
  String get permReportsDelete;

  /// No description provided for @permReportsPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish & unpublish decisions'**
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

  /// No description provided for @perm_audit.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get perm_audit;

  /// No description provided for @permAuditView.
  ///
  /// In en, this message translates to:
  /// **'Read the record of who did what'**
  String get permAuditView;

  /// No description provided for @perm_complaints.
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get perm_complaints;

  /// No description provided for @permComplaintsView.
  ///
  /// In en, this message translates to:
  /// **'View every complaint filed'**
  String get permComplaintsView;

  /// No description provided for @permComplaintsReply.
  ///
  /// In en, this message translates to:
  /// **'Take part in any complaint thread'**
  String get permComplaintsReply;

  /// No description provided for @permComplaintsLock.
  ///
  /// In en, this message translates to:
  /// **'Close a complaint to further replies'**
  String get permComplaintsLock;

  /// No description provided for @permComplaintsDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss a complaint as unfounded'**
  String get permComplaintsDismiss;

  /// No description provided for @permComplaintsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete a complaint'**
  String get permComplaintsDelete;

  /// No description provided for @perm_evaluations.
  ///
  /// In en, this message translates to:
  /// **'Evaluations'**
  String get perm_evaluations;

  /// No description provided for @permEvaluationsView.
  ///
  /// In en, this message translates to:
  /// **'View every evaluation and its marks'**
  String get permEvaluationsView;

  /// No description provided for @permEvaluationsTemplates.
  ///
  /// In en, this message translates to:
  /// **'Build and edit the evaluation forms'**
  String get permEvaluationsTemplates;

  /// No description provided for @permEvaluationsAssign.
  ///
  /// In en, this message translates to:
  /// **'Open an evaluation and name its evaluator'**
  String get permEvaluationsAssign;

  /// No description provided for @permEvaluationsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete an evaluation'**
  String get permEvaluationsDelete;

  /// No description provided for @perm_incidents.
  ///
  /// In en, this message translates to:
  /// **'Urgent reports'**
  String get perm_incidents;

  /// No description provided for @permIncidentsReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive and read every urgent report'**
  String get permIncidentsReceive;

  /// No description provided for @permIncidentsHandle.
  ///
  /// In en, this message translates to:
  /// **'Take on an urgent report and close it'**
  String get permIncidentsHandle;

  /// No description provided for @perm_checkin.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get perm_checkin;

  /// No description provided for @permCheckinBoard.
  ///
  /// In en, this message translates to:
  /// **'Read everyone\'s attendance record'**
  String get permCheckinBoard;

  /// No description provided for @permCheckinCodes.
  ///
  /// In en, this message translates to:
  /// **'View, print and share place codes'**
  String get permCheckinCodes;

  /// No description provided for @permCheckinRotate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate a place code, voiding every printed copy'**
  String get permCheckinRotate;

  /// No description provided for @perm_export.
  ///
  /// In en, this message translates to:
  /// **'Data export'**
  String get perm_export;

  /// No description provided for @permExportData.
  ///
  /// In en, this message translates to:
  /// **'Export any dataset, including data you cannot open on screen'**
  String get permExportData;

  /// No description provided for @perm_map.
  ///
  /// In en, this message translates to:
  /// **'Season map'**
  String get perm_map;

  /// No description provided for @permMapView.
  ///
  /// In en, this message translates to:
  /// **'Open the season map'**
  String get permMapView;

  /// No description provided for @perm_tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get perm_tasks;

  /// No description provided for @permTasksAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign tasks to other people'**
  String get permTasksAssign;

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

  /// No description provided for @attachmentTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That file is larger than the {limit} limit. Choose a smaller one.'**
  String attachmentTooLarge(String limit);

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

  /// No description provided for @reportCellEntryGone.
  ///
  /// In en, this message translates to:
  /// **'This choice no longer exists'**
  String get reportCellEntryGone;

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

  /// No description provided for @reportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Subtitle'**
  String get reportSubtitle;

  /// No description provided for @reportShape.
  ///
  /// In en, this message translates to:
  /// **'Document shape'**
  String get reportShape;

  /// No description provided for @reportKindDecision.
  ///
  /// In en, this message translates to:
  /// **'Decision'**
  String get reportKindDecision;

  /// No description provided for @reportKindCircular.
  ///
  /// In en, this message translates to:
  /// **'Circular'**
  String get reportKindCircular;

  /// No description provided for @reportNumber.
  ///
  /// In en, this message translates to:
  /// **'Decision number'**
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
  /// **'Build the decision from the pieces below — a heading, prose, a list, a table, a link, a code to scan. They appear in the order you add them.'**
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

  /// No description provided for @blockColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get blockColumnLabel;

  /// No description provided for @blockColumnKind.
  ///
  /// In en, this message translates to:
  /// **'Column type'**
  String get blockColumnKind;

  /// No description provided for @blockColumnKindText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get blockColumnKindText;

  /// No description provided for @blockColumnKindNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get blockColumnKindNumber;

  /// No description provided for @blockColumnKindDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get blockColumnKindDate;

  /// No description provided for @blockColumnKindTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get blockColumnKindTime;

  /// No description provided for @blockColumnKindTimeRange.
  ///
  /// In en, this message translates to:
  /// **'Time range'**
  String get blockColumnKindTimeRange;

  /// No description provided for @blockColumnKindReference.
  ///
  /// In en, this message translates to:
  /// **'From master data'**
  String get blockColumnKindReference;

  /// No description provided for @blockColumnKindTags.
  ///
  /// In en, this message translates to:
  /// **'List of items'**
  String get blockColumnKindTags;

  /// No description provided for @blockColumnSet.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get blockColumnSet;

  /// No description provided for @blockColumnSpan.
  ///
  /// In en, this message translates to:
  /// **'Merge repeats'**
  String get blockColumnSpan;

  /// No description provided for @blockColumnRetypeWarning.
  ///
  /// In en, this message translates to:
  /// **'{count} cells cannot be converted and will be emptied'**
  String blockColumnRetypeWarning(int count);

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
  /// **'New decision'**
  String get reportNew;

  /// No description provided for @reportEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit decision'**
  String get reportEdit;

  /// No description provided for @reportSaved.
  ///
  /// In en, this message translates to:
  /// **'Decision saved'**
  String get reportSaved;

  /// No description provided for @reportIdentity.
  ///
  /// In en, this message translates to:
  /// **'What this decision is'**
  String get reportIdentity;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get reportTitle;

  /// No description provided for @reportScopeHint.
  ///
  /// In en, this message translates to:
  /// **'General decisions stay true whichever season is running'**
  String get reportScopeHint;

  /// No description provided for @reportOncePerSeason.
  ///
  /// In en, this message translates to:
  /// **'This kind of decision is created only once per season, and it already exists — edit the existing one instead of creating another'**
  String get reportOncePerSeason;

  /// No description provided for @reportPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get reportPublished;

  /// No description provided for @reportPublishedHint.
  ///
  /// In en, this message translates to:
  /// **'An unpublished decision is visible only to whoever manages decisions'**
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
  /// **'No decisions yet'**
  String get reportsManageEmpty;

  /// No description provided for @reportDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {title}? This cannot be undone.'**
  String reportDeleteConfirm(String title);

  /// No description provided for @reportDeleted.
  ///
  /// In en, this message translates to:
  /// **'Decision deleted'**
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
  /// **'Decisions & circulars management'**
  String get navReportsManage;

  /// No description provided for @navReportsManageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter, correct and publish decisions'**
  String get navReportsManageSubtitle;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Decisions and circulars'**
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
  /// **'No decision matches'**
  String get reportsNoMatches;

  /// No description provided for @reportsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search decisions'**
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
  /// **'That decision is no longer available'**
  String get reportMissing;

  /// No description provided for @reportAboutSection.
  ///
  /// In en, this message translates to:
  /// **'About this decision'**
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

  /// No description provided for @permModulesTasks.
  ///
  /// In en, this message translates to:
  /// **'Write file duties and set any state'**
  String get permModulesTasks;

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
  /// **'My role'**
  String get moduleSectionTasks;

  /// No description provided for @moduleSectionTasksOf.
  ///
  /// In en, this message translates to:
  /// **'{name} — role'**
  String moduleSectionTasksOf(String name);

  /// No description provided for @moduleJobDescription.
  ///
  /// In en, this message translates to:
  /// **'Job description'**
  String get moduleJobDescription;

  /// No description provided for @moduleTasksSection.
  ///
  /// In en, this message translates to:
  /// **'Duties'**
  String get moduleTasksSection;

  /// No description provided for @moduleTasksFile.
  ///
  /// In en, this message translates to:
  /// **'File duties'**
  String get moduleTasksFile;

  /// No description provided for @moduleTasksFileHint.
  ///
  /// In en, this message translates to:
  /// **'The whole file\'s work — its members divide it among themselves'**
  String get moduleTasksFileHint;

  /// No description provided for @moduleTasksRole.
  ///
  /// In en, this message translates to:
  /// **'Role duties'**
  String get moduleTasksRole;

  /// No description provided for @moduleTasksRoleOf.
  ///
  /// In en, this message translates to:
  /// **'{name} duties'**
  String moduleTasksRoleOf(String name);

  /// No description provided for @moduleTasksRoleHint.
  ///
  /// In en, this message translates to:
  /// **'Attached to the post, not the person — replacing the holder leaves them standing'**
  String get moduleTasksRoleHint;

  /// No description provided for @moduleTasksNone.
  ///
  /// In en, this message translates to:
  /// **'This file has no duties written yet'**
  String get moduleTasksNone;

  /// No description provided for @taskStateNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get taskStateNotStarted;

  /// No description provided for @taskStateInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get taskStateInProgress;

  /// No description provided for @taskStateDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get taskStateDone;

  /// No description provided for @moduleTaskDue.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String moduleTaskDue(String date);

  /// No description provided for @moduleTaskAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a duty'**
  String get moduleTaskAdd;

  /// No description provided for @moduleTaskEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit duty'**
  String get moduleTaskEdit;

  /// No description provided for @moduleTaskDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete duty'**
  String get moduleTaskDelete;

  /// No description provided for @moduleTaskDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this duty from the file\'s list?'**
  String get moduleTaskDeleteConfirm;

  /// No description provided for @moduleTaskScope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get moduleTaskScope;

  /// No description provided for @moduleTaskScopeFile.
  ///
  /// In en, this message translates to:
  /// **'File duty'**
  String get moduleTaskScopeFile;

  /// No description provided for @moduleTaskScopeFileHint.
  ///
  /// In en, this message translates to:
  /// **'The whole file\'s — members share it among themselves'**
  String get moduleTaskScopeFileHint;

  /// No description provided for @moduleTaskScopeRole.
  ///
  /// In en, this message translates to:
  /// **'Role duty'**
  String get moduleTaskScopeRole;

  /// No description provided for @moduleTaskScopeRoleHint.
  ///
  /// In en, this message translates to:
  /// **'What holding the post means, whoever holds it'**
  String get moduleTaskScopeRoleHint;

  /// No description provided for @moduleTaskRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get moduleTaskRoleLabel;

  /// No description provided for @moduleTaskTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Duty'**
  String get moduleTaskTitleLabel;

  /// No description provided for @moduleTaskTitleEnLabel.
  ///
  /// In en, this message translates to:
  /// **'English title'**
  String get moduleTaskTitleEnLabel;

  /// No description provided for @moduleTaskDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get moduleTaskDescriptionLabel;

  /// No description provided for @moduleTaskNoDue.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get moduleTaskNoDue;

  /// No description provided for @moduleTaskPickRole.
  ///
  /// In en, this message translates to:
  /// **'Choose a role'**
  String get moduleTaskPickRole;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'My tasks'**
  String get navTasks;

  /// No description provided for @navTasksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your own list, and what was assigned to you'**
  String get navTasksSubtitle;

  /// No description provided for @tasksTitle.
  ///
  /// In en, this message translates to:
  /// **'My tasks'**
  String get tasksTitle;

  /// No description provided for @tasksOwnSection.
  ///
  /// In en, this message translates to:
  /// **'My own tasks'**
  String get tasksOwnSection;

  /// No description provided for @tasksOwnHint.
  ///
  /// In en, this message translates to:
  /// **'You wrote these for yourself — edit, delete and move them freely'**
  String get tasksOwnHint;

  /// No description provided for @tasksAssignedSection.
  ///
  /// In en, this message translates to:
  /// **'Assigned to me'**
  String get tasksAssignedSection;

  /// No description provided for @tasksAssignedHint.
  ///
  /// In en, this message translates to:
  /// **'Written for you — you change only how they are going'**
  String get tasksAssignedHint;

  /// No description provided for @tasksIAssignedSection.
  ///
  /// In en, this message translates to:
  /// **'Assigned by me'**
  String get tasksIAssignedSection;

  /// No description provided for @tasksIAssignedHint.
  ///
  /// In en, this message translates to:
  /// **'What you wrote onto other people\'s lists, followed up from here'**
  String get tasksIAssignedHint;

  /// No description provided for @tasksEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get tasksEmpty;

  /// No description provided for @tasksEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Write your first task with the button below'**
  String get tasksEmptyHint;

  /// No description provided for @tasksNew.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get tasksNew;

  /// No description provided for @tasksAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign a task'**
  String get tasksAssign;

  /// No description provided for @navTasksManage.
  ///
  /// In en, this message translates to:
  /// **'Task assignment'**
  String get navTasksManage;

  /// No description provided for @navTasksManageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Write tasks onto other people\'s lists, and follow them up'**
  String get navTasksManageSubtitle;

  /// No description provided for @tasksManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Task assignment'**
  String get tasksManageTitle;

  /// No description provided for @tasksManageEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have assigned nothing yet'**
  String get tasksManageEmpty;

  /// No description provided for @tasksManageEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Assign a task with the button below — its owner is told, and changes only how it is going'**
  String get tasksManageEmptyHint;

  /// No description provided for @taskPickPerson.
  ///
  /// In en, this message translates to:
  /// **'Choose an employee'**
  String get taskPickPerson;

  /// No description provided for @taskAssignedBy.
  ///
  /// In en, this message translates to:
  /// **'Assigned by {name}'**
  String taskAssignedBy(String name);

  /// No description provided for @taskAssignedTo.
  ///
  /// In en, this message translates to:
  /// **'For {name}'**
  String taskAssignedTo(String name);

  /// No description provided for @taskTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get taskTitleLabel;

  /// No description provided for @taskDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get taskDescriptionLabel;

  /// No description provided for @taskDue.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String taskDue(String date);

  /// No description provided for @taskNoDue.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get taskNoDue;

  /// No description provided for @taskState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get taskState;

  /// No description provided for @taskNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get taskNote;

  /// No description provided for @taskNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Anything worth saying about it?'**
  String get taskNoteHint;

  /// No description provided for @taskEvidence.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get taskEvidence;

  /// No description provided for @taskUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update state'**
  String get taskUpdate;

  /// No description provided for @taskStateSaved.
  ///
  /// In en, this message translates to:
  /// **'State updated'**
  String get taskStateSaved;

  /// No description provided for @taskReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Assigned to you — only its state is yours to change'**
  String get taskReadOnly;

  /// No description provided for @taskEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get taskEdit;

  /// No description provided for @taskDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get taskDelete;

  /// No description provided for @taskDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this task? Whatever was filed against it goes with it.'**
  String get taskDeleteConfirm;

  /// No description provided for @taskProgress.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total}'**
  String taskProgress(int done, int total);

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

  /// No description provided for @referenceShelfPlaces.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get referenceShelfPlaces;

  /// No description provided for @referenceShelfStructure.
  ///
  /// In en, this message translates to:
  /// **'File divisions'**
  String get referenceShelfStructure;

  /// No description provided for @referenceShelfMission.
  ///
  /// In en, this message translates to:
  /// **'The mission'**
  String get referenceShelfMission;

  /// No description provided for @referenceShelfReports.
  ///
  /// In en, this message translates to:
  /// **'Report inputs'**
  String get referenceShelfReports;

  /// No description provided for @referenceShelfOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get referenceShelfOther;

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

  /// No description provided for @referenceDivisionAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get referenceDivisionAll;

  /// No description provided for @referenceDivisionNone.
  ///
  /// In en, this message translates to:
  /// **'Unclassified'**
  String get referenceDivisionNone;

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

  /// No description provided for @referenceDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get referenceDeleteAll;

  /// No description provided for @referenceDeleteAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes {count} entries from “{name}”. It cannot be undone.'**
  String referenceDeleteAllConfirm(int count, String name);

  /// No description provided for @referenceDeleteAllDone.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} entries'**
  String referenceDeleteAllDone(int count);

  /// No description provided for @referenceDeleteAllPartial.
  ///
  /// In en, this message translates to:
  /// **'Deleted {deleted}; {kept} kept because they are used by modules or other lists'**
  String referenceDeleteAllPartial(int deleted, int kept);

  /// No description provided for @referenceDeleteAllNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing was deleted: every entry is used by a module or another list'**
  String get referenceDeleteAllNone;

  /// No description provided for @referenceDeletingAll.
  ///
  /// In en, this message translates to:
  /// **'Deleting…'**
  String get referenceDeletingAll;

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

  /// No description provided for @navAuditLog.
  ///
  /// In en, this message translates to:
  /// **'Activity log'**
  String get navAuditLog;

  /// No description provided for @navAuditLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Who did what, and when'**
  String get navAuditLogSubtitle;

  /// No description provided for @auditEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No events yet'**
  String get auditEmptyTitle;

  /// No description provided for @auditEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Every change made in the app is recorded here.'**
  String get auditEmptyBody;

  /// No description provided for @auditSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by person or record…'**
  String get auditSearchHint;

  /// No description provided for @auditActionInsert.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get auditActionInsert;

  /// No description provided for @auditActionUpdate.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get auditActionUpdate;

  /// No description provided for @auditActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get auditActionDelete;

  /// No description provided for @auditActionLogin.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get auditActionLogin;

  /// No description provided for @auditActionLogout.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get auditActionLogout;

  /// No description provided for @auditFilterAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get auditFilterAction;

  /// No description provided for @auditFilterEntity.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get auditFilterEntity;

  /// No description provided for @auditFilterActor.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get auditFilterActor;

  /// No description provided for @auditFilterDate.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get auditFilterDate;

  /// No description provided for @auditClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get auditClearFilters;

  /// No description provided for @auditSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get auditSystem;

  /// No description provided for @auditDetails.
  ///
  /// In en, this message translates to:
  /// **'Event details'**
  String get auditDetails;

  /// No description provided for @auditActor.
  ///
  /// In en, this message translates to:
  /// **'Done by'**
  String get auditActor;

  /// No description provided for @auditChanges.
  ///
  /// In en, this message translates to:
  /// **'What changed'**
  String get auditChanges;

  /// No description provided for @auditRecordData.
  ///
  /// In en, this message translates to:
  /// **'Record data'**
  String get auditRecordData;

  /// No description provided for @auditDeletedData.
  ///
  /// In en, this message translates to:
  /// **'Deleted record'**
  String get auditDeletedData;

  /// No description provided for @auditRecipients.
  ///
  /// In en, this message translates to:
  /// **'{count} recipients'**
  String auditRecipients(int count);

  /// No description provided for @auditYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get auditYes;

  /// No description provided for @auditNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get auditNo;

  /// No description provided for @auditNoDetails.
  ///
  /// In en, this message translates to:
  /// **'This event carries no further details.'**
  String get auditNoDetails;

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
  /// **'Decisions'**
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
  /// **'Decisions'**
  String get dashboardReports;

  /// No description provided for @dashboardReportsCaption.
  ///
  /// In en, this message translates to:
  /// **'{authors, plural, =0{from nobody} =1{from one author} other{from {authors} authors}}'**
  String dashboardReportsCaption(int authors);

  /// No description provided for @dashboardReportsTrend.
  ///
  /// In en, this message translates to:
  /// **'Decisions over 30 days'**
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

  /// No description provided for @prayerTimesTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get prayerTimesTitle;

  /// No description provided for @prayerFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerFajr;

  /// No description provided for @prayerSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get prayerSunrise;

  /// No description provided for @prayerDhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerDhuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerIsha;

  /// No description provided for @prayerNextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next prayer'**
  String get prayerNextLabel;

  /// No description provided for @prayerFajrEndsLabel.
  ///
  /// In en, this message translates to:
  /// **'Fajr time ends'**
  String get prayerFajrEndsLabel;

  /// No description provided for @prayerRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get prayerRemainingLabel;

  /// No description provided for @prayerNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get prayerNowLabel;

  /// No description provided for @prayerAm.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get prayerAm;

  /// No description provided for @prayerPm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get prayerPm;

  /// No description provided for @prayerTomorrow.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get prayerTomorrow;

  /// No description provided for @prayerSunriseGapNote.
  ///
  /// In en, this message translates to:
  /// **'Sunrise — no prayer is due until Dhuhr'**
  String get prayerSunriseGapNote;

  /// No description provided for @prayerLocating.
  ///
  /// In en, this message translates to:
  /// **'Finding you…'**
  String get prayerLocating;

  /// No description provided for @prayerApproximate.
  ///
  /// In en, this message translates to:
  /// **'Approximate'**
  String get prayerApproximate;

  /// No description provided for @prayerYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get prayerYourLocation;

  /// No description provided for @prayerPlaceMakkah.
  ///
  /// In en, this message translates to:
  /// **'Makkah'**
  String get prayerPlaceMakkah;

  /// No description provided for @prayerPlaceMina.
  ///
  /// In en, this message translates to:
  /// **'Mina'**
  String get prayerPlaceMina;

  /// No description provided for @prayerPlaceMuzdalifah.
  ///
  /// In en, this message translates to:
  /// **'Muzdalifah'**
  String get prayerPlaceMuzdalifah;

  /// No description provided for @prayerPlaceArafat.
  ///
  /// In en, this message translates to:
  /// **'Arafat'**
  String get prayerPlaceArafat;

  /// No description provided for @prayerPlaceMadinah.
  ///
  /// In en, this message translates to:
  /// **'Madinah'**
  String get prayerPlaceMadinah;

  /// No description provided for @prayerPlaceJeddah.
  ///
  /// In en, this message translates to:
  /// **'Jeddah'**
  String get prayerPlaceJeddah;

  /// No description provided for @prayerAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer alerts'**
  String get prayerAlertsTitle;

  /// No description provided for @prayerAlertsEnable.
  ///
  /// In en, this message translates to:
  /// **'Announce the prayers'**
  String get prayerAlertsEnable;

  /// No description provided for @prayerAlertsHint.
  ///
  /// In en, this message translates to:
  /// **'This phone alone. Times are worked out on the device from where it is standing — nothing is sent from a server.'**
  String get prayerAlertsHint;

  /// No description provided for @prayerAlertsWhich.
  ///
  /// In en, this message translates to:
  /// **'Which prayers'**
  String get prayerAlertsWhich;

  /// No description provided for @prayerAlertsBefore.
  ///
  /// In en, this message translates to:
  /// **'Warning before the call'**
  String get prayerAlertsBefore;

  /// No description provided for @prayerAlertsBeforeOff.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get prayerAlertsBeforeOff;

  /// No description provided for @prayerAlertsMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String prayerAlertsMinutes(int count);

  /// No description provided for @prayerAlertsSilent.
  ///
  /// In en, this message translates to:
  /// **'Without a sound'**
  String get prayerAlertsSilent;

  /// No description provided for @prayerAlertsSilentHint.
  ///
  /// In en, this message translates to:
  /// **'It still appears and still vibrates.'**
  String get prayerAlertsSilentHint;

  /// No description provided for @prayerAlertsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are switched off for this app in the system settings.'**
  String get prayerAlertsBlocked;

  /// No description provided for @prayerAlertsInexact.
  ///
  /// In en, this message translates to:
  /// **'Android may hold these back by several minutes. Allow exact alarms so each call arrives on the minute.'**
  String get prayerAlertsInexact;

  /// No description provided for @prayerAlertsGrantExact.
  ///
  /// In en, this message translates to:
  /// **'Allow exact alarms'**
  String get prayerAlertsGrantExact;

  /// No description provided for @prayerAlertsNeedLocation.
  ///
  /// In en, this message translates to:
  /// **'Set your location on the prayer card first — nothing is announced from an approximate position.'**
  String get prayerAlertsNeedLocation;

  /// No description provided for @prayerAlertsUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Prayer alerts are an Android feature.'**
  String get prayerAlertsUnsupported;

  /// No description provided for @prayerAlertNow.
  ///
  /// In en, this message translates to:
  /// **'{prayer} is now due'**
  String prayerAlertNow(String prayer);

  /// No description provided for @prayerAlertNowBody.
  ///
  /// In en, this message translates to:
  /// **'The call is at {clock}'**
  String prayerAlertNowBody(String clock);

  /// No description provided for @prayerAlertBefore.
  ///
  /// In en, this message translates to:
  /// **'{prayer} in {count} minutes'**
  String prayerAlertBefore(String prayer, int count);

  /// No description provided for @prayerAlertBeforeBody.
  ///
  /// In en, this message translates to:
  /// **'The call is at {clock}'**
  String prayerAlertBeforeBody(String clock);

  /// No description provided for @prayerWidgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Home screen'**
  String get prayerWidgetTitle;

  /// No description provided for @prayerWidgetHint.
  ///
  /// In en, this message translates to:
  /// **'The next prayer and its countdown, on the phone\'s home screen — without opening the app.'**
  String get prayerWidgetHint;

  /// No description provided for @prayerWidgetAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to home screen'**
  String get prayerWidgetAdd;

  /// No description provided for @prayerWidgetAddManually.
  ///
  /// In en, this message translates to:
  /// **'Long-press an empty spot on the home screen, choose Widgets, and pick this app.'**
  String get prayerWidgetAddManually;

  /// No description provided for @prayerWidgetInstalled.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Not added yet} =1{Added} other{Added, {count} copies}}'**
  String prayerWidgetInstalled(int count);

  /// No description provided for @prayerWidgetStale.
  ///
  /// In en, this message translates to:
  /// **'Open the app to refresh the times'**
  String get prayerWidgetStale;

  /// No description provided for @navMyComplaints.
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get navMyComplaints;

  /// No description provided for @navMyComplaintsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What you filed, and what came back'**
  String get navMyComplaintsSubtitle;

  /// No description provided for @navComplaints.
  ///
  /// In en, this message translates to:
  /// **'Complaints register'**
  String get navComplaints;

  /// No description provided for @navComplaintsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every complaint filed across the mission'**
  String get navComplaintsSubtitle;

  /// No description provided for @complaintsTitle.
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get complaintsTitle;

  /// No description provided for @complaintsMineTitle.
  ///
  /// In en, this message translates to:
  /// **'My complaints'**
  String get complaintsMineTitle;

  /// No description provided for @complaintsAgainstMeTitle.
  ///
  /// In en, this message translates to:
  /// **'Complaints about me'**
  String get complaintsAgainstMeTitle;

  /// No description provided for @complaintsNew.
  ///
  /// In en, this message translates to:
  /// **'File a complaint'**
  String get complaintsNew;

  /// No description provided for @complaintsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No complaints filed'**
  String get complaintsEmpty;

  /// No description provided for @complaintsEmptyAll.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been filed yet'**
  String get complaintsEmptyAll;

  /// No description provided for @complaintsAgainstMeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been filed about you'**
  String get complaintsAgainstMeEmpty;

  /// No description provided for @complaintsNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No complaint matches this'**
  String get complaintsNoMatches;

  /// No description provided for @complaintsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search complaints'**
  String get complaintsSearchHint;

  /// No description provided for @complaintsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get complaintsFilterAll;

  /// No description provided for @complaintsShowDismissed.
  ///
  /// In en, this message translates to:
  /// **'Include dismissed'**
  String get complaintsShowDismissed;

  /// No description provided for @complaintTarget.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get complaintTarget;

  /// No description provided for @complaintTargetEmployee.
  ///
  /// In en, this message translates to:
  /// **'An employee'**
  String get complaintTargetEmployee;

  /// No description provided for @complaintTargetModule.
  ///
  /// In en, this message translates to:
  /// **'An operational file'**
  String get complaintTargetModule;

  /// No description provided for @complaintTargetReport.
  ///
  /// In en, this message translates to:
  /// **'A decision'**
  String get complaintTargetReport;

  /// No description provided for @complaintTargetHotel.
  ///
  /// In en, this message translates to:
  /// **'A hotel'**
  String get complaintTargetHotel;

  /// No description provided for @complaintTargetCluster.
  ///
  /// In en, this message translates to:
  /// **'A cluster'**
  String get complaintTargetCluster;

  /// No description provided for @complaintTargetGroup.
  ///
  /// In en, this message translates to:
  /// **'A group'**
  String get complaintTargetGroup;

  /// No description provided for @complaintTargetOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get complaintTargetOther;

  /// No description provided for @complaintTargetPick.
  ///
  /// In en, this message translates to:
  /// **'Choose what this is about'**
  String get complaintTargetPick;

  /// No description provided for @complaintTargetPicked.
  ///
  /// In en, this message translates to:
  /// **'Selected: {name}'**
  String complaintTargetPicked(String name);

  /// No description provided for @complaintBody.
  ///
  /// In en, this message translates to:
  /// **'What happened'**
  String get complaintBody;

  /// No description provided for @complaintBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Describe it in your own words'**
  String get complaintBodyHint;

  /// No description provided for @complaintBodyRequired.
  ///
  /// In en, this message translates to:
  /// **'Write what happened'**
  String get complaintBodyRequired;

  /// No description provided for @complaintTargetRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose what the complaint is about'**
  String get complaintTargetRequired;

  /// No description provided for @complaintSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send the complaint'**
  String get complaintSubmit;

  /// No description provided for @complaintSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Your complaint was filed'**
  String get complaintSubmitted;

  /// No description provided for @complaintAnonymousNote.
  ///
  /// In en, this message translates to:
  /// **'The person you are complaining about will read this, but will not be told who filed it.'**
  String get complaintAnonymousNote;

  /// No description provided for @complaintReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get complaintReply;

  /// No description provided for @complaintReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Write a reply'**
  String get complaintReplyHint;

  /// No description provided for @complaintReplySent.
  ///
  /// In en, this message translates to:
  /// **'Reply sent'**
  String get complaintReplySent;

  /// No description provided for @complaintReplyCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No replies} =1{1 reply} other{{count} replies}}'**
  String complaintReplyCount(int count);

  /// No description provided for @complaintRoleComplainant.
  ///
  /// In en, this message translates to:
  /// **'The complainant'**
  String get complaintRoleComplainant;

  /// No description provided for @complaintRoleAccused.
  ///
  /// In en, this message translates to:
  /// **'The employee complained about'**
  String get complaintRoleAccused;

  /// No description provided for @complaintRoleManager.
  ///
  /// In en, this message translates to:
  /// **'Oversight'**
  String get complaintRoleManager;

  /// No description provided for @complaintLocked.
  ///
  /// In en, this message translates to:
  /// **'This complaint is closed to replies'**
  String get complaintLocked;

  /// No description provided for @complaintLock.
  ///
  /// In en, this message translates to:
  /// **'Close to replies'**
  String get complaintLock;

  /// No description provided for @complaintUnlock.
  ///
  /// In en, this message translates to:
  /// **'Reopen for replies'**
  String get complaintUnlock;

  /// No description provided for @complaintDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get complaintDismissed;

  /// No description provided for @complaintDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss as unfounded'**
  String get complaintDismiss;

  /// No description provided for @complaintUndismiss.
  ///
  /// In en, this message translates to:
  /// **'Reinstate'**
  String get complaintUndismiss;

  /// No description provided for @complaintDismissReason.
  ///
  /// In en, this message translates to:
  /// **'Why it is being dismissed (optional)'**
  String get complaintDismissReason;

  /// No description provided for @complaintDismissConfirm.
  ///
  /// In en, this message translates to:
  /// **'A dismissed complaint no longer counts toward an automatic suspension, and may lift one already in force. Dismiss it?'**
  String get complaintDismissConfirm;

  /// No description provided for @complaintDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete the complaint'**
  String get complaintDelete;

  /// No description provided for @complaintDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this complaint and everything attached to it? This cannot be undone.'**
  String get complaintDeleteConfirm;

  /// No description provided for @complaintDeleted.
  ///
  /// In en, this message translates to:
  /// **'Complaint deleted'**
  String get complaintDeleted;

  /// No description provided for @complaintWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get complaintWithdraw;

  /// No description provided for @complaintMissing.
  ///
  /// In en, this message translates to:
  /// **'This complaint is no longer there'**
  String get complaintMissing;

  /// No description provided for @complaintFiledOn.
  ///
  /// In en, this message translates to:
  /// **'Filed {date}'**
  String complaintFiledOn(String date);

  /// No description provided for @complaintsSectionAgainst.
  ///
  /// In en, this message translates to:
  /// **'Complaints about this employee'**
  String get complaintsSectionAgainst;

  /// No description provided for @complaintsAgainstCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{None} =1{1 complaint} other{{count} complaints}}'**
  String complaintsAgainstCount(int count);

  /// No description provided for @complaintsDistinctComplainants.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no one} =1{1 person} other{{count} different people}}'**
  String complaintsDistinctComplainants(int count);

  /// No description provided for @complaintsAutoSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended automatically by complaints'**
  String get complaintsAutoSuspended;

  /// No description provided for @complaintsAutoSuspendNear.
  ///
  /// In en, this message translates to:
  /// **'One more complainant suspends this account automatically'**
  String get complaintsAutoSuspendNear;

  /// No description provided for @complaintsDismissedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} dismissed'**
  String complaintsDismissedCount(int count);

  /// No description provided for @navEvaluations.
  ///
  /// In en, this message translates to:
  /// **'Evaluations'**
  String get navEvaluations;

  /// No description provided for @navEvaluationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What you were asked to evaluate'**
  String get navEvaluationsSubtitle;

  /// No description provided for @navEvaluationsManage.
  ///
  /// In en, this message translates to:
  /// **'Evaluation register'**
  String get navEvaluationsManage;

  /// No description provided for @navEvaluationsManageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every evaluation across the mission and its marks'**
  String get navEvaluationsManageSubtitle;

  /// No description provided for @navEvaluationForms.
  ///
  /// In en, this message translates to:
  /// **'Evaluation forms'**
  String get navEvaluationForms;

  /// No description provided for @navEvaluationFormsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The forms, their questions and their marks'**
  String get navEvaluationFormsSubtitle;

  /// No description provided for @evaluationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Evaluation register'**
  String get evaluationsTitle;

  /// No description provided for @evaluationsMineTitle.
  ///
  /// In en, this message translates to:
  /// **'My evaluations'**
  String get evaluationsMineTitle;

  /// No description provided for @evaluationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have not been asked to evaluate anything yet'**
  String get evaluationsEmpty;

  /// No description provided for @evaluationsEmptyAll.
  ///
  /// In en, this message translates to:
  /// **'No evaluation has been opened yet'**
  String get evaluationsEmptyAll;

  /// No description provided for @evaluationsNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get evaluationsNoMatches;

  /// No description provided for @evaluationsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by form or subject'**
  String get evaluationsSearchHint;

  /// No description provided for @evaluationsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get evaluationsFilterAll;

  /// No description provided for @evaluationsNew.
  ///
  /// In en, this message translates to:
  /// **'New evaluation'**
  String get evaluationsNew;

  /// No description provided for @evaluationsOpenCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{nothing outstanding} =1{1 outstanding} other{{count} outstanding}}'**
  String evaluationsOpenCount(int count);

  /// No description provided for @evaluationsOverdueCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{none overdue} =1{1 overdue} other{{count} overdue}}'**
  String evaluationsOverdueCount(int count);

  /// No description provided for @evaluationStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get evaluationStatusDraft;

  /// No description provided for @evaluationStatusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get evaluationStatusSubmitted;

  /// No description provided for @evaluationOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get evaluationOverdue;

  /// No description provided for @evaluationDueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String evaluationDueOn(String date);

  /// No description provided for @evaluationOpenedOn.
  ///
  /// In en, this message translates to:
  /// **'Opened {date}'**
  String evaluationOpenedOn(String date);

  /// No description provided for @evaluationSubmittedOn.
  ///
  /// In en, this message translates to:
  /// **'Completed {date}'**
  String evaluationSubmittedOn(String date);

  /// No description provided for @evaluationEvaluator.
  ///
  /// In en, this message translates to:
  /// **'Evaluator'**
  String get evaluationEvaluator;

  /// No description provided for @evaluationEvaluatorHidden.
  ///
  /// In en, this message translates to:
  /// **'Evaluator not disclosed'**
  String get evaluationEvaluatorHidden;

  /// No description provided for @evaluationSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get evaluationSubject;

  /// No description provided for @evaluationNote.
  ///
  /// In en, this message translates to:
  /// **'Note from the office'**
  String get evaluationNote;

  /// No description provided for @evaluationProgress.
  ///
  /// In en, this message translates to:
  /// **'{answered} of {total}'**
  String evaluationProgress(int answered, int total);

  /// No description provided for @evaluationScore.
  ///
  /// In en, this message translates to:
  /// **'{score} of {total}'**
  String evaluationScore(String score, String total);

  /// No description provided for @evaluationPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String evaluationPercent(String percent);

  /// No description provided for @evaluationTargetEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get evaluationTargetEmployee;

  /// No description provided for @evaluationTargetModule.
  ///
  /// In en, this message translates to:
  /// **'Operational file'**
  String get evaluationTargetModule;

  /// No description provided for @evaluationTargetReport.
  ///
  /// In en, this message translates to:
  /// **'Decision'**
  String get evaluationTargetReport;

  /// No description provided for @evaluationTargetHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get evaluationTargetHotel;

  /// No description provided for @evaluationTargetCluster.
  ///
  /// In en, this message translates to:
  /// **'Cluster'**
  String get evaluationTargetCluster;

  /// No description provided for @evaluationTargetGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get evaluationTargetGroup;

  /// No description provided for @evaluationTargetOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get evaluationTargetOther;

  /// No description provided for @evaluationSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Evaluation'**
  String get evaluationSheetTitle;

  /// No description provided for @evaluationStageOf.
  ///
  /// In en, this message translates to:
  /// **'Stage {index} of {total}'**
  String evaluationStageOf(int index, int total);

  /// No description provided for @evaluationStageScore.
  ///
  /// In en, this message translates to:
  /// **'Stage mark {score} of {total}'**
  String evaluationStageScore(String score, String total);

  /// No description provided for @evaluationQuestionRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get evaluationQuestionRequired;

  /// No description provided for @evaluationQuestionOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get evaluationQuestionOptional;

  /// No description provided for @evaluationQuestionUnanswered.
  ///
  /// In en, this message translates to:
  /// **'Not answered'**
  String get evaluationQuestionUnanswered;

  /// No description provided for @evaluationWriteHint.
  ///
  /// In en, this message translates to:
  /// **'Write your answer'**
  String get evaluationWriteHint;

  /// No description provided for @evaluationSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get evaluationSaveDraft;

  /// No description provided for @evaluationSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit evaluation'**
  String get evaluationSubmit;

  /// No description provided for @evaluationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Evaluation submitted'**
  String get evaluationSubmitted;

  /// No description provided for @evaluationDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Answers saved'**
  String get evaluationDraftSaved;

  /// No description provided for @evaluationIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Answer every required question first'**
  String get evaluationIncomplete;

  /// No description provided for @evaluationReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get evaluationReopen;

  /// No description provided for @evaluationReopened.
  ///
  /// In en, this message translates to:
  /// **'Evaluation reopened'**
  String get evaluationReopened;

  /// No description provided for @evaluationReopenConfirm.
  ///
  /// In en, this message translates to:
  /// **'This returns the evaluation to in-progress and keeps the answers. Continue?'**
  String get evaluationReopenConfirm;

  /// No description provided for @evaluationNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get evaluationNext;

  /// No description provided for @evaluationBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get evaluationBack;

  /// No description provided for @evaluationLocked.
  ///
  /// In en, this message translates to:
  /// **'This evaluation is read-only'**
  String get evaluationLocked;

  /// No description provided for @evaluationDiscardChanges.
  ///
  /// In en, this message translates to:
  /// **'There are unsaved answers. Leave without saving?'**
  String get evaluationDiscardChanges;

  /// No description provided for @evaluationMissing.
  ///
  /// In en, this message translates to:
  /// **'Evaluation not found'**
  String get evaluationMissing;

  /// No description provided for @evaluationAlreadySubmitted.
  ///
  /// In en, this message translates to:
  /// **'This evaluation was already submitted'**
  String get evaluationAlreadySubmitted;

  /// No description provided for @evaluationDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete evaluation'**
  String get evaluationDelete;

  /// No description provided for @evaluationDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This evaluation and its answers are deleted permanently. Continue?'**
  String get evaluationDeleteConfirm;

  /// No description provided for @evaluationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Evaluation deleted'**
  String get evaluationDeleted;

  /// No description provided for @evaluationAssignTitle.
  ///
  /// In en, this message translates to:
  /// **'Open an evaluation'**
  String get evaluationAssignTitle;

  /// No description provided for @evaluationAssignForm.
  ///
  /// In en, this message translates to:
  /// **'Form'**
  String get evaluationAssignForm;

  /// No description provided for @evaluationAssignPickForm.
  ///
  /// In en, this message translates to:
  /// **'Choose an evaluation form'**
  String get evaluationAssignPickForm;

  /// No description provided for @evaluationAssignNoForms.
  ///
  /// In en, this message translates to:
  /// **'No active forms. Create one and switch it on first.'**
  String get evaluationAssignNoForms;

  /// No description provided for @evaluationAssignSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get evaluationAssignSubject;

  /// No description provided for @evaluationAssignPickSubject.
  ///
  /// In en, this message translates to:
  /// **'Choose the subject'**
  String get evaluationAssignPickSubject;

  /// No description provided for @evaluationAssignSubjectPicked.
  ///
  /// In en, this message translates to:
  /// **'About: {name}'**
  String evaluationAssignSubjectPicked(String name);

  /// No description provided for @evaluationAssignEvaluator.
  ///
  /// In en, this message translates to:
  /// **'Evaluator'**
  String get evaluationAssignEvaluator;

  /// No description provided for @evaluationAssignPickEvaluator.
  ///
  /// In en, this message translates to:
  /// **'Choose the employee'**
  String get evaluationAssignPickEvaluator;

  /// No description provided for @evaluationAssignNoteHint.
  ///
  /// In en, this message translates to:
  /// **'What should they look at? (optional)'**
  String get evaluationAssignNoteHint;

  /// No description provided for @evaluationAssignDue.
  ///
  /// In en, this message translates to:
  /// **'Due date (optional)'**
  String get evaluationAssignDue;

  /// No description provided for @evaluationAssignDueClear.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get evaluationAssignDueClear;

  /// No description provided for @evaluationAssignSubmit.
  ///
  /// In en, this message translates to:
  /// **'Open and send'**
  String get evaluationAssignSubmit;

  /// No description provided for @evaluationAssigned.
  ///
  /// In en, this message translates to:
  /// **'Evaluation opened and the evaluator notified'**
  String get evaluationAssigned;

  /// No description provided for @evaluationAssignAnonymousNote.
  ///
  /// In en, this message translates to:
  /// **'The employee sees their mark and never learns who wrote it.'**
  String get evaluationAssignAnonymousNote;

  /// No description provided for @evaluationFormsTitle.
  ///
  /// In en, this message translates to:
  /// **'Evaluation forms'**
  String get evaluationFormsTitle;

  /// No description provided for @evaluationFormsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No evaluation forms yet'**
  String get evaluationFormsEmpty;

  /// No description provided for @evaluationFormsNew.
  ///
  /// In en, this message translates to:
  /// **'New form'**
  String get evaluationFormsNew;

  /// No description provided for @evaluationFormsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search the forms'**
  String get evaluationFormsSearchHint;

  /// No description provided for @evaluationFormActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get evaluationFormActive;

  /// No description provided for @evaluationFormInactive.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get evaluationFormInactive;

  /// No description provided for @evaluationFormActivate.
  ///
  /// In en, this message translates to:
  /// **'Switch on'**
  String get evaluationFormActivate;

  /// No description provided for @evaluationFormDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Switch off'**
  String get evaluationFormDeactivate;

  /// No description provided for @evaluationFormStages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 stage} other{{count} stages}}'**
  String evaluationFormStages(int count);

  /// No description provided for @evaluationFormQuestions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question} other{{count} questions}}'**
  String evaluationFormQuestions(int count);

  /// No description provided for @evaluationFormTotal.
  ///
  /// In en, this message translates to:
  /// **'out of {total}'**
  String evaluationFormTotal(String total);

  /// No description provided for @evaluationFormInUse.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 evaluation open on it} other{{count} evaluations open on it}}'**
  String evaluationFormInUse(int count);

  /// No description provided for @evaluationFormDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete form'**
  String get evaluationFormDelete;

  /// No description provided for @evaluationFormDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This form, its stages and its questions are deleted. Continue?'**
  String get evaluationFormDeleteConfirm;

  /// No description provided for @evaluationFormDeleted.
  ///
  /// In en, this message translates to:
  /// **'Form deleted'**
  String get evaluationFormDeleted;

  /// No description provided for @evaluationFormInUseDelete.
  ///
  /// In en, this message translates to:
  /// **'A form with evaluations open on it cannot be deleted. Switch it off instead.'**
  String get evaluationFormInUseDelete;

  /// No description provided for @evaluationEditorNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New evaluation form'**
  String get evaluationEditorNewTitle;

  /// No description provided for @evaluationEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit form'**
  String get evaluationEditorTitle;

  /// No description provided for @evaluationEditorName.
  ///
  /// In en, this message translates to:
  /// **'Form name'**
  String get evaluationEditorName;

  /// No description provided for @evaluationEditorNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Operational file evaluation - Tarwiyah and catering'**
  String get evaluationEditorNameHint;

  /// No description provided for @evaluationEditorDescription.
  ///
  /// In en, this message translates to:
  /// **'Short description (optional)'**
  String get evaluationEditorDescription;

  /// No description provided for @evaluationEditorFor.
  ///
  /// In en, this message translates to:
  /// **'Evaluates'**
  String get evaluationEditorFor;

  /// No description provided for @evaluationEditorForLocked.
  ///
  /// In en, this message translates to:
  /// **'The subject kind cannot change once evaluations have been opened on the form'**
  String get evaluationEditorForLocked;

  /// No description provided for @evaluationEditorPublish.
  ///
  /// In en, this message translates to:
  /// **'Active for use'**
  String get evaluationEditorPublish;

  /// No description provided for @evaluationEditorPublishHint.
  ///
  /// In en, this message translates to:
  /// **'A form that is switched off takes no new evaluations; the ones already open keep working'**
  String get evaluationEditorPublishHint;

  /// No description provided for @evaluationEditorStages.
  ///
  /// In en, this message translates to:
  /// **'Stages'**
  String get evaluationEditorStages;

  /// No description provided for @evaluationEditorAddStage.
  ///
  /// In en, this message translates to:
  /// **'Add stage'**
  String get evaluationEditorAddStage;

  /// No description provided for @evaluationEditorStageName.
  ///
  /// In en, this message translates to:
  /// **'Stage name'**
  String get evaluationEditorStageName;

  /// No description provided for @evaluationEditorStageNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Tarwiyah team'**
  String get evaluationEditorStageNameHint;

  /// No description provided for @evaluationEditorStageDescription.
  ///
  /// In en, this message translates to:
  /// **'Stage description (optional)'**
  String get evaluationEditorStageDescription;

  /// No description provided for @evaluationEditorRemoveStage.
  ///
  /// In en, this message translates to:
  /// **'Delete stage'**
  String get evaluationEditorRemoveStage;

  /// No description provided for @evaluationEditorRemoveStageConfirm.
  ///
  /// In en, this message translates to:
  /// **'The stage and all its questions are deleted. Continue?'**
  String get evaluationEditorRemoveStageConfirm;

  /// No description provided for @evaluationEditorAddChoice.
  ///
  /// In en, this message translates to:
  /// **'Multiple-choice question'**
  String get evaluationEditorAddChoice;

  /// No description provided for @evaluationEditorAddWritten.
  ///
  /// In en, this message translates to:
  /// **'Written question'**
  String get evaluationEditorAddWritten;

  /// No description provided for @evaluationEditorQuestionText.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get evaluationEditorQuestionText;

  /// No description provided for @evaluationEditorQuestionPoints.
  ///
  /// In en, this message translates to:
  /// **'Question mark'**
  String get evaluationEditorQuestionPoints;

  /// No description provided for @evaluationEditorRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get evaluationEditorRequired;

  /// No description provided for @evaluationEditorAddOption.
  ///
  /// In en, this message translates to:
  /// **'Add answer'**
  String get evaluationEditorAddOption;

  /// No description provided for @evaluationEditorOptionText.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get evaluationEditorOptionText;

  /// No description provided for @evaluationEditorOptionPoints.
  ///
  /// In en, this message translates to:
  /// **'Mark'**
  String get evaluationEditorOptionPoints;

  /// No description provided for @evaluationEditorNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'No questions in this stage yet'**
  String get evaluationEditorNoQuestions;

  /// No description provided for @evaluationEditorWrittenNote.
  ///
  /// In en, this message translates to:
  /// **'A written question carries no mark - neither the question nor its answer'**
  String get evaluationEditorWrittenNote;

  /// No description provided for @evaluationEditorUnreachable.
  ///
  /// In en, this message translates to:
  /// **'The best answer gives {best} while the question is worth {points}'**
  String evaluationEditorUnreachable(String best, String points);

  /// No description provided for @evaluationEditorNeedsTwoOptions.
  ///
  /// In en, this message translates to:
  /// **'A multiple-choice question needs at least two answers'**
  String get evaluationEditorNeedsTwoOptions;

  /// No description provided for @evaluationEditorTotal.
  ///
  /// In en, this message translates to:
  /// **'Form total: {total}'**
  String evaluationEditorTotal(String total);

  /// No description provided for @evaluationEditorSave.
  ///
  /// In en, this message translates to:
  /// **'Save form'**
  String get evaluationEditorSave;

  /// No description provided for @evaluationEditorSaved.
  ///
  /// In en, this message translates to:
  /// **'Form saved'**
  String get evaluationEditorSaved;

  /// No description provided for @evaluationEditorCannotPublish.
  ///
  /// In en, this message translates to:
  /// **'Finish the form before switching it on: every stage needs a name, every question needs text, and every multiple-choice question needs at least two answers'**
  String get evaluationEditorCannotPublish;

  /// No description provided for @evaluationEditorMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get evaluationEditorMoveUp;

  /// No description provided for @evaluationEditorMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get evaluationEditorMoveDown;

  /// No description provided for @evaluationsAboutMeTitle.
  ///
  /// In en, this message translates to:
  /// **'Evaluations about me'**
  String get evaluationsAboutMeTitle;

  /// No description provided for @evaluationsAboutMeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No evaluation has been written about you'**
  String get evaluationsAboutMeEmpty;

  /// No description provided for @evaluationsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'Evaluations of this subject'**
  String get evaluationsSectionAbout;

  /// No description provided for @evaluationsAboutCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No evaluations} =1{1 evaluation} other{{count} evaluations}}'**
  String evaluationsAboutCount(int count);

  /// No description provided for @evaluationsAboutPending.
  ///
  /// In en, this message translates to:
  /// **'{count} in progress'**
  String evaluationsAboutPending(int count);

  /// No description provided for @evaluationsAboutAverage.
  ///
  /// In en, this message translates to:
  /// **'Average {percent}%'**
  String evaluationsAboutAverage(String percent);

  /// No description provided for @evaluationsAboutAnonymousNote.
  ///
  /// In en, this message translates to:
  /// **'Marks are shown without the names of who wrote them.'**
  String get evaluationsAboutAnonymousNote;

  /// No description provided for @evaluationErrorOptionTooHigh.
  ///
  /// In en, this message translates to:
  /// **'An answer is worth more than the question it answers'**
  String get evaluationErrorOptionTooHigh;

  /// No description provided for @evaluationErrorWrittenHasOptions.
  ///
  /// In en, this message translates to:
  /// **'A written question takes no preset answers'**
  String get evaluationErrorWrittenHasOptions;

  /// No description provided for @evaluationsOpenFromForms.
  ///
  /// In en, this message translates to:
  /// **'Evaluations are opened from إدارة التقييم, standing on the form they will be filled on'**
  String get evaluationsOpenFromForms;

  /// No description provided for @evaluationAssignNoTargets.
  ///
  /// In en, this message translates to:
  /// **'There is nothing of kind «{kind}» to open an evaluation about'**
  String evaluationAssignNoTargets(String kind);

  /// No description provided for @evaluationAssignNoEvaluators.
  ///
  /// In en, this message translates to:
  /// **'There is no employee who can be assigned'**
  String get evaluationAssignNoEvaluators;

  /// No description provided for @evaluationFormMustBeActive.
  ///
  /// In en, this message translates to:
  /// **'Switch the form on before an evaluation can be opened on it'**
  String get evaluationFormMustBeActive;

  /// No description provided for @evaluationEditorForHint.
  ///
  /// In en, this message translates to:
  /// **'This picks the KIND of subject only. The particular file or employee is named when an evaluation is opened on this form — from the «New evaluation» button on its card, once the form is switched on.'**
  String get evaluationEditorForHint;

  /// No description provided for @evaluationAssignNoSeason.
  ///
  /// In en, this message translates to:
  /// **'The current season could not be read, and the evaluator cannot be chosen without it'**
  String get evaluationAssignNoSeason;

  /// No description provided for @evaluationAssignedShow.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get evaluationAssignedShow;

  /// No description provided for @evaluationAssignSubjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get evaluationAssignSubjects;

  /// No description provided for @evaluationAssignEvaluators.
  ///
  /// In en, this message translates to:
  /// **'Evaluators'**
  String get evaluationAssignEvaluators;

  /// No description provided for @evaluationAssignPickSubjects.
  ///
  /// In en, this message translates to:
  /// **'Choose the subjects'**
  String get evaluationAssignPickSubjects;

  /// No description provided for @evaluationAssignPickEvaluators.
  ///
  /// In en, this message translates to:
  /// **'Choose the employees'**
  String get evaluationAssignPickEvaluators;

  /// No description provided for @evaluationAssignAddMore.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get evaluationAssignAddMore;

  /// No description provided for @evaluationAssignPlanned.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No evaluation will be opened} =1{1 evaluation will be opened} other{{count} evaluations will be opened}}'**
  String evaluationAssignPlanned(int count);

  /// No description provided for @evaluationAssignCross.
  ///
  /// In en, this message translates to:
  /// **'One per subject per evaluator — {targets} × {evaluators}'**
  String evaluationAssignCross(int targets, int evaluators);

  /// No description provided for @evaluationAssignedMany.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 evaluation opened and its evaluator notified} other{{count} evaluations opened and their evaluators notified}}'**
  String evaluationAssignedMany(int count);

  /// No description provided for @evaluationFormShowEvaluations.
  ///
  /// In en, this message translates to:
  /// **'Show the evaluations on it'**
  String get evaluationFormShowEvaluations;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @locationResolved.
  ///
  /// In en, this message translates to:
  /// **'Coordinates read from the link'**
  String get locationResolved;

  /// No description provided for @seasonMapOnlyThis.
  ///
  /// In en, this message translates to:
  /// **'Tap to show only this'**
  String get seasonMapOnlyThis;

  /// No description provided for @seasonMapShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get seasonMapShowAll;

  /// No description provided for @seasonMapNoTiles.
  ///
  /// In en, this message translates to:
  /// **'The map backdrop could not be loaded — the positions are right, only the pictures are missing'**
  String get seasonMapNoTiles;

  /// No description provided for @seasonMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Season map'**
  String get seasonMapTitle;

  /// No description provided for @seasonMapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The season\'s places and open reports on one map'**
  String get seasonMapSubtitle;

  /// No description provided for @seasonMapManned.
  ///
  /// In en, this message translates to:
  /// **'Somebody is there'**
  String get seasonMapManned;

  /// No description provided for @seasonMapUnmanned.
  ///
  /// In en, this message translates to:
  /// **'Nobody checked in'**
  String get seasonMapUnmanned;

  /// No description provided for @seasonMapIncident.
  ///
  /// In en, this message translates to:
  /// **'Open report'**
  String get seasonMapIncident;

  /// No description provided for @seasonMapEmpty.
  ///
  /// In en, this message translates to:
  /// **'No members'**
  String get seasonMapEmpty;

  /// No description provided for @seasonMapUncoded.
  ///
  /// In en, this message translates to:
  /// **'Cannot be checked into'**
  String get seasonMapUncoded;

  /// No description provided for @seasonMapPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted here'**
  String get seasonMapPosted;

  /// No description provided for @seasonMapPresent.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get seasonMapPresent;

  /// No description provided for @seasonMapOpenIncidents.
  ///
  /// In en, this message translates to:
  /// **'Open incidents'**
  String get seasonMapOpenIncidents;

  /// No description provided for @seasonMapInFile.
  ///
  /// In en, this message translates to:
  /// **'In the operational file'**
  String get seasonMapInFile;

  /// No description provided for @seasonMapCopyCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Copy coordinates'**
  String get seasonMapCopyCoordinates;

  /// No description provided for @seasonMapCoordinatesCopied.
  ///
  /// In en, this message translates to:
  /// **'Coordinates copied'**
  String get seasonMapCoordinatesCopied;

  /// No description provided for @seasonMapPlaces.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get seasonMapPlaces;

  /// No description provided for @seasonMapIncidents.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get seasonMapIncidents;

  /// No description provided for @seasonMapCounts.
  ///
  /// In en, this message translates to:
  /// **'{places} places · {incidents} reports'**
  String seasonMapCounts(int places, int incidents);

  /// No description provided for @seasonMapEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No place in this season has a position'**
  String get seasonMapEmptyState;

  /// No description provided for @seasonMapEmptyStateHint.
  ///
  /// In en, this message translates to:
  /// **'A place appears here once its position is set on the operational file'**
  String get seasonMapEmptyStateHint;

  /// No description provided for @incidentTitle.
  ///
  /// In en, this message translates to:
  /// **'Urgent report'**
  String get incidentTitle;

  /// No description provided for @incidentHint.
  ///
  /// In en, this message translates to:
  /// **'For what cannot wait — a breakdown, an accident, a cut-off. It reaches the operations room immediately.'**
  String get incidentHint;

  /// No description provided for @incidentBodyHint.
  ///
  /// In en, this message translates to:
  /// **'What has happened?'**
  String get incidentBodyHint;

  /// No description provided for @incidentAttach.
  ///
  /// In en, this message translates to:
  /// **'Attach a photo'**
  String get incidentAttach;

  /// No description provided for @incidentSend.
  ///
  /// In en, this message translates to:
  /// **'Send the report'**
  String get incidentSend;

  /// No description provided for @incidentSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get incidentSending;

  /// No description provided for @incidentSent.
  ///
  /// In en, this message translates to:
  /// **'The operations room has been alerted'**
  String get incidentSent;

  /// No description provided for @incidentWhatIsAttached.
  ///
  /// In en, this message translates to:
  /// **'Attached automatically: your name, your position, the time'**
  String get incidentWhatIsAttached;

  /// No description provided for @incidentNotDeliveredTitle.
  ///
  /// In en, this message translates to:
  /// **'It did not go through'**
  String get incidentNotDeliveredTitle;

  /// No description provided for @incidentNotDeliveredBody.
  ///
  /// In en, this message translates to:
  /// **'There is no network. The report is saved on your device and will be sent when it returns — but **nobody has been told yet**. If this cannot wait, telephone the operations room now.'**
  String get incidentNotDeliveredBody;

  /// No description provided for @incidentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Urgent reports'**
  String get incidentsTitle;

  /// No description provided for @incidentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No open reports'**
  String get incidentsEmpty;

  /// No description provided for @incidentsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Every urgent report appears here the moment it arrives'**
  String get incidentsEmptyHint;

  /// No description provided for @incidentsShowClosed.
  ///
  /// In en, this message translates to:
  /// **'Show closed'**
  String get incidentsShowClosed;

  /// No description provided for @incidentStateOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get incidentStateOpen;

  /// No description provided for @incidentStateInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get incidentStateInProgress;

  /// No description provided for @incidentStateClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get incidentStateClosed;

  /// No description provided for @incidentTake.
  ///
  /// In en, this message translates to:
  /// **'I\'ll take it'**
  String get incidentTake;

  /// No description provided for @incidentClose.
  ///
  /// In en, this message translates to:
  /// **'Close the report'**
  String get incidentClose;

  /// No description provided for @incidentReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get incidentReopen;

  /// No description provided for @incidentResolutionHint.
  ///
  /// In en, this message translates to:
  /// **'What happened? (optional)'**
  String get incidentResolutionHint;

  /// No description provided for @incidentCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get incidentCall;

  /// No description provided for @incidentOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get incidentOpenMap;

  /// No description provided for @incidentWaited.
  ///
  /// In en, this message translates to:
  /// **'Waiting {duration}'**
  String incidentWaited(String duration);

  /// No description provided for @incidentHandledBy.
  ///
  /// In en, this message translates to:
  /// **'Taken by {name}'**
  String incidentHandledBy(String name);

  /// No description provided for @incidentOpenCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No open reports} =1{1 open report} other{{count} open reports}}'**
  String incidentOpenCount(int count);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String durationMinutes(int count);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String durationHours(int count);

  /// No description provided for @checkInScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the place code'**
  String get checkInScanTitle;

  /// No description provided for @checkInScanHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the code fixed at the place'**
  String get checkInScanHint;

  /// No description provided for @checkInTorch.
  ///
  /// In en, this message translates to:
  /// **'Torch'**
  String get checkInTorch;

  /// No description provided for @checkInNoCamera.
  ///
  /// In en, this message translates to:
  /// **'The camera could not be opened — the permission may be refused'**
  String get checkInNoCamera;

  /// No description provided for @checkInNoCameraHint.
  ///
  /// In en, this message translates to:
  /// **'Checking in needs the code and your location together, so there is no way to do it without a camera'**
  String get checkInNoCameraHint;

  /// No description provided for @checkInTitle.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get checkInTitle;

  /// No description provided for @checkInAction.
  ///
  /// In en, this message translates to:
  /// **'Record my arrival'**
  String get checkInAction;

  /// No description provided for @checkInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the code fixed to the hotel or camp while you are standing there'**
  String get checkInSubtitle;

  /// No description provided for @checkInScan.
  ///
  /// In en, this message translates to:
  /// **'Scan the code'**
  String get checkInScan;

  /// No description provided for @checkInNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get checkInNoteHint;

  /// No description provided for @checkInDone.
  ///
  /// In en, this message translates to:
  /// **'Your arrival was recorded'**
  String get checkInDone;

  /// No description provided for @checkInDoneAt.
  ///
  /// In en, this message translates to:
  /// **'Recorded — {place}, {metres} m away'**
  String checkInDoneAt(String place, String metres);

  /// No description provided for @checkInQueued.
  ///
  /// In en, this message translates to:
  /// **'Saved on the device — it will be recorded when the network returns'**
  String get checkInQueued;

  /// No description provided for @checkInDistance.
  ///
  /// In en, this message translates to:
  /// **'{metres} m away'**
  String checkInDistance(String metres);

  /// No description provided for @checkInNotApproved.
  ///
  /// In en, this message translates to:
  /// **'Your account is not approved yet, so you cannot check in'**
  String get checkInNotApproved;

  /// No description provided for @checkInNotAPlace.
  ///
  /// In en, this message translates to:
  /// **'That code does not belong to a current place'**
  String get checkInNotAPlace;

  /// No description provided for @checkInNeedsAPosition.
  ///
  /// In en, this message translates to:
  /// **'Not recorded: turn location on, then scan the code again'**
  String get checkInNeedsAPosition;

  /// No description provided for @checkInCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'This code is no longer valid — look for the new one put up in its place'**
  String get checkInCodeExpired;

  /// No description provided for @checkInPlaceHasNoLocation.
  ///
  /// In en, this message translates to:
  /// **'This place has no location set, so how near you are cannot be checked. Tell the administration.'**
  String get checkInPlaceHasNoLocation;

  /// No description provided for @checkInTooFar.
  ///
  /// In en, this message translates to:
  /// **'You are too far from this place — you must be at it to check in'**
  String get checkInTooFar;

  /// No description provided for @checkInCodesDenied.
  ///
  /// In en, this message translates to:
  /// **'You may not view place codes'**
  String get checkInCodesDenied;

  /// No description provided for @checkInRotateDenied.
  ///
  /// In en, this message translates to:
  /// **'You may not regenerate place codes'**
  String get checkInRotateDenied;

  /// No description provided for @checkInQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Place code'**
  String get checkInQrTitle;

  /// No description provided for @checkInQrHint.
  ///
  /// In en, this message translates to:
  /// **'Print this and fix it at the place — whoever arrives scans it to record their arrival'**
  String get checkInQrHint;

  /// No description provided for @checkInQrPrint.
  ///
  /// In en, this message translates to:
  /// **'Print or share'**
  String get checkInQrPrint;

  /// No description provided for @checkInQrShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get checkInQrShare;

  /// No description provided for @checkInQrCard.
  ///
  /// In en, this message translates to:
  /// **'Check-in code'**
  String get checkInQrCard;

  /// No description provided for @checkInQrRotatedAt.
  ///
  /// In en, this message translates to:
  /// **'Last regenerated: {when}'**
  String checkInQrRotatedAt(String when);

  /// No description provided for @checkInQrNoLocation.
  ///
  /// In en, this message translates to:
  /// **'This place has no location — nobody can check in here until one is set'**
  String get checkInQrNoLocation;

  /// No description provided for @checkInQrRotate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate the code'**
  String get checkInQrRotate;

  /// No description provided for @checkInQrRotateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Every printed code for this place stops working immediately. The new one must be printed and put up before anybody can check in here.'**
  String get checkInQrRotateConfirm;

  /// No description provided for @checkInQrRotated.
  ///
  /// In en, this message translates to:
  /// **'Regenerated — print it and put it up now'**
  String get checkInQrRotated;

  /// No description provided for @checkInQrPrintAll.
  ///
  /// In en, this message translates to:
  /// **'Print the list\'s codes'**
  String get checkInQrPrintAll;

  /// No description provided for @checkInQrPrintingAll.
  ///
  /// In en, this message translates to:
  /// **'Preparing the codes…'**
  String get checkInQrPrintingAll;

  /// No description provided for @presenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance record'**
  String get presenceTitle;

  /// No description provided for @presenceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The latest arrivals across the season\'s places'**
  String get presenceSubtitle;

  /// No description provided for @presenceEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nobody has checked in yet'**
  String get presenceEmpty;

  /// No description provided for @presenceTabPresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get presenceTabPresent;

  /// No description provided for @presenceTabGaps.
  ///
  /// In en, this message translates to:
  /// **'Not checked in'**
  String get presenceTabGaps;

  /// No description provided for @presenceGapsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Every post is confirmed'**
  String get presenceGapsEmpty;

  /// No description provided for @presenceGapsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No post at a place is without a check-in within the chosen window'**
  String get presenceGapsEmptyHint;

  /// No description provided for @presenceGapNeverSeen.
  ///
  /// In en, this message translates to:
  /// **'Never checked in'**
  String get presenceGapNeverSeen;

  /// No description provided for @presenceGapLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {time}'**
  String presenceGapLastSeen(String time);

  /// No description provided for @presenceGapCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{none} =1{1 post} other{{count} posts}}'**
  String presenceGapCount(int count);

  /// No description provided for @presenceEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Whoever scans a place code while standing at it appears here'**
  String get presenceEmptyHint;

  /// No description provided for @presenceWindow4h.
  ///
  /// In en, this message translates to:
  /// **'4 hours'**
  String get presenceWindow4h;

  /// No description provided for @presenceWindow12h.
  ///
  /// In en, this message translates to:
  /// **'12 hours'**
  String get presenceWindow12h;

  /// No description provided for @presenceWindow24h.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get presenceWindow24h;

  /// No description provided for @presenceCounts.
  ///
  /// In en, this message translates to:
  /// **'{people} people in {places} places'**
  String presenceCounts(int people, int places);

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportTitle;

  /// No description provided for @exportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Take any list out as a file — with the columns you choose'**
  String get exportSubtitle;

  /// No description provided for @exportWhat.
  ///
  /// In en, this message translates to:
  /// **'What do you want to export?'**
  String get exportWhat;

  /// No description provided for @exportWhichColumns.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get exportWhichColumns;

  /// No description provided for @exportColumnsDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get exportColumnsDefault;

  /// No description provided for @exportColumnsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get exportColumnsAll;

  /// No description provided for @exportPickAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one column'**
  String get exportPickAtLeastOne;

  /// No description provided for @exportOptionAny.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to include all'**
  String get exportOptionAny;

  /// No description provided for @exportFormat.
  ///
  /// In en, this message translates to:
  /// **'File format'**
  String get exportFormat;

  /// No description provided for @exportFormatCsv.
  ///
  /// In en, this message translates to:
  /// **'CSV (Excel)'**
  String get exportFormatCsv;

  /// No description provided for @exportFormatPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF (for printing)'**
  String get exportFormatPdf;

  /// No description provided for @exportRun.
  ///
  /// In en, this message translates to:
  /// **'Export and share'**
  String get exportRun;

  /// No description provided for @exportRunning.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get exportRunning;

  /// No description provided for @exportDoneRows.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 row exported} other{{count} rows exported}}'**
  String exportDoneRows(int count);

  /// No description provided for @exportNothingMatched.
  ///
  /// In en, this message translates to:
  /// **'Nothing matched — check the options above'**
  String get exportNothingMatched;

  /// No description provided for @exportNothingAvailable.
  ///
  /// In en, this message translates to:
  /// **'There is nothing you can export'**
  String get exportNothingAvailable;

  /// No description provided for @exportNothingAvailableHint.
  ///
  /// In en, this message translates to:
  /// **'Export covers what you are allowed to see'**
  String get exportNothingAvailableHint;

  /// No description provided for @exportGeneratedBy.
  ///
  /// In en, this message translates to:
  /// **'From the Hajj Mission management system'**
  String get exportGeneratedBy;

  /// No description provided for @exportPage.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get exportPage;

  /// No description provided for @accountStatusIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get accountStatusIncomplete;

  /// No description provided for @accountStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get accountStatusPending;

  /// No description provided for @accountStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get accountStatusApproved;

  /// No description provided for @accountStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get accountStatusRejected;

  /// No description provided for @outboxSavedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved on the device — it will be sent when the network returns'**
  String get outboxSavedOffline;

  /// No description provided for @offlineShowingSaved.
  ///
  /// In en, this message translates to:
  /// **'No network — showing a saved copy, last updated {time}'**
  String offlineShowingSaved(String time);

  /// No description provided for @outboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting to be sent'**
  String get outboxTitle;

  /// No description provided for @outboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing is waiting to be sent'**
  String get outboxEmpty;

  /// No description provided for @outboxEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Everything you wrote has reached the server'**
  String get outboxEmptyHint;

  /// No description provided for @outboxPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item waiting to be sent} other{{count} items waiting to be sent}}'**
  String outboxPending(int count);

  /// No description provided for @outboxStateWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a network'**
  String get outboxStateWaiting;

  /// No description provided for @outboxStateSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get outboxStateSending;

  /// No description provided for @outboxStateBlocked.
  ///
  /// In en, this message translates to:
  /// **'Not accepted'**
  String get outboxStateBlocked;

  /// No description provided for @outboxAttempts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attempt} other{{count} attempts}}'**
  String outboxAttempts(int count);

  /// No description provided for @outboxRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get outboxRetry;

  /// No description provided for @outboxDiscard.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get outboxDiscard;

  /// No description provided for @outboxDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this item?'**
  String get outboxDiscardTitle;

  /// No description provided for @outboxDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'It will never reach the server, and cannot be brought back.'**
  String get outboxDiscardBody;

  /// No description provided for @outboxKindTaskState.
  ///
  /// In en, this message translates to:
  /// **'Duty state'**
  String get outboxKindTaskState;

  /// No description provided for @outboxKindReport.
  ///
  /// In en, this message translates to:
  /// **'File report'**
  String get outboxKindReport;

  /// No description provided for @outboxBlockedNotice.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item was not accepted} other{{count} items were not accepted}}'**
  String outboxBlockedNotice(int count);
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
