import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../../core/constants/permission_codes.dart';
import '../../../core/l10n/localized_name.dart';
import '../../complaints/data/complaints_repository.dart';
import '../../complaints/presentation/widgets/complaint_labels.dart';
import '../../employees/data/employees_repository.dart';
import '../../evaluations/data/evaluations_repository.dart';
import '../../evaluations/presentation/widgets/evaluation_labels.dart';
import '../../modules/data/modules_repository.dart';
import '../../modules/domain/module_task.dart';
import '../../modules/domain/module_type.dart';
import '../../modules/domain/operational_module.dart';
import '../../profile/domain/profile.dart';
import '../../profile/domain/profile_enums.dart';
import '../../modules/domain/reference_item.dart';
import '../../reports/data/reports_repository.dart';
import '../../reports/domain/report.dart';
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
/// Every fetch goes through the same repository the screen uses, so row
/// security narrows an export exactly as it narrows a page. That used to mean
/// this screen could not widen anything at all.
///
/// **It can now.** 0100 made `export.data` a senior read: the row policies
/// themselves accept it, so a holder exports the employees whether or not he
/// may open the employees screen. The widening had to happen there rather than
/// here — offering a dataset the reader's policies refuse produces an EMPTY
/// FILE and no error, and an empty export is worse than a refusal because he
/// carries it away believing it is the data.
///
/// Two things it still does not open: the complaints and the evaluations filed
/// about the holder HIMSELF. 0079 and 0084 fence a manager off his own case so
/// that a read permission cannot become the way to find out who accused you,
/// and 0100 widens the helper INSIDE that fence rather than around it.
abstract final class ExportCatalog {
  static final List<ExportDataset> all = [
    _EmployeesDataset(),
    _SeasonParticipantsDataset(),
    _ModuleDataset(),
    _ReferenceItemsDataset(),
    _ReportsDataset(),
    _ComplaintsDataset(),
    _EvaluationsDataset(),
  ];

  /// What this reader may be offered.
  ///
  /// `export.data` offers everything, and that is the point of it (0100).
  /// Whoever may take data out may take any of it — so the per-dataset
  /// permissions below decide nothing for a holder, and the row policies were
  /// widened to match. Without that widening this list would be a lie: the
  /// employees would be offered and the file would come back empty, because
  /// `profiles_select` would return him nothing and no error would be raised.
  ///
  /// The per-dataset check is kept for the admin case and for a future grant
  /// that is narrower than this one. Nothing today reaches it except an admin,
  /// who passes the first clause anyway.
  static List<ExportDataset> visibleTo({
    required bool isAdmin,
    required Set<String> permissions,
  }) => [
    for (final dataset in all)
      if (isAdmin ||
          permissions.contains(PermissionCodes.exportData) ||
          dataset.permission == null ||
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
  ExportColumn(
    key: 'first_name',
    label: _n('الاسم', 'First name'),
    byDefault: false,
  ),
  ExportColumn(
    key: 'father_name',
    label: _n('اسم الأب', 'Father name'),
    byDefault: false,
  ),
  ExportColumn(
    key: 'surname',
    label: _n('الكنية', 'Surname'),
    byDefault: false,
  ),
  ExportColumn(key: 'job_title', label: _n('المهنة', 'Job title')),
  ExportColumn(key: 'mission_type', label: _n('نوع البعثة', 'Mission type')),
  ExportColumn(key: 'email', label: _n('البريد الإلكتروني', 'Email')),
  ExportColumn(key: 'phone_sy', label: _n('الهاتف (سوريا)', 'Phone (SY)')),
  ExportColumn(key: 'phone_sa', label: _n('الهاتف (السعودية)', 'Phone (SA)')),
  ExportColumn(key: 'city', label: _n('المدينة', 'City'), byDefault: false),
  ExportColumn(key: 'gender', label: _n('الجنس', 'Gender'), byDefault: false),
  ExportColumn(
    key: 'date_of_birth',
    label: _n('تاريخ الميلاد', 'Date of birth'),
    byDefault: false,
  ),
  ExportColumn(
    key: 'is_external',
    label: _n('خارجي', 'External'),
    byDefault: false,
  ),
  ExportColumn(
    key: 'external_organization',
    label: _n('الجهة', 'Organization'),
    byDefault: false,
  ),
  ExportColumn(
    key: 'external_title',
    label: _n('الصفة', 'Title'),
    byDefault: false,
  ),
  ExportColumn(
    key: 'account_status',
    label: _n('حالة الحساب', 'Account status'),
    byDefault: false,
  ),
  ExportColumn(
    key: 'is_suspended',
    label: _n('موقوف', 'Suspended'),
    byDefault: false,
  ),
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

class _EmployeesDataset extends ExportListDataset {
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
      choices: (_) async => [
        ExportChoice(
          id: 'permanent',
          label: _n('الملاك الدائم', 'Permanent staff'),
        ),
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
      // `.data` because the read may have come off disk. An export IS allowed
      // to be built from a saved copy — the alternative is refusing to produce
      // a file at all with no signal — and the ordinary case here is a desk
      // with a network, where it is live anyway.
      if (kind != 'external') ...(await repo.fetchPermanent()).data,
      // An external belongs to a season rather than to the mission, which is
      // why the season is offered here and why leaving it off lists everyone
      // who has ever been one.
      if (kind != 'permanent') ...await repo.fetchExternal(seasonId: seasonId),
    ];

    return [for (final person in people) _profileRow(person, request)];
  }
}

class _SeasonParticipantsDataset extends ExportListDataset {
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

/// One operational file, and everything in it.
///
/// It was three datasets — the files, the members of a file, the duties of a
/// file — and that was three wrong answers to one question. Nobody exports "the
/// members of a file" as an errand of its own: they are asked for تشكيل فرق
/// المشاعر, and they want the file. So they exported the roster, then went back
/// and exported the duties, then had two sheets that nothing tied together and
/// no record of which file either came from.
///
/// The file is the subject and its parts are sections of one document. The
/// index of all files went with them: a list of files is a thing to look at on
/// the files screen, not a thing anybody carries away.
class _ModuleDataset extends ExportDataset {
  @override
  String get id => 'module';

  @override
  LocalizedName get name => _n('ملف تشغيلي', 'An operational file');

  @override
  String? get permission => null;

  @override
  LocalizedName get partsLabel => _n('الأقسام', 'Sections');

  /// The parts, not columns. Each one is a section with columns of its own that
  /// the reader never picks between — a roster is a roster.
  @override
  List<ExportColumn> get columns => [
    ExportColumn(key: 'info', label: _n('معلومات الملف', 'File particulars')),
    ExportColumn(key: 'members', label: _n('الأعضاء', 'Members')),
    ExportColumn(key: 'tasks', label: _n('المهام', 'Duties')),
    ExportColumn(
      key: 'reports',
      label: _n('التقارير المرفوعة', 'Filed reports'),
    ),
  ];

  @override
  List<ExportOption> get options => [_moduleOption()];

  @override
  Future<List<ExportTable>> build(
    ExportRequest request,
    List<ExportColumn> chosen,
  ) async {
    final moduleId = request.option('module');
    if (moduleId == null) return const [];

    final wants = {for (final part in chosen) part.key};
    final repo = ModulesRepository();
    final l = request.l;
    final sections = <ExportTable>[];

    final module = await repo.fetchModule(moduleId);
    if (module == null) return const [];

    // The type, for the names of its levels and roles. Without it a posting is
    // a pair of ids and the roster reads as a column of blanks.
    final type = await repo.fetchModuleType(module.moduleTypeId);

    if (wants.contains('info')) {
      sections.add(
        ExportTable(
          title: request.text(_n('معلومات الملف', 'File particulars')),
          // Two columns rather than one wide row. A file has fifteen
          // particulars and most of them are empty; laid across the page they
          // are a header row nobody can read and one row of mostly nothing.
          headers: [
            request.text(_n('البند', 'Field')),
            request.text(_n('القيمة', 'Value')),
          ],
          // Empty particulars are left OUT rather than printed as blank
          // rows. Most of the fifteen are empty on any given file — no
          // decision number, no end date, neither note — and a two-column
          // sheet that is half blank reads as data that failed to load.
          rows: [
            for (final (label, value) in <(LocalizedName, String)>[
              (
                _n('نوع الملف', 'File type'),
                request.text(module.moduleTypeName),
              ),
              (
                _n('الموسم', 'Season'),
                module.seasonHijriYear?.toString() ?? '',
              ),
              (
                _n('رقم القرار', 'Decision number'),
                ExportValues.text(module.decisionNumber),
              ),
              (
                _n('تاريخ البدء', 'Starts on'),
                ExportValues.date(module.startsOn),
              ),
              (
                _n('ملاحظة بداية العمل', 'Start note'),
                ExportValues.text(module.startNote),
              ),
              (
                _n('تاريخ الانتهاء', 'Ends on'),
                ExportValues.date(module.endsOn),
              ),
              (
                _n('ملاحظة نهاية العمل', 'End note'),
                ExportValues.text(module.endNote),
              ),
              (_n('مُفعَّل', 'Active'), ExportValues.yesNo(l, module.isActive)),
              (_n('قائم', 'Running'), ExportValues.yesNo(l, module.isRunning)),
              (
                _n('دورية التقرير', 'Report cadence'),
                // Not `.name` — that is the enum's own identifier and prints
                // literally as "none" on a file that asks for none, which is
                // exactly what the sheet in `docs/module-2026-08-19.pdf`
                // showed. Empty rather than "no reports" when there are none,
                // to match the row this mirrors on the file page, which is
                // not shown at all when `!asksForReports`.
                switch (module.reportCadence) {
                  ReportCadence.none => '',
                  ReportCadence.daily => l.cadenceDaily,
                  ReportCadence.weekly => l.cadenceWeekly,
                  ReportCadence.once => l.cadenceOnce,
                },
              ),
            ])
              if (value.isNotEmpty) [request.text(label), value],
            // What the TYPE asks this file for — the official PDF, a capacity,
            // whatever the Administration added. Named by the type rather than
            // by their keys, and skipped when empty.
            for (final field in type?.fields ?? const <ModuleField>[])
              if (_fieldValue(module.data[field.key]) case final value
                  when value.isNotEmpty)
                [request.text(field.label), value],
          ],
        ),
      );
    }

    if (wants.contains('members')) {
      final members = await repo.fetchMembers(moduleId);
      final nodes = await repo.fetchNodes(moduleId);
      // The sets are what NAMES a node. Since 0095 nothing is authored
      // inside a file — a برج is an entry of a list and its own `label` is
      // null — so without these every place on the sheet is blank.
      final sets = await repo.fetchReferenceSets();
      sections.add(_roster(request, type, members, nodes, sets));
    }

    if (wants.contains('tasks')) {
      final list = await repo.fetchModuleTasks(moduleId);
      sections.add(
        ExportTable(
          title: request.text(_n('المهام', 'Duties')),
          headers: [
            request.text(_n('المهمة', 'Duty')),
            request.text(_n('النطاق', 'Scope')),
            request.text(_n('تاريخ الاستحقاق', 'Due on')),
            request.text(_n('الوصف', 'Description')),
          ],
          rows: [
            for (final task in list.tasks)
              [
                request.text(task.title),
                switch (task.scope) {
                  TaskScope.file => l.moduleTaskScopeFile,
                  TaskScope.role => l.moduleTaskScopeRole,
                },
                ExportValues.date(task.dueOn),
                request.text(task.description),
              ],
          ],
        ),
      );
    }

    if (wants.contains('reports')) {
      final reports = await repo.fetchReports(moduleId);
      sections.add(
        ExportTable(
          title: request.text(_n('التقارير المرفوعة', 'Filed reports')),
          headers: [
            request.text(_n('الكاتب', 'Author')),
            request.text(_n('الفترة', 'Period')),
            request.text(_n('تاريخ الرفع', 'Filed at')),
            request.text(_n('المتن', 'Body')),
            request.text(_n('المرفقات', 'Attachments')),
          ],
          rows: [
            for (final report in reports)
              [
                report.author?.fullName ?? '',
                ExportValues.date(report.periodStart),
                ExportValues.moment(report.createdAt),
                ExportValues.text(report.notes),
                report.attachments.length.toString(),
              ],
          ],
        ),
      );
    }

    return sections;
  }

  /// Everyone in the file: one row per PERSON, with the posts they hold and
  /// where they hold them.
  ///
  /// The same fold the roster screen does. A file records a row per POST, so on
  /// تشكيل فرق المشاعر — where a supervisor serves منى يوم التروية, عرفات and
  /// منى أيام التشريق — the sheet carried his name, his trade and both his
  /// telephone numbers three times over, and whoever received it could not tell
  /// three postings from three men.
  ExportTable _roster(
    ExportRequest request,
    ModuleType? type,
    List<ModuleMember> members,
    List<ModuleNode> nodes,
    List<ReferenceSet> sets,
  ) {
    final roleName = <String, String>{
      for (final role in type?.roles ?? const <ModuleRole>[])
        role.id: request.text(role.name),
      for (final level in type?.levels ?? const <ModuleLevel>[])
        for (final role in level.roles) role.id: request.text(role.name),
    };
    // A file's own roles are grouped into TEAMS by the type — فريق
    // الكوسترات, مراقبو إعاشة المشاعر — and the team is the nearest thing such
    // a posting has to a place.
    final teamOf = <String, String>{
      for (final role in type?.roles ?? const <ModuleRole>[])
        if (role.teamId case final teamId?)
          for (final team in type?.teams ?? const <ModuleTeam>[])
            if (team.id == teamId) role.id: request.text(team.name),
    };

    final nodeById = {for (final node in nodes) node.id: node};
    final levelById = {
      for (final level in type?.levels ?? const <ModuleLevel>[])
        level.id: level,
    };

    /// A node's own name: the ENTRY it stands for, then a hand-typed label,
    /// then the level's name — the same three, in the same order, that every
    /// screen in this app resolves a node by.
    ///
    /// Reading `label` alone put a blank in every cell of the الموقع column: it
    /// has been null on every node since 0095, when a file stopped being able
    /// to name anything inside itself.
    String nameOf(ModuleNode node) {
      final level = levelById[node.levelId];
      final setId = level?.referenceSetId;
      final itemId = node.referenceItemId;
      if (setId != null && itemId != null) {
        for (final set in sets) {
          if (set.id != setId) continue;
          final item = set.items.where((i) => i.id == itemId).firstOrNull;
          if (item != null) return request.text(item.name);
        }
      }
      return node.label ?? (level == null ? '' : request.text(level.name));
    }

    /// Where a posting sits, named from the outside in: «القطاع الأول — برج ٣».
    ///
    /// A posting held on the FILE has no node, and it used to say so — «على
    /// الملف نفسه», on every row, which on a file with no tree at all was one
    /// sentence repeated down a whole column and not one fact in it. What such
    /// a posting HAS is its team, so that is what the column carries; and where
    /// there is no team either, the cell is empty, because there is genuinely
    /// no place and a phrase saying so is furniture.
    String placeOf(ModuleMember member, ModuleNode? node) {
      if (node == null) return teamOf[member.roleId] ?? '';
      final names = <String>[];
      var current = node;
      while (true) {
        names.insert(0, nameOf(current));
        final parent = current.parentId == null
            ? null
            : nodeById[current.parentId];
        if (parent == null) break;
        current = parent;
      }
      // An em dash, and NOT an arrow. The PDF is set in itfQomraArabic, which
      // maps three hundred codepoints and U+2190 is not one of them: the
      // separator rendered as nothing at all, and «القطاع الخامس ← بركة
      // اليقين» reached the sheet as two names run together with no sign that
      // one contains the other. A glyph the font lacks does not fail — it
      // silently is not there, which is the worst way for a document to be
      // wrong. See `export_pdf_glyphs_test.dart`, which now refuses any
      // separator this font cannot draw.
      return names.where((n) => n.isNotEmpty).join(' — ');
    }

    // Keyed by person and by the NODE — its id, never its printed name.
    //
    // The name was the key, and that was a silent loss: every node's name
    // resolved to the empty string, so every posting in the file shared one
    // key, and the roles held on the FILE itself — فريق الكوسترات, مراقبو
    // الإعاشة — were folded into whichever tower row happened to come first
    // and left the sheet altogether. An id is what a place IS; a label is what
    // it is called today.
    final order = <String>[];
    final byKey = <String, (ModuleMember, String, List<String>)>{};

    void add(ModuleMember member, ModuleNode? node) {
      final key = '${member.profileId}@${node?.id ?? ''}';
      final name = roleName[member.roleId] ?? '';
      final held = byKey[key];
      if (held == null) {
        order.add(key);
        byKey[key] = (
          member,
          placeOf(member, node),
          [if (name.isNotEmpty) name],
        );
      } else if (name.isNotEmpty && !held.$3.contains(name)) {
        held.$3.add(name);
      }
    }

    for (final member in members) {
      add(member, null);
    }
    for (final node in nodes) {
      for (final member in node.members) {
        add(member, node);
      }
    }

    final headers = <LocalizedName>[
      _n('الاسم', 'Name'),
      _n('الصفات', 'Posts held'),
      _n('الموقع', 'Where'),
      _n('المهنة', 'Job title'),
      _n('الهاتف (السعودية)', 'Phone (SA)'),
      _n('الهاتف (سوريا)', 'Phone (SY)'),
      _n('البريد الإلكتروني', 'Email'),
    ];

    final rows = <List<String>>[
      for (final key in order)
        if (byKey[key] case final entry?)
          [
            entry.$1.profile?.fullName ?? '',
            // Separated by a comma rather than by a newline: a cell with a line
            // break in it is one Excel row that looks like three, and a reader
            // sorting the sheet loses two of them.
            entry.$3.join('، '),
            entry.$2,
            request.text(entry.$1.profile?.jobTitleName),
            ExportValues.text(entry.$1.profile?.phoneSa),
            ExportValues.text(entry.$1.profile?.phoneSy),
            ExportValues.text(entry.$1.profile?.email),
          ],
    ];

    // A column empty in EVERY row is left out.
    //
    // These columns are not chosen by the reader — a roster is a roster — so
    // the sheet is the only thing that can decide they are not worth their
    // width. A file with no tree has no place to put in الموقع, and a mission
    // whose people have no Saudi number yet has two blank columns; on a
    // landscape page each of them takes width from the names, and each of them
    // says "nothing here" in a way that reads as data that failed to arrive.
    //
    // The first column is never dropped: it is the name, and a nameless roster
    // is not a shorter roster.
    final keep = [
      for (var c = 0; c < headers.length; c++)
        if (c == 0 || rows.any((row) => row[c].trim().isNotEmpty)) c,
    ];

    return ExportTable(
      title: request.text(_n('الأعضاء', 'Members')),
      headers: [for (final c in keep) request.text(headers[c])],
      rows: [
        for (final row in rows) [for (final c in keep) row[c]],
      ],
    );
  }
}

/// The master-data lists — التكتلات, the hotels, the camps, the groups.
///
/// One dataset with the list as an option rather than one dataset per list:
/// the sets are content, added by the Administration during a season, and a
/// catalogue that had to be edited to export a new one would be a catalogue
/// that is always one list behind.
class _ReferenceItemsDataset extends ExportListDataset {
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
    ExportColumn(
      key: 'sort_order',
      label: _n('الترتيب', 'Order'),
      byDefault: false,
    ),
    ExportColumn(key: 'id', label: _n('المعرّف', 'Id'), byDefault: false),
  ];

  @override
  List<ExportOption> get options => [
    ExportOption(
      key: 'set',
      label: _n('القائمة', 'List'),
      choices: (_) async {
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
    final sets = await ModulesRepository().fetchReferenceSets(
      activeOnly: false,
    );
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
    final sets = await ModulesRepository().fetchReferenceSets(
      activeOnly: false,
    );
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

/// The decisions — either the index of them, or one of them entire.
///
/// One dataset and not two, because the option is the difference. Leave «القرار»
/// unanswered and it is the list it has always been: a row per decision, for
/// somebody who wants to know what has been issued. Name one and the export
/// stops being a list and becomes the DOCUMENT — its particulars, its body, and
/// each of its tables under its own heading.
///
/// A decision was only ever exportable as one row of metadata before, which is
/// the one thing about it nobody needs on paper: what a قرار says is its body,
/// and the body was reachable from nowhere.
class _ReportsDataset extends ExportDataset {
  @override
  String get id => 'reports';

  @override
  // القرارات, not التقارير. The identifiers in this feature all say `report`
  // — see the note on the `Report` class for why they were left alone — but
  // what the reader is choosing to export is the mission's decisions.
  LocalizedName get name => _n('القرارات', 'Decisions');

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
  List<ExportOption> get options => [
    // «عام» among the seasons, because a decision genuinely may belong to no
    // season — most of what the mission writes down outlives one year — and
    // without it there was no way to ask for those and only those.
    _seasonOption(required: false, includeGeneral: true),
    _reportOption(),
  ];

  @override
  Future<List<ExportTable>> build(
    ExportRequest request,
    List<ExportColumn> chosen,
  ) async {
    final reportId = request.option('report');
    final repo = ReportsRepository();
    final l = request.l;

    // ── the index ───────────────────────────────────────────────────────────
    if (reportId == null || reportId.isEmpty) {
      // The same rule the dropdown above was filled by — see [_reportsFor].
      // Two readings of «الموسم» would be a list that offers a decision the
      // file then leaves out.
      final reports = await _reportsFor(request.option('season'));
      final rows = [
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
      return [
        ExportTable(
          title: request.text(name),
          headers: [for (final column in chosen) request.text(column.label)],
          rows: [
            for (final row in rows)
              [for (final column in chosen) row[column.key] ?? ''],
          ],
        ),
      ];
    }

    // ── one decision, entire ────────────────────────────────────────────────
    final report = await repo.fetchReport(reportId);
    if (report == null) return const [];

    // The lists a table block expands over, scoped to the DOCUMENT's season —
    // the same rule the reader screen applies. Last year's تكتلات must not
    // arrive as empty columns on this year's table.
    final sets = await ModulesRepository().fetchReferenceSets();
    List<ReferenceItem> expansionOf(ReportBlock block) {
      final code = block.expandSetCode;
      if (code == null) return const [];
      final set = sets.where((s) => s.code == code).firstOrNull;
      return set?.itemsForSeason(report.seasonId) ?? const [];
    }

    final sections = <ExportTable>[
      ExportTable(
        title: request.text(_n('بيانات القرار', 'Decision particulars')),
        headers: [
          request.text(_n('البند', 'Field')),
          request.text(_n('القيمة', 'Value')),
        ],
        rows: [
          [request.text(_n('العنوان', 'Title')), report.title],
          if (report.subtitle case final sub? when sub.trim().isNotEmpty)
            [request.text(_n('العنوان الفرعي', 'Subtitle')), sub],
          [
            request.text(_n('الرقم', 'Number')),
            ExportValues.text(report.number),
          ],
          [request.text(_n('النوع', 'Type')), request.text(report.typeName)],
          [
            request.text(_n('الموسم', 'Season')),
            report.seasonHijriYear?.toString() ?? '',
          ],
          [
            request.text(_n('منشور', 'Published')),
            ExportValues.yesNo(l, report.isPublished),
          ],
          [
            request.text(_n('آخر تحديث', 'Last updated')),
            ExportValues.moment(report.updatedAt),
          ],
        ],
      ),
    ];

    // The body, in the order it was written. Prose in one column, because it IS
    // one column: a قرار is paragraphs and headings, and splitting them across
    // cells to make the sheet look like a table would put line breaks where the
    // author did not.
    final prose = <List<String>>[];
    final tables = <ExportTable>[];
    var tableNumber = 0;

    for (final block in [
      ...report.blocks,
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder))) {
      if (block.isEmpty) continue;
      switch (block.kind) {
        case ReportBlockKind.table:
          tableNumber++;
          final expansion = expansionOf(block);
          tables.add(
            ExportTable(
              title: request.text(
                _n('جدول $tableNumber', 'Table $tableNumber'),
              ),
              headers: block.effectiveColumns([
                for (final item in expansion) request.text(item.name),
              ]),
              rows: block.rows,
            ),
          );
        case ReportBlockKind.divider:
          continue;
        case ReportBlockKind.bullets || ReportBlockKind.numbers:
          for (final item in block.items) {
            prose.add([_blockLabel(request, block.kind), item]);
          }
        case ReportBlockKind.url:
          prose.add([_blockLabel(request, block.kind), block.url]);
        case ReportBlockKind.qr:
          prose.add([
            _blockLabel(request, block.kind),
            [block.label, block.value].where((t) => t.isNotEmpty).join(' — '),
          ]);
        default:
          prose.add([_blockLabel(request, block.kind), block.text]);
      }
    }

    if (prose.isNotEmpty) {
      sections.add(
        ExportTable(
          title: request.text(_n('المتن', 'Body')),
          note: request.text(
            _n(
              'كما كُتب، بترتيبه. الجداول تحته، كلٌّ تحت عنوانه.',
              'As written, in order. The tables follow, each under its own heading.',
            ),
          ),
          headers: [
            request.text(_n('النوع', 'Kind')),
            request.text(_n('النص', 'Text')),
          ],
          rows: prose,
        ),
      );
    }

    return [...sections, ...tables];
  }

  /// What a block IS, for the column beside its text — a heading read as a
  /// paragraph is a document that has lost its shape.
  String _blockLabel(ExportRequest request, ReportBlockKind kind) =>
      request.text(switch (kind) {
        ReportBlockKind.heading => _n('عنوان', 'Heading'),
        ReportBlockKind.subheading => _n('عنوان فرعي', 'Subheading'),
        ReportBlockKind.bullets => _n('نقطة', 'Bullet'),
        ReportBlockKind.numbers => _n('بند مرقّم', 'Numbered item'),
        ReportBlockKind.note => _n('ملاحظة', 'Note'),
        ReportBlockKind.url => _n('رابط', 'Link'),
        ReportBlockKind.qr => _n('رمز QR', 'QR code'),
        _ => _n('فقرة', 'Paragraph'),
      });
}

class _ComplaintsDataset extends ExportListDataset {
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
    ExportColumn(
      key: 'reply_count',
      label: _n('عدد الردود', 'Replies'),
      byDefault: false,
    ),
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

class _EvaluationsDataset extends ExportListDataset {
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
    ExportColumn(
      key: 'submitted_at',
      label: _n('تاريخ الاعتماد', 'Submitted at'),
      byDefault: false,
    ),
    ExportColumn(
      key: 'due_on',
      label: _n('تاريخ الاستحقاق', 'Due on'),
      byDefault: false,
    ),
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
/// The season a dataset is narrowed to.
///
/// [includeGeneral] adds «عام» — the rows that belong to NO season and are
/// therefore true in all of them. Only where that is a real state of the data:
/// a decision may be general, a file may not, and offering the choice where
/// nothing can be it is a filter that always answers nothing.
ExportOption _seasonOption({
  LocalizedName? label,
  bool required = true,
  bool includeGeneral = false,
}) => ExportOption(
  key: 'season',
  label: label ?? _n('الموسم', 'Season'),
  required: required,
  choices: (_) async {
    final seasons = await SeasonsRepository().fetchSeasons();
    return [
      if (includeGeneral)
        ExportChoice(id: kGeneralSeason, label: _n('عام', 'General')),
      for (final season in seasons)
        ExportChoice(
          id: season.id,
          label: LocalizedName(ar: '${season.hijriYear}هـ'),
        ),
    ];
  },
);

/// The decisions a season answer stands for.
///
/// Three answers, three meanings, and they are written here once so the list
/// the reader picks from and the file he gets cannot disagree:
///
///   * nothing chosen — every decision, whatever season;
///   * [kGeneralSeason] — only those belonging to NO season;
///   * a season — that season's, AND the general ones, because a general
///     decision is in force during it. That is the reader's own rule from
///     `fetchReports`, and an export that quietly used a stricter one would
///     drop documents the screen shows.
Future<List<Report>> _reportsFor(String? season) async {
  final repo = ReportsRepository();
  if (season == kGeneralSeason) {
    final all = await repo.fetchReports();
    return [
      for (final r in all)
        if (r.seasonId == null) r,
    ];
  }
  return repo.fetchReports(seasonId: season);
}

/// «عام»: belonging to no season.
///
/// A sentinel and not a season id, because it is not one — it is the ABSENCE
/// of a season, which is a real and deliberate state here: most of what the
/// mission writes down outlives one year, and null is how the database says so.
/// Leaving the option empty still means "every season"; this means "the ones
/// that are not any season's".
const kGeneralSeason = 'general';

/// Which decision, when the reader wants one rather than the list.
///
/// OPTIONAL, and that is the whole design: unanswered it is the index of what
/// has been issued, answered it is that document entire. Making it required
/// would have taken away the only export that answers "what decisions are
/// there" — a question somebody asks before they know which one they want.
ExportOption _reportOption() => ExportOption(
  key: 'report',
  label: _n('القرار (لتصديره كاملاً)', 'Decision (to export it whole)'),
  required: false,
  // The season above it decides which decisions are on offer. Without this the
  // screen contradicted itself two rows apart: «الموسم ١٤٤٧» and under it every
  // decision the mission has ever issued, 1445 included.
  dependsOn: const {'season'},
  choices: (answers) async {
    final reports = await _reportsFor(answers['season']);
    return [
      for (final report in reports)
        ExportChoice(
          id: report.id,
          label: LocalizedName(
            ar: [
              if (report.number case final n? when n.isNotEmpty) 'رقم $n',
              report.title,
            ].join(' — '),
          ),
        ),
    ];
  },
);

/// Which operational file. Required: a file's roster and its duties belong to
/// a file, and no file in particular has neither.
ExportOption _moduleOption() => ExportOption(
  key: 'module',
  label: _n('الملف التشغيلي', 'Operational file'),
  choices: (_) async {
    final modules = await ModulesRepository().fetchModules();
    return [
      for (final module in modules)
        ExportChoice(
          id: module.id,
          label: LocalizedName(
            ar:
                '${module.moduleTypeName?.ar ?? ''} — '
                '${module.seasonHijriYear ?? ''}هـ',
            en: module.moduleTypeName?.en,
          ),
        ),
    ];
  },
);

/// One of a file's own field values, as a person should read it.
///
/// A `pdf` or attachment field holds a MAP — the stored name and the path it
/// was filed under — and `toString()` on it put
/// `{name: تكليف اداري.docx, path: 8c2b.../3142_47.docx}` into a cell of the
/// sheet: a storage key, in front of whoever the file was sent to, standing
/// where the document's name should be.
///
/// The name is what the field means. The path is where this app keeps it, and
/// that is nobody else's business.
@visibleForTesting
String exportFieldValue(Object? raw) => _fieldValue(raw);

String _fieldValue(Object? raw) {
  if (raw == null) return '';
  if (raw is Map) {
    final name = raw['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    // A stored file with no name is still a file. Its path is not a name, so
    // it is named by what it is rather than by where it sits.
    return raw.containsKey('path') ? '—' : '';
  }
  if (raw is List) {
    return raw.map(_fieldValue).where((v) => v.isNotEmpty).join('، ');
  }
  return ExportValues.text(raw.toString());
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
