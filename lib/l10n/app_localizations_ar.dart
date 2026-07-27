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
  String get commonDone => 'إنهاء';

  @override
  String get commonCopied => 'تم النسخ';

  @override
  String get profileEmail => 'البريد الإلكتروني';

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
  String get profileCity => 'المدينة';

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
  String get notificationAttach => 'إرفاق';

  @override
  String get notificationAttachPhoto => 'صورة';

  @override
  String get notificationAttachCamera => 'التقاط صورة';

  @override
  String get notificationAttachVideo => 'فيديو';

  @override
  String get notificationAttachAudio => 'ملف صوتي';

  @override
  String get notificationAttachFile => 'ملف';

  @override
  String notificationAttachmentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مرفقاً',
      few: '$count مرفقات',
      two: 'مرفقان',
      one: 'مرفق واحد',
    );
    return '$_temp0';
  }

  @override
  String get attachmentImage => 'صورة';

  @override
  String get attachmentVideo => 'فيديو';

  @override
  String get attachmentAudio => 'صوت';

  @override
  String get attachmentFile => 'ملف';

  @override
  String get attachmentDownload => 'تحميل';

  @override
  String get attachmentOpenFailed => 'تعذّر فتح المرفق';

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
  String get employeeModulesSection => 'الملفات التشغيلية المُسندة إليه';

  @override
  String get employeeModulesEmpty => 'لم يُسند إلى أي ملف تشغيلي';

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

  @override
  String get commonDelete => 'حذف';

  @override
  String get perm_modules => 'الملفات التشغيلية';

  @override
  String get permModulesManage => 'إنشاء وتعديل وتفعيل الملفات';

  @override
  String get permModulesMembers => 'إسناد أعضاء الملفات';

  @override
  String get permModulesTypes => 'إدارة أنواع الملفات والبيانات المرجعية';

  @override
  String get navModules => 'الملفات التشغيلية';

  @override
  String get navModulesSubtitle => 'ملفات الموسم والأدوار والمهام';

  @override
  String get navReferenceData => 'البيانات المرجعية';

  @override
  String get navReferenceDataSubtitle => 'الفنادق والتكتلات والقوائم الأخرى';

  @override
  String get modulesTitle => 'الملفات التشغيلية';

  @override
  String get modulesEmpty => 'لم يتم إسناد أي ملف إليك بعد';

  @override
  String get modulesEmptyManager => 'لم يتم إنشاء أي ملف بعد';

  @override
  String get moduleActiveSection => 'الملفات المفعّلة';

  @override
  String get moduleDraftSection => 'المسودات';

  @override
  String get moduleBadgeDraft => 'غير مفعّل';

  @override
  String get moduleNew => 'ملف جديد';

  @override
  String get moduleChooseType => 'اختر نوع الملف';

  @override
  String get moduleNoTypes => 'لم يتم تعريف أي نوع ملف بعد';

  @override
  String get moduleAllTypesUsed => 'تم إنشاء جميع أنواع الملفات في هذا الموسم';

  @override
  String get moduleOnePerSeason =>
      'يُنشأ الملف مرة واحدة في الموسم، واسمه هو نوعه';

  @override
  String get moduleSeasonLabel => 'الموسم';

  @override
  String get moduleStartDate => 'تاريخ بدء العمل';

  @override
  String get moduleStartCondition => 'بداية العمل';

  @override
  String get moduleEndCondition => 'نهاية العمل';

  @override
  String get moduleStepInfo => 'الملف';

  @override
  String get moduleStepSectors => 'القطاعات';

  @override
  String get moduleStepTowers => 'الأبراج';

  @override
  String get moduleStepMembers => 'الفريق';

  @override
  String get moduleNodeName => 'الاسم';

  @override
  String moduleNodeAdd(String level) {
    return 'إضافة $level';
  }

  @override
  String moduleNodeEdit(String level) {
    return 'تعديل $level';
  }

  @override
  String moduleNodeDelete(String level) {
    return 'حذف $level';
  }

  @override
  String moduleNodeDeleteConfirm(String name) {
    return 'حذف «$name»؟ سيُحذف كل ما بداخله معه.';
  }

  @override
  String moduleSectorSuggestedName(int number) {
    return 'القطاع $number';
  }

  @override
  String moduleSectorsCount(int count) {
    return '$count قطاعاً';
  }

  @override
  String get moduleNoSectors => 'لم تُضف أي قطاعات بعد';

  @override
  String get moduleSectorsFirst => 'أضف القطاعات أولاً، ثم وزّع الفنادق عليها';

  @override
  String get moduleBuildTree => 'إضافة القطاعات والأبراج';

  @override
  String get moduleNoLevels => 'لم تُعرّف بنية هذا النوع من الملفات بعد';

  @override
  String get moduleSectionInfo => 'معلومات الملف';

  @override
  String get moduleSectionTasks => 'دوري ومهامي';

  @override
  String moduleSectionTasksOf(String name) {
    return '$name — الدور والمهام';
  }

  @override
  String get moduleJobDescription => 'الوصف الوظيفي';

  @override
  String get moduleNoTasks => 'لا توجد مهام معرّفة لهذا الدور بعد';

  @override
  String get moduleAssignedTasks => 'المهام المسندة';

  @override
  String moduleAssignedTasksCount(int count, int total) {
    return '$count من $total مهام';
  }

  @override
  String get moduleNoAssignedTasks => 'لم تُسند إليه مهام بعد';

  @override
  String get moduleNoAssignedTasksMine =>
      'لم تُسند إليك مهام من قائمة هذا الدور بعد';

  @override
  String get moduleTeamPick => 'اختيار الأعضاء';

  @override
  String get moduleNoTeamMembers => 'لم يُختر أعضاء هذا الفريق بعد';

  @override
  String get moduleNoRoles => 'لا توجد أدوار معرّفة لهذا النوع من الملفات بعد';

  @override
  String moduleMembersCount(int count) {
    return '$count عضواً';
  }

  @override
  String get moduleNoMembers => 'لم يُسند أي عضو هنا بعد';

  @override
  String get moduleRoleUnassigned => 'غير مُسند';

  @override
  String get moduleSaved => 'تم الحفظ';

  @override
  String get moduleActivate => 'تفعيل الملف';

  @override
  String get moduleDeactivate => 'إلغاء تفعيل الملف';

  @override
  String get moduleActivated => 'تم تفعيل الملف — وصل الإشعار إلى الأعضاء';

  @override
  String get moduleDeactivated => 'تم إلغاء تفعيل الملف';

  @override
  String get moduleAttachPdf => 'إرفاق ملف PDF';

  @override
  String get moduleReplacePdf => 'استبدال الملف';

  @override
  String get moduleOpenPdf => 'فتح ملف PDF';

  @override
  String get moduleNoPdf => 'لا يوجد ملف مرفق';

  @override
  String get modulePdfOpenFailed => 'تعذّر فتح الملف';

  @override
  String get moduleDelete => 'حذف الملف';

  @override
  String get moduleDeleteConfirm =>
      'حذف هذا الملف؟ سيُحذف كل ما فيه — أعضاؤه ومهامهم المسندة ومرفقاته — معه.';

  @override
  String get moduleDeleted => 'تم حذف الملف';

  @override
  String get moduleNoCurrentSeason => 'حدّد الموسم الحالي قبل إنشاء الملفات';

  @override
  String get moduleNoParticipants => 'لا يوجد مشاركون في الموسم الحالي بعد';

  @override
  String get moduleContactSy => 'الرقم السوري';

  @override
  String get moduleContactSa => 'الرقم السعودي';

  @override
  String get modulePickerSearchHint => 'ابحث بالاسم أو الاختصاص الوظيفي';

  @override
  String get modulePickerAll => 'الجميع';

  @override
  String get modulePickerInternal => 'من البعثة';

  @override
  String get modulePickerExternal => 'من خارج البعثة';

  @override
  String get modulePickerNoMatches => 'لا أحد يطابق البحث';

  @override
  String get modulePickerFree => 'غير مُسند إلى أي ملف';

  @override
  String modulePickerAlreadyIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مُسند إلى $count ملفاً',
      few: 'مُسند إلى $count ملفات',
      two: 'مُسند إلى ملفين',
      one: 'مُسند إلى ملف واحد',
    );
    return '$_temp0';
  }

  @override
  String modulePickerConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تأكيد اختيار $count شخصاً',
      few: 'تأكيد اختيار $count أشخاص',
      two: 'تأكيد اختيار شخصين',
      one: 'تأكيد اختيار شخص واحد',
      zero: 'تأكيد بلا اختيار',
    );
    return '$_temp0';
  }

  @override
  String get referenceDataTitle => 'البيانات المرجعية';

  @override
  String referenceItemsCount(int count) {
    return '$count عنصراً';
  }

  @override
  String get referenceAddItem => 'إضافة عنصر';

  @override
  String get referenceItemName => 'الاسم (بالعربية)';

  @override
  String get referenceItemNameEn => 'الاسم (بالإنكليزية)';

  @override
  String get referenceItemSaved => 'تم حفظ العنصر';

  @override
  String get referenceItemDeleted => 'تم حذف العنصر';

  @override
  String get referenceEmpty => 'لا توجد عناصر بعد';

  @override
  String referenceDeleteConfirm(String name) {
    return 'حذف «$name»؟';
  }

  @override
  String get referenceInUse => 'هذا العنصر مستخدم في أحد الملفات ولا يمكن حذفه';

  @override
  String get referenceDuplicate => 'يوجد عنصر بهذا الاسم في القائمة بالفعل';

  @override
  String get referenceOpenLink => 'فتح الرابط';

  @override
  String get locationPickerTitle => 'تحديد الموقع';

  @override
  String get locationPickOnMap => 'من الخريطة';

  @override
  String get locationUseCurrent => 'موقعي الحالي';

  @override
  String get locationOrPasteLink => 'أو الصق رابط الموقع';

  @override
  String get locationTapToPlace => 'اضغط على الخريطة لتحديد الموقع';

  @override
  String get locationConfirm => 'تأكيد هذا الموقع';

  @override
  String get locationCaptured => 'تم التقاط الموقع الحالي';

  @override
  String get locationPermissionDenied => 'لم يُسمح بالوصول إلى الموقع';

  @override
  String get locationServiceDisabled => 'خدمة الموقع مغلقة في الجهاز';

  @override
  String get locationFailed => 'تعذّر تحديد موقعك';

  @override
  String get locationOpenMap => 'فتح على الخريطة';

  @override
  String get referenceCall => 'اتصال';

  @override
  String get referenceLinkFailed => 'تعذّر فتح الرابط';

  @override
  String get referenceDetailsTitle => 'التفاصيل';
}
