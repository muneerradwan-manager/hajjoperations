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
  /// **'Log out of this device?'**
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
  /// **'Operational modules'**
  String get perm_modules;

  /// No description provided for @permModulesManage.
  ///
  /// In en, this message translates to:
  /// **'Create, edit & activate modules'**
  String get permModulesManage;

  /// No description provided for @permModulesMembers.
  ///
  /// In en, this message translates to:
  /// **'Assign module members'**
  String get permModulesMembers;

  /// No description provided for @permModulesTypes.
  ///
  /// In en, this message translates to:
  /// **'Manage module types & master data'**
  String get permModulesTypes;

  /// No description provided for @navModules.
  ///
  /// In en, this message translates to:
  /// **'Operational modules'**
  String get navModules;

  /// No description provided for @navModulesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Season files, roles and tasks'**
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

  /// No description provided for @moduleReportBody.
  ///
  /// In en, this message translates to:
  /// **'The report'**
  String get moduleReportBody;

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

  /// No description provided for @moduleSectorSuggestedName.
  ///
  /// In en, this message translates to:
  /// **'Sector {number}'**
  String moduleSectorSuggestedName(int number);

  /// No description provided for @moduleSectorsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sectors'**
  String moduleSectorsCount(int count);

  /// No description provided for @moduleNoSectors.
  ///
  /// In en, this message translates to:
  /// **'No sectors have been added yet'**
  String get moduleNoSectors;

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
