// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'إدارة الحج والعمرة';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonSubmit => 'إرسال';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonLogout => 'تسجيل الخروج';

  @override
  String get commonRequired => 'مطلوب';

  @override
  String get commonLoading => 'جارٍ التحميل…';

  @override
  String get commonOptional => 'اختياري';

  @override
  String get commonNext => 'التالي';

  @override
  String get commonBack => 'رجوع';

  @override
  String get commonEdit => 'تعديل';

  @override
  String get commonSettings => 'الإعدادات';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsTheme => 'المظهر';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get authLoginTitle => 'مرحباً بعودتك';

  @override
  String get authLoginSubtitle => 'سجّل الدخول للمتابعة';

  @override
  String get authRegisterTitle => 'إنشاء حساب';

  @override
  String get authRegisterSubtitle => 'سجّل ببريدك الإلكتروني للبدء';

  @override
  String get authEmail => 'البريد الإلكتروني';

  @override
  String get authPassword => 'كلمة المرور';

  @override
  String get authConfirmPassword => 'تأكيد كلمة المرور';

  @override
  String get authSignIn => 'تسجيل الدخول';

  @override
  String get authSignUp => 'إنشاء حساب';

  @override
  String get authOrContinueWith => 'أو';

  @override
  String get authGoogle => 'المتابعة عبر Google';

  @override
  String get authHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get authNoAccount => 'ليس لديك حساب؟';

  @override
  String get authInvalidEmail => 'أدخل بريداً إلكترونياً صحيحاً';

  @override
  String get authPasswordTooShort => 'يجب أن تكون كلمة المرور 8 أحرف على الأقل';

  @override
  String get authPasswordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get authCheckEmail =>
      'تحقق من بريدك الإلكتروني لتأكيد حسابك ثم سجّل الدخول.';

  @override
  String get profileCompleteTitle => 'أكمل ملفك الشخصي';

  @override
  String get profileCompleteSubtitle => 'املأ بياناتك لإرسالها للاعتماد';

  @override
  String get profileFirstName => 'الاسم الأول';

  @override
  String get profileSurname => 'الكنية';

  @override
  String get profileFatherName => 'اسم الأب';

  @override
  String get profilePhoto => 'الصورة الشخصية';

  @override
  String get profileJobTitle => 'الوصف الوظيفي';

  @override
  String get profileGender => 'الجنس';

  @override
  String get profileDateOfBirth => 'تاريخ الميلاد';

  @override
  String get profileMissionType => 'نوع البعثة';

  @override
  String get profilePhoneSy => 'رقم الهاتف السوري';

  @override
  String get profilePhoneSa => 'رقم الهاتف السعودي';

  @override
  String get profilePassportPhoto => 'صورة جواز السفر';

  @override
  String get profileVisaPhoto => 'صورة التأشيرة';

  @override
  String get profileNusukPhoto => 'صورة بطاقة نسك';

  @override
  String get profileDocumentsSection => 'المستندات (اختياري)';

  @override
  String get profilePickImage => 'اختر صورة';

  @override
  String get profileChangeImage => 'تغيير';

  @override
  String get profileSelectDate => 'اختر التاريخ';

  @override
  String get profileSubmitForApproval => 'إرسال للاعتماد';

  @override
  String get profileCamera => 'الكاميرا';

  @override
  String get profileGallery => 'معرض الصور';

  @override
  String get genderMale => 'ذكر';

  @override
  String get genderFemale => 'أنثى';

  @override
  String get missionAdministrative => 'البعثة الإدارية';

  @override
  String get missionReligious => 'البعثة الدينية';

  @override
  String get missionMedical => 'البعثة الطبية';

  @override
  String get statusPendingTitle => 'قيد الانتظار';

  @override
  String get statusPendingMessage =>
      'حسابك قيد المراجعة. ستحصل على صلاحية الدخول بمجرد اعتماده من قبل المدير.';

  @override
  String get statusRejectedTitle => 'لم يتم اعتماد الحساب';

  @override
  String get statusRejectedMessage => 'لم تتم الموافقة على حسابك.';

  @override
  String statusRejectedReason(String reason) {
    return 'السبب: $reason';
  }

  @override
  String get statusEditAndResubmit => 'تعديل وإعادة الإرسال';

  @override
  String get statusSuspendedTitle => 'الحساب موقوف';

  @override
  String get statusSuspendedMessage =>
      'تم إيقاف حسابك. يرجى التواصل مع المدير.';

  @override
  String get homeTitle => 'الرئيسية';

  @override
  String homeWelcome(String name) {
    return 'مرحباً، $name';
  }

  @override
  String get homeAdminSection => 'الإدارة';

  @override
  String get homeGeneralSection => 'عام';

  @override
  String get navApprovals => 'اعتماد الحسابات';

  @override
  String get navApprovalsSubtitle => 'مراجعة طلبات التسجيل المعلّقة';

  @override
  String get navMyProfile => 'ملفي الشخصي';

  @override
  String get approvalQueueTitle => 'الحسابات قيد الانتظار';

  @override
  String get approvalEmpty => 'لا توجد حسابات بانتظار الاعتماد';

  @override
  String approvalPendingCount(int count) {
    return '$count قيد الانتظار';
  }

  @override
  String get approvalDetailTitle => 'مراجعة الحساب';

  @override
  String get approvalApprove => 'اعتماد';

  @override
  String get approvalReject => 'رفض';

  @override
  String get approvalRejectReasonTitle => 'سبب الرفض';

  @override
  String get approvalRejectReasonHint => 'اختياري — يظهر لمقدّم الطلب';

  @override
  String get approvalApproved => 'تم اعتماد الحساب';

  @override
  String get approvalRejected => 'تم رفض الحساب';

  @override
  String get profileSectionPersonal => 'المعلومات الشخصية';

  @override
  String get profileSectionContact => 'معلومات التواصل';

  @override
  String get profileSectionDocuments => 'المستندات';

  @override
  String get profileBadgeExternal => 'خارجي';

  @override
  String get profileBadgeAdmin => 'مدير';

  @override
  String get profileFieldNotProvided => 'غير مرفق';

  @override
  String get profileNoPhone => '—';

  @override
  String get navPermissions => 'الصلاحيات';

  @override
  String get navPermissionsSubtitle => 'منح الصلاحيات للموظفين';

  @override
  String get permissionsEmployeesTitle => 'الموظفون';

  @override
  String get permissionEditorTitle => 'الصلاحيات';

  @override
  String get employeesEmpty => 'لا يوجد موظفون بعد';

  @override
  String get permissionSaved => 'تم تحديث الصلاحيات';

  @override
  String permissionGrantedCount(int count, int total) {
    return '$count من $total صلاحية';
  }

  @override
  String get commonSearch => 'بحث';

  @override
  String get commonSelectAll => 'تحديد الكل';

  @override
  String get permAllGranted => 'صلاحيات كاملة (مدير)';

  @override
  String get perm_employees => 'الموظفون';

  @override
  String get perm_approvals => 'اعتماد الحسابات';

  @override
  String get perm_seasons => 'المواسم';

  @override
  String get perm_permissions => 'الصلاحيات';

  @override
  String get permEmployeesView => 'عرض الموظفين وتفاصيلهم';

  @override
  String get permEmployeesCreate => 'إضافة موظف';

  @override
  String get permEmployeesSuspend => 'إيقاف/تفعيل الحسابات';

  @override
  String get permEmployeesExternal => 'إدارة الصفة الخارجية';

  @override
  String get permEmployeesDocuments => 'عرض المستندات';

  @override
  String get permApprovalsDecide => 'قبول ورفض الحسابات';

  @override
  String get permSeasonsManage => 'إدارة المواسم';

  @override
  String get permSeasonsParticipants => 'إدارة المشاركين';

  @override
  String get permPermissionsManage => 'منح وسحب الصلاحيات';

  @override
  String get perm_notifications => 'الإشعارات';

  @override
  String get permNotificationsSend => 'إرسال الإشعارات';

  @override
  String get navNotifications => 'الإشعارات';

  @override
  String get notificationsEmpty => 'لا توجد إشعارات بعد';

  @override
  String get notificationSend => 'إرسال إشعار';

  @override
  String get notificationTitleField => 'العنوان';

  @override
  String get notificationBodyField => 'الرسالة';

  @override
  String get notificationSent => 'تم إرسال الإشعار';

  @override
  String get notificationMarkAllRead => 'تعليم الكل كمقروء';

  @override
  String get navSeasons => 'المواسم';

  @override
  String get navSeasonsSubtitle => 'الموسم الحالي والأرشيف';

  @override
  String get seasonsTitle => 'المواسم';

  @override
  String get seasonCurrentLabel => 'الموسم الحالي';

  @override
  String get seasonUpcomingLabel => 'المواسم القادمة';

  @override
  String get seasonArchiveLabel => 'المواسم السابقة';

  @override
  String seasonHijriYear(int year) {
    return '$year هـ';
  }

  @override
  String get seasonBadgeCurrent => 'حالي';

  @override
  String get seasonParticipantsTitle => 'المشاركون';

  @override
  String seasonParticipantsCount(int count) {
    return '$count مشارك';
  }

  @override
  String get seasonManageParticipants => 'إدارة المشاركين';

  @override
  String get seasonNoParticipants => 'لا يوجد مشاركون في هذا الموسم بعد';

  @override
  String get seasonSetCurrent => 'تعيين كموسم حالي';

  @override
  String get seasonSetCurrentDone => 'تم تحديث الموسم الحالي';

  @override
  String get seasonArchiveEmpty => 'لا توجد مواسم سابقة';

  @override
  String get seasonSelectParticipants => 'اختيار المشاركين';

  @override
  String get seasonParticipantsSaved => 'تم تحديث المشاركين';

  @override
  String get navEmployees => 'الموظفون';

  @override
  String get navEmployeesSubtitle => 'دليل الموظفين والخارجيين';

  @override
  String get employeesPermanentSection => 'الموظفون الدائمون';

  @override
  String get employeesExternalSection => 'الموظفون الخارجيون';

  @override
  String get employeesExternalEmpty => 'لا يوجد موظفون خارجيون';

  @override
  String get employeeDetailTitle => 'الموظف';

  @override
  String get employeeEditExternalTitle => 'الصفة الخارجية';

  @override
  String get employeeIsExternal => 'موظف خارجي';

  @override
  String get employeeIsExternalHint =>
      'من جهة حكومية أخرى — ليس من الموظفين الدائمين';

  @override
  String get employeeOrganization => 'الجهة / الوزارة';

  @override
  String get employeeExternalRole => 'المسمى الوظيفي لدى الجهة';

  @override
  String get employeeExternalSaved => 'تم تحديث بيانات الموظف';

  @override
  String get employeeSectionOrganization => 'الجهة';

  @override
  String get employeeSeasonsSection => 'المواسم التي شارك بها';

  @override
  String get employeeSeasonsEmpty => 'لم يشارك في أي موسم بعد';

  @override
  String get employeeSeasonBadgeCurrent => 'حالي';

  @override
  String get navMyProfileSubtitle => 'عرض وتعديل بياناتك';

  @override
  String get myProfileEdit => 'تعديل الملف';

  @override
  String get myProfileChangePassword => 'تغيير كلمة المرور';

  @override
  String get myProfileNewPassword => 'كلمة المرور الجديدة';

  @override
  String get myProfileConfirmPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get myProfilePasswordChanged => 'تم تغيير كلمة المرور';

  @override
  String get myProfileSaved => 'تم تحديث الملف';

  @override
  String get myProfileEditTitle => 'تعديل الملف';

  @override
  String get createEmployeeTitle => 'إنشاء موظف';

  @override
  String get createEmployeeCreated => 'تم إنشاء الموظف';

  @override
  String get createEmployeeAccountSection => 'بيانات الحساب';

  @override
  String get createEmployeeSubmit => 'إنشاء الحساب';
}
