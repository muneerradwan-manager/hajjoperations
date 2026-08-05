import '../../../core/constants/permission_codes.dart';
import '../../../core/l10n/localized_name.dart';
import '../../complaints/data/complaints_repository.dart';
import '../../complaints/presentation/widgets/complaint_labels.dart';
import '../../employees/data/employees_repository.dart';
import '../../evaluations/data/evaluations_repository.dart';
import '../../evaluations/presentation/widgets/evaluation_labels.dart';
import '../../modules/data/modules_repository.dart';
import '../../modules/domain/module_task.dart';
import '../../profile/domain/profile.dart';
import '../../profile/domain/profile_enums.dart';
import '../../reports/data/reports_repository.dart';
import '../../seasons/data/seasons_repository.dart';
import '../domain/export_dataset.dart';
import 'export_values.dart';

LocalizedName _n(String ar, String en) => LocalizedName(ar: ar, en: en);

/// Every kind of thing this app can hand over as a file.
///
/// One catalogue rather than an export button per screen, and the difference is
/// not tidiness. A button on a screen exports WHAT THAT SCREEN HAPPENS TO BE
/// SHOWING — the filter someone left on, the hundred rows that had loaded — and
/// the person receiving the file cannot tell which of those it was. A dataset
/// says what it fetches, is asked for its rows directly, and can be read.
///
/// Nothing here widens what anybody can see. Every fetch goes through the same
/// repository the screen uses, so row security narrows an export exactly as it
/// narrows a page; [ExportDataset.permission] only decides whether the dataset
/// is OFFERED. A person who exports the employees gets the employees he could
/// already have scrolled through, in a file instead of on a screen.
abstract final class ExportCatalog {
  static final List<ExportDataset> all = [
    _EmployeesDataset(),
    _SeasonParticipantsDataset(),
    _ModulesDataset(),
    _ModuleMembersDataset(),
    _ModuleTasksDataset(),
    _ReferenceItemsDataset(),
    _ReportsDataset(),
    _ComplaintsDataset(),
    _EvaluationsDataset(),
  ];

  /// What this reader may be offered. The catalogue is not a menu of everything
  /// that exists — a section somebody cannot open is a section he cannot export.
  static List<ExportDataset> visibleTo({
    required bool isAdmin,
    required Set<String> permissions,
  }) => [
    for (final dataset in all)
      if (dataset.permission == null ||
          isAdmin ||
          permissions.contains(dataset.permission))
        dataset,
  ];

  static ExportDataset? byId(String id) {
    for (final dataset in all) {
      if (dataset.id == id) return dataset;
    }
    return null;
  }
}

// ---------------------------------------------------------------- the people

/// The columns a person has, shared by the two datasets that list people.
///
/// Written once because they must not drift: an export of the permanent staff
/// and an export of a season's participants that disagree about what "المهنة"
/// means are two files nobody can put side by side.
List<ExportColumn> _profileColumns() => [
  ExportColumn(key: 'full_name', label: _n('الاسم الكامل', 'Full name')),
  ExportColumn(key: 'first_name', label: _n('الاسم', 'First name'), byDefault: false),
  ExportColumn(key: 'father_name', label: _n('اسم الأب', 'Father name'), byDefault: false),
  ExportColumn(key: 'surname', label: _n('الكنية', 'Surname'), byDefault: false),
  ExportColumn(key: 'job_title', label: _n('المهنة', 'Job title')),
  ExportColumn(key: 'mission_type', label: _n('نوع البعثة', 'Mission type')),
  ExportColumn(key: 'email', label: _n('البريد الإلكتروني', 'Email')),
  ExportColumn(key: 'phone_sy', label: _n('الهاتف (سوريا)', 'Phone (SY)')),
  ExportColumn(key: 'phone_sa', label: _n('الهاتف (السعودية)', 'Phone (SA)')),
  ExportColumn(key: 'city', label: _n('المدينة', 'City'), byDefault: false),
  ExportColumn(key: 'gender', label: _n('الجنس', 'Gender'), byDefault: false),
  ExportColumn(key: 'date_of_birth', label: _n('تاريخ الميلاد', 'Date of birth'), byDefault: false),
  ExportColumn(key: 'is_external', label: _n('خارجي', 'External'), byDefault: false),
  ExportColumn(key: 'external_organization', label: _n('الجهة', 'Organization'), byDefault: false),
  ExportColumn(key: 'external_title', label: _n('الصفة', 'Title'), byDefault: false),
  ExportColumn(key: 'account_status', label: _n('حالة الحساب', 'Account status'), byDefault: false),
  ExportColumn(key: 'is_suspended', label: _n('موقوف', 'Suspended'), byDefault: false),
  ExportColumn(key: 'id', label: _n('المعرّف', 'Id'), byDefault: false),
];

Map<String, String> _profileRow(Profile profile, ExportRequest request) {
  final l = request.l;
  return {
    'full_name': profile.fullName,
    'first_name': ExportValues.text(profile.firstName),
    'father_name': ExportValues.text(profile.fatherName),
    'surname': ExportValues.text(profile.surname),
    'job_title': request.text(profile.jobTitleName),
    'mission_type': request.text(profile.missionTypeName),
    'email': ExportValues.text(profile.email),
    'phone_sy': ExportValues.text(profile.phoneSy),
    'phone_sa': ExportValues.text(profile.phoneSa),
    'city': request.text(profile.cityName),
    'gender': switch (profile.gender) {
      Gender.male => l.genderMale,
      Gender.female => l.genderFemale,
      null => '',
    },
    'date_of_birth': ExportValues.date(profile.dateOfBirth),
    'is_external': ExportValues.yesNo(l, profile.isExternal),
    'external_organization': ExportValues.text(profile.externalOrganization),
    'external_title': ExportValues.text(profile.externalTitle),
    'account_status': switch (profile.accountStatus) {
      AccountStatus.incomplete => l.accountStatusIncomplete,
      AccountStatus.pending => l.accountStatusPending,
      AccountStatus.approved => l.accountStatusApproved,
      AccountStatus.rejected => l.accountStatusRejected,
    },
    'is_suspended': ExportValues.yesNo(l, profile.isSuspended),
    'id': profile.id,
  };
}

class _EmployeesDataset extends ExportDataset {
  @override
  String get id => 'employees';

  @override
  LocalizedName get name => _n('الموظفون', 'Employees');

  @override
  String? get permission => PermissionCodes.employeesView;

  @override
  List<ExportColumn> get columns => _profileColumns();

  @override
  List<ExportOption> get options => [
    ExportOption(
      key: 'kind',
      label: _n('من يُصدَّر', 'Who'),
      choices: () async => [
        ExportChoice(id: 'permanent', label: _n('الملاك الدائم', 'Permanent staff')),
        ExportChoice(id: 'external', label: _n('الخارجيون', 'External')),
        ExportChoice(id: 'both', label: _n('الجميع', 'Everyone')),
      ],
    ),
    _seasonOption(
      label: _n('الموسم (للخارجيين)', 'Season (for external)'),
      required: false,
    ),
  ];

  @override
  Future<List<Map<String, String>>> fetch(ExportRequest request) async {
    final repo = EmployeesRepository();
    final kind = request.option('kind') ?? 'permanent';
    final seasonId = request.option('season');

    final people = <Profile>[
      if (kind != 'external') ...await repo.fetchPermanent(),
      // An external belongs to a season rather than to the mission, which is
      // why the season is offered here and why leaving it off lists everyone
      // who has ever been one.
      if (kind != 'permanent') ...await repo.fetchExternal(seasonId: seasonId),
    ];

    return [for (final person in people) _profileRow(person, request)];
  }
}

class _SeasonParticipantsDataset extends ExportDataset {
  @override
  String get id => 'season_participants';

  @override
  LocalizedName get name => _n('مشاركو الموسم', 'Season participants');

  @override
  String? get permission => PermissionCodes.seasonsParticipantsView;

  @override
  List<ExportColumn> get columns => _profileColumns();

  @override
  List<ExportOption> get options => [_seasonOption()];

  @override
  Future<List<Map<String, String>>> fetch(ExportRequest request) async {
    final seasonId = request.option('season');
    if (seasonId == null) return [];
    final people = await SeasonsRepository().fetchParticipants(seasonId);
    return [for (final person in people) _profileRow(person, request)];
  }
}

// ------------------------------------------------------- the files and their

class _ModulesDataset extends ExportDataset {
  @override
  String get id => 'modules';

  @override
  LocalizedName get name => _n('الملفات التشغيلية', 'Operational files');

  @override
  String? get permission => null;

  @override
  List<ExportColumn> get columns => [
    ExportColumn(key: 'type', label: _n('نوع الملف', 'File type')),
    ExportColumn(key: 'season', label: _n('الموسم', 'Season')),
    ExportColumn(key: 'decision_number', label: _n('رقم القرار', 'Decision number')),
    ExportColumn(key: 'starts_on', label: _n('تاريخ البدء', 'Starts on')),
    ExportColumn(key: 'ends_on', label: _n('تاريخ الانتهاء', 'Ends on')),
    ExportColumn(key: 'is_active', label: _n('مُفعَّل', 'Active')),
    ExportColumn(key: 'is_running', label: _n('قائم', 'Running'), byDefault: false),
    ExportColumn(key: 'report_cadence', label: _n('دورية التقرير', 'Report cadence'), byDefault: false),
    ExportColumn(key: 'id', label: _n('المعرّف', 'Id'), byDefault: false),
  ];

  @override
  List<ExportOption> get options => [_seasonOption(required: false)];

  @override
  Future<List<Map<String, String>>> fetch(ExportRequest request) async {
    final modules = await ModulesRepository().fetchModules(
      seasonId: request.option('season'),
    );
    final l = request.l;
    return [
      for (final module in modules)
        {
          'type': request.text(module.moduleTypeName),
          'season': module.seasonHijriYear?.toString() ?? '',
          'decision_number': ExportValues.text(module.decisionNumber),
          'starts_on': ExportValues.date(module.startsOn),
          'ends_on': ExportValues.date(module.endsOn),
          'is_active': ExportValues.yesNo(l, module.isActive),
          'is_running': ExportValues.yesNo(l, module.isRunning),
          'report_cadence': module.reportCadence.name,
          'id': module.id,
        },
    ];
  }
}

class _ModuleMembersDataset extends ExportDataset {
  @override
  String get id => 'module_members';

  @override
  LocalizedName get name => _n('أعضاء ملف تشغيلي', 'Members of a file');

  @override
  String? get permission => null;

  @override
  List<ExportColumn> get columns => [
    ExportColumn(key: 'name', label: _n('الاسم', 'Name')),
    ExportColumn(key: 'job_title', label: _n('المهنة', 'Job title')),
    ExportColumn(key: 'phone_sa', label: _n('الهاتف (السعودية)', 'Phone (SA)')),
    ExportColumn(key: 'phone_sy', label: _n('الهاتف (سوريا)', 'Phone (SY)'), byDefault: false),
    ExportColumn(key: 'email', label: _n('البريد الإلكتروني', 'Email'), byDefault: false),
    ExportColumn(key: 'profile_id', label: _n('معرّف الموظف', 'Employee id'), byDefault: false),
  ];

  @override
  List<ExportOption> get options => [_moduleOption()];

  @override
  Future<List<Map<String, String>>> fetch(ExportRequest request) async {
    final moduleId = request.option('module');
    if (moduleId == null) return [];

    final repo = ModulesRepository();
    // Both halves: a man may hold a post on the file itself or at one of its
    // towers, and a roster missing either is a roster of half the file.
    final members = await repo.fetchMembers(moduleId);
    final nodes = await repo.fetchNodes(moduleId);
    final everyone = [
      ...members,
      for (final node in nodes) ...node.members,
    ];

    return [
      for (final member in everyone)
        {
          'name': member.profile?.fullName ?? '',
          'job_title': request.text(member.profile?.jobTitleName),
          'phone_sa': ExportValues.text(member.profile?.phoneSa),
          'phone_sy': ExportValues.text(member.profile?.phoneSy),
          'email': ExportValues.text(member.profile?.email),
          'profile_id': member.profileId,
        },
    ];
  }
}

class _ModuleTasksDataset extends ExportDataset {
  @override
  String get id => 'module_tasks';

  @override
  LocalizedName get name => _n('مهام ملف تشغيلي', 'Duties of a file');

  @override
  String? get permission => null;

  @override
  List<ExportColumn> get columns => [
    ExportColumn(key: 'title', label: _n('المهمة', 'Duty')),
    ExportColumn(key: 'state', label: _n('الحالة', 'State')),
    ExportColumn(key: 'scope', label: _n('النطاق', 'Scope')),
    ExportColumn(key: 'due_on', label: _n('تاريخ الاستحقاق', 'Due on')),
    ExportColumn(key: 'note', label: _n('الملاحظة', 'Note')),
    ExportColumn(key: 'updated_by', label: _n('آخر من حدّثها', 'Last updated by')),
    ExportColumn(key: 'updated_at', label: _n('تاريخ التحديث', 'Updated at')),
    ExportColumn(key: 'attachments', label: _n('عدد المرفقات', 'Attachments'), byDefault: false),
    ExportColumn(key: 'description', label: _n('الوصف', 'Description'), byDefault: false),
  ];

  @override
  List<ExportOption> get options => [_moduleOption()];

  @override
  Future<List<Map<String, String>>> fetch(ExportRequest request) async {
    final moduleId = request.option('module');
    if (moduleId == null) return [];

    // `all` on purpose: an export of "the duties of this file" that quietly
    // meant "mine" would be read as the file's state by whoever received it.
    // What the reader may not see, the database withholds anyway.
    final lines = await ModulesRepository().fetchTaskBoard(
      moduleId: moduleId,
      all: true,
    );
    final l = request.l;

    return [
      for (final line in lines)
        {
          'title': request.text(line.title),
          'state': switch (line.state) {
            TaskState.notStarted => l.taskStateNotStarted,
            TaskState.inProgress => l.taskStateInProgress,
            TaskState.done => l.taskStateDone,
          },
          'scope': switch (line.scope) {
            TaskScope.file => l.moduleTaskScopeFile,
            TaskScope.role => l.moduleTaskScopeRole,
            TaskScope.personal => l.moduleTaskScopePersonal,
          },
          'due_on': ExportValues.date(line.dueOn),
          'note': ExportValues.text(line.note),
          'updated_by': ExportValues.text(line.updatedByName),
          'updated_at': ExportValues.moment(line.updatedAt),
          'attachments': ExportValues.number(line.attachments.length),
          'description': request.text(line.description),
        },
    ];
  }
}

/// The master-data lists — التكتلات, the hotels, the camps, the groups.
///
/// One dataset with the list as an option rather than one dataset per list:
/// the sets are content, added by the Administration during a season, and a
/// catalogue that had to be edited to export a new one would be a catalogue
/// that is always one list behind.
class _ReferenceItemsDataset extends ExportDataset {
  @override
  String get id => 'reference_items';

  @override
  LocalizedName get name => _n('البيانات المرجعية', 'Master data');

  @override
  String? get permission => PermissionCodes.referenceView;

  @override
  List<ExportColumn> get columns => [
    ExportColumn(key: 'name', label: _n('الاسم', 'Name')),
    ExportColumn(key: 'is_active', label: _n('مُفعَّل', 'Active')),
    ExportColumn(key: 'sort_order', label: _n('الترتيب', 'Order'), byDefault: false),
    ExportColumn(key: 'id', label: _n('المعرّف', 'Id'), byDefault: false),
  ];

  @override
  List<ExportOption> get options => [
    ExportOption(
      key: 'set',
      label: _n('القائمة', 'List'),
      choices: () async {
        final sets = await ModulesRepository().fetchReferenceSets();
        return [
          for (final set in sets) ExportChoice(id: set.id, label: set.name),
        ];
      },
    ),
    _seasonOption(required: false),
  ];

  @override
  Future<List<ExportColumn>> extraColumns(Map<String, String> options) async {
    final setId = options['set'];
    if (setId == null) return const [];
    final sets = await ModulesRepository().fetchReferenceSets(activeOnly: false);
    final set = sets.where((candidate) => candidate.id == setId).firstOrNull;
    if (set == null) return const [];
    return [
      for (final field in set.fields)
        ExportColumn(
          key: 'field_${field.key}',
          label: field.label,
          byDefault: false,
        ),
    ];
  }

  @override
  Future<List<Map<String, String>>> fetch(ExportRequest request) async {
    final setId = request.option('set');
    if (setId == null) return [];

    // `activeOnly: false`: an export carries what is there and SAYS which
    // entries are switched off, in its own column. Silently dropping them would
    // make a list of forty hotels read as a list of thirty-one.
    final sets = await ModulesRepository().fetchReferenceSets(activeOnly: false);
    final set = sets.where((candidate) => candidate.id == setId).firstOrNull;
    if (set == null) return [];
    final l = request.l;

    // The season is a property of each ENTRY, not of the query: a set that is
    // season-scoped holds a separate row per season, and one that is not holds
    // rows belonging to no season at all. Filtering the second kind by season
    // would return nothing and look like an empty list.
    final seasonId = request.option('season');
    final items = (set.isSeasonScoped && seasonId != null)
        ? set.items.where((item) => item.seasonId == seasonId).toList()
        : set.items;

    // A set carries its own extra fields — a hotel has a capacity, a camp has a
    // location — and they are exported as their own columns rather than
    // flattened into one. See [dynamicColumns].
    return [
      for (final item in items)
        {
          'name': request.text(item.name),
          'is_active': ExportValues.yesNo(l, item.isActive),
          'sort_order': ExportValues.number(item.sortOrder),
          'id': item.id,
          for (final field in set.fields)
            'field_${field.key}': _fieldValue(item.data[field.key]),
        },
    ];
  }

  static String _fieldValue(Object? value) => switch (value) {
    null => '',
    final Map<String, dynamic> map =>
      // A location, a stored file — the label is what a reader wants, not the
      // JSON it is kept as.
      (map['name'] ?? map['label'] ?? map['address'] ?? '').toString(),
    final List<dynamic> list => list.join(' / '),
    _ => value.toString(),
  };
}

// --------------------------------------------------------------- the records

class _ReportsDataset extends ExportDataset {
  @override
  String get id => 'reports';

  @override
  LocalizedName get name => _n('التقارير المركزية', 'Central reports');

  @override
  String? get permission => null;

  @override
  List<ExportColumn> get columns => [
    ExportColumn(key: 'title', label: _n('العنوان', 'Title')),
    ExportColumn(key: 'number', label: _n('الرقم', 'Number')),
    ExportColumn(key: 'type', label: _n('النوع', 'Type')),
    ExportColumn(key: 'season', label: _n('الموسم', 'Season')),
    ExportColumn(key: 'is_published', label: _n('منشور', 'Published')),
    ExportColumn(key: 'updated_at', label: _n('آخر تحديث', 'Last updated')),
    ExportColumn(key: 'id', label: _n('المعرّف', 'Id'), byDefault: false),
  ];

  @override
  List<ExportOption> get options => [_seasonOption(required: false)];

  @override
  Future<List<Map<String, String>>> fetch(ExportRequest request) async {
    final reports = await ReportsRepository().fetchReports(
      seasonId: request.option('season'),
    );
    final l = request.l;
    return [
      for (final report in reports)
        {
          'title': report.title,
          'number': ExportValues.text(report.number),
          'type': request.text(report.typeName),
          'season': report.seasonHijriYear?.toString() ?? '',
          'is_published': ExportValues.yesNo(l, report.isPublished),
          'updated_at': ExportValues.moment(report.updatedAt),
          'id': report.id,
        },
    ];
  }
}

class _ComplaintsDataset extends ExportDataset {
  @override
  String get id => 'complaints';

  @override
  LocalizedName get name => _n('الشكاوى', 'Complaints');

  @override
  String? get permission => PermissionCodes.complaintsView;

  @override
  List<ExportColumn> get columns => [
    ExportColumn(key: 'created_at', label: _n('تاريخ التقديم', 'Filed at')),
    ExportColumn(key: 'target', label: _n('الشكوى على', 'Complaint about')),
    ExportColumn(key: 'target_label', label: _n('الجهة', 'Subject')),
    ExportColumn(key: 'body', label: _n('النص', 'Body')),
    ExportColumn(key: 'complainant', label: _n('المشتكي', 'Complainant')),
    ExportColumn(key: 'is_locked', label: _n('مغلقة', 'Locked')),
    ExportColumn(key: 'is_dismissed', label: _n('غير مُحقّة', 'Dismissed')),
    ExportColumn(key: 'reply_count', label: _n('عدد الردود', 'Replies'), byDefault: false),
    ExportColumn(key: 'id', label: _n('المعرّف', 'Id'), byDefault: false),
  ];

  @override
  Future<List<Map<String, String>>> fetch(ExportRequest request) async {
    // `all` is the register, and it is what `complaints.view` grants. The
    // complainant's name comes back only where the caller is entitled to it —
    // the RPC redacts it otherwise, and this exports what it is given.
    final complaints = await ComplaintsRepository().fetchList(all: true);
    final l = request.l;
    return [
      for (final complaint in complaints)
        {
          'created_at': ExportValues.moment(complaint.createdAt),
          'target': complaintTargetLabel(l, complaint.target),
          'target_label': ExportValues.text(complaint.targetLabel),
          'body': complaint.body,
          'complainant': ExportValues.text(complaint.complainantName),
          'is_locked': ExportValues.yesNo(l, complaint.isLocked),
          'is_dismissed': ExportValues.yesNo(l, complaint.isDismissed),
          'reply_count': ExportValues.number(complaint.replyCount),
          'id': complaint.id,
        },
    ];
  }
}

class _EvaluationsDataset extends ExportDataset {
  @override
  String get id => 'evaluations';

  @override
  LocalizedName get name => _n('التقييمات', 'Evaluations');

  @override
  String? get permission => PermissionCodes.evaluationsView;

  @override
  List<ExportColumn> get columns => [
    ExportColumn(key: 'created_at', label: _n('تاريخ الفتح', 'Opened at')),
    ExportColumn(key: 'template', label: _n('النموذج', 'Form')),
    ExportColumn(key: 'target', label: _n('نوع الجهة', 'Subject kind')),
    ExportColumn(key: 'target_label', label: _n('الجهة', 'Subject')),
    ExportColumn(key: 'evaluator', label: _n('المُقيِّم', 'Evaluator')),
    ExportColumn(key: 'status', label: _n('الحالة', 'Status')),
    ExportColumn(key: 'score', label: _n('العلامة', 'Score')),
    ExportColumn(key: 'max_score', label: _n('العلامة القصوى', 'Out of')),
    ExportColumn(key: 'percent', label: _n('النسبة %', 'Percent')),
    ExportColumn(key: 'submitted_at', label: _n('تاريخ الاعتماد', 'Submitted at'), byDefault: false),
    ExportColumn(key: 'due_on', label: _n('تاريخ الاستحقاق', 'Due on'), byDefault: false),
    ExportColumn(key: 'id', label: _n('المعرّف', 'Id'), byDefault: false),
  ];

  @override
  Future<List<Map<String, String>>> fetch(ExportRequest request) async {
    final evaluations = await EvaluationsRepository().fetchList(all: true);
    final l = request.l;
    return [
      for (final evaluation in evaluations)
        {
          'created_at': ExportValues.moment(evaluation.createdAt),
          'template': evaluation.templateTitle,
          'target': evaluationTargetLabel(l, evaluation.target),
          'target_label': ExportValues.text(evaluation.targetLabel),
          'evaluator': ExportValues.text(evaluation.evaluatorName),
          'status': evaluation.isSubmitted
              ? l.evaluationStatusSubmitted
              : l.evaluationStatusDraft,
          'score': ExportValues.decimal(evaluation.score),
          'max_score': ExportValues.decimal(evaluation.maxScore),
          'percent': ExportValues.decimal(evaluation.percent),
          'submitted_at': ExportValues.moment(evaluation.submittedAt),
          'due_on': ExportValues.date(evaluation.dueOn),
          'id': evaluation.id,
        },
    ];
  }
}

// ----------------------------------------------------------- shared options

/// Which season. Offered by nearly everything, because nearly everything in
/// this app is scoped to one and an export that silently spanned all of them
/// would be read as this year's.
ExportOption _seasonOption({LocalizedName? label, bool required = true}) =>
    ExportOption(
      key: 'season',
      label: label ?? _n('الموسم', 'Season'),
      required: required,
      choices: () async {
        final seasons = await SeasonsRepository().fetchSeasons();
        return [
          for (final season in seasons)
            ExportChoice(
              id: season.id,
              label: LocalizedName(ar: '${season.hijriYear}هـ'),
            ),
        ];
      },
    );

/// Which operational file. Required: "the members" of no file in particular is
/// not a question with an answer.
ExportOption _moduleOption() => ExportOption(
  key: 'module',
  label: _n('الملف التشغيلي', 'Operational file'),
  choices: () async {
    final modules = await ModulesRepository().fetchModules();
    return [
      for (final module in modules)
        ExportChoice(
          id: module.id,
          label: LocalizedName(
            ar: '${module.moduleTypeName?.ar ?? ''} — '
                '${module.seasonHijriYear ?? ''}هـ',
            en: module.moduleTypeName?.en,
          ),
        ),
    ];
  },
);

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
