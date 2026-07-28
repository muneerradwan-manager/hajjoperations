import '../../../core/l10n/localized_name.dart';

/// Embedded PostgREST lists come back unordered; every catalog table carries a
/// `sort_order` that decides how the admin arranged it.
List<Map<String, dynamic>> _bySortOrder(Object? rows) {
  final list = ((rows as List?) ?? const [])
      .cast<Map<String, dynamic>>()
      .toList();
  list.sort(
    (a, b) =>
        ((a['sort_order'] as int?) ?? 0).compareTo((b['sort_order'] as int?) ?? 0),
  );
  return list;
}

/// The kinds of value a module field can hold. Mirrors the `module_field_kind`
/// enum in the database (0017_modules.sql).
enum ModuleFieldKind {
  text,
  textarea,
  number,
  date,
  reference,
  pdf,
  url,
  location,
  phone;

  static ModuleFieldKind fromDb(String? value) => switch (value) {
    'textarea' => ModuleFieldKind.textarea,
    'number' => ModuleFieldKind.number,
    'date' => ModuleFieldKind.date,
    'reference' => ModuleFieldKind.reference,
    'pdf' => ModuleFieldKind.pdf,
    'url' => ModuleFieldKind.url,
    'location' => ModuleFieldKind.location,
    'phone' => ModuleFieldKind.phone,
    _ => ModuleFieldKind.text,
  };
}

/// One field in a module type's data schema. The value a module stores for it
/// lives under [key] in `modules.data`.
class ModuleField {
  const ModuleField({
    required this.id,
    required this.key,
    required this.label,
    required this.kind,
    this.levelId,
    this.referenceSetId,
    this.isRequired = false,
  });

  final String id;
  final String key;
  final LocalizedName label;
  final ModuleFieldKind kind;

  /// The tree level whose nodes carry this field — the الطاقة الاستيعابية of a
  /// مخيم. Null for a field of the file itself, which is what every field was
  /// until 0052.
  final String? levelId;

  /// Which master-data list backs the dropdown, for [ModuleFieldKind.reference].
  final String? referenceSetId;
  final bool isRequired;

  factory ModuleField.fromMap(Map<String, dynamic> map) => ModuleField(
    id: map['id'] as String,
    key: map['key'] as String,
    label: LocalizedName.fromMap(map, prefix: 'label'),
    kind: ModuleFieldKind.fromDb(map['kind'] as String?),
    levelId: map['level_id'] as String?,
    referenceSetId: map['reference_set_id'] as String?,
    isRequired: (map['is_required'] as bool?) ?? false,
  );
}

/// A stage of a type's work — التخطيط والإعداد, then مكة المكرمة, then المشاعر.
/// Duties fall into one, and a list of fifteen read in one run says far less
/// than three lists read in the order the work happens.
class TaskGroup {
  const TaskGroup({required this.id, required this.code, required this.name});

  final String id;
  final String code;
  final LocalizedName name;

  factory TaskGroup.fromMap(Map<String, dynamic> map) => TaskGroup(
    id: map['id'] as String,
    code: map['code'] as String,
    name: LocalizedName.fromMap(map),
  );
}

/// A duty, defined once per module type.
///
/// It belongs either to a role — the duties of that post — or to the file
/// itself, when the Administration lists duties for the work without tying any
/// of them to one of its specialities. Whether it is carried by everyone or
/// handed to particular people is the role's business, not the duty's; see
/// [ModuleRole.tasksAreAssigned].
class RoleTask {
  const RoleTask({
    required this.id,
    required this.title,
    this.description,
    this.groupId,
  });

  final String id;
  final LocalizedName title;
  final LocalizedName? description;

  /// The stage of the work this duty falls in, for a type that has stages.
  final String? groupId;

  factory RoleTask.fromMap(Map<String, dynamic> map) => RoleTask(
    id: map['id'] as String,
    title: LocalizedName.fromMap(map, prefix: 'title'),
    description: map['description_ar'] == null
        ? null
        : LocalizedName.fromMap(map, prefix: 'description'),
    groupId: map['group_id'] as String?,
  );
}

/// A job role within a module type, with the tasks that come with it.
class ModuleRole {
  const ModuleRole({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.levelId,
    this.allowsMultiple = false,
    this.isRequired = false,
    this.tasksAreAssigned = false,
    this.tasks = const [],
  });

  final String id;
  final String code;
  final LocalizedName name;

  /// The job description (الوصف الوظيفي): what the post is, stated once by the
  /// Administration. Distinct from [tasks], which is what is due this season.
  final LocalizedName? description;

  /// The tree level this role is held at — a sector supervisor is appointed per
  /// sector, a tower supervisor per tower. Null for a role held once for the
  /// whole file.
  final String? levelId;

  /// Roles such as "mission members" hold several people; a supervisor holds one.
  final bool allowsMultiple;
  final bool isRequired;

  /// How [tasks] is meant to be read. False — the standing list — is every duty
  /// of the post, carried by whoever holds it. True makes the list a menu: each
  /// holder is handed his own share of it, possibly none, and it is what he was
  /// handed rather than the whole list that is his.
  final bool tasksAreAssigned;

  final List<RoleTask> tasks;

  /// The subset of [tasks] handed to one person, in the order the type lists
  /// them. For a standing list this is simply all of them: nothing was handed
  /// out because nothing needed to be.
  List<RoleTask> tasksFor(Set<String> assigned) => tasksAreAssigned
      ? tasks.where((t) => assigned.contains(t.id)).toList()
      : tasks;

  factory ModuleRole.fromMap(Map<String, dynamic> map) => ModuleRole(
    id: map['id'] as String,
    code: map['code'] as String,
    name: LocalizedName.fromMap(map),
    description: map['description_ar'] == null
        ? null
        : LocalizedName.fromMap(map, prefix: 'description'),
    levelId: map['level_id'] as String?,
    allowsMultiple: (map['allows_multiple'] as bool?) ?? false,
    isRequired: (map['is_required'] as bool?) ?? false,
    tasksAreAssigned: (map['tasks_are_assigned'] as bool?) ?? false,
    tasks: _bySortOrder(map['module_type_tasks']).map(RoleTask.fromMap).toList(),
  );
}

/// One level of a module type's tree: القطاع, then البرج/الفندق inside it.
///
/// [referenceSetId] is what a node at this level *is*. A tower is a hotel taken
/// from the hotels list; a sector has no list — it is a division of this file
/// alone, so it is named when it is created ("القطاع الأول").
class ModuleLevel {
  const ModuleLevel({
    required this.id,
    required this.code,
    required this.name,
    required this.depth,
    this.referenceSetId,
    this.secondaryReferenceSetId,
    this.fields = const [],
    this.roles = const [],
  });

  final String id;
  final String code;
  final LocalizedName name;

  /// 1 is the outermost level; each level nests inside the one before it.
  final int depth;
  final String? referenceSetId;

  /// A second list a node here is TIED to, as opposed to what it is: a برج is a
  /// فندق, and it belongs to a تكتل. Null for a level that ties to nothing,
  /// which is every level but the tower.
  final String? secondaryReferenceSetId;

  /// What every node at this level carries besides its name — the الطاقة
  /// الاستيعابية and the موقع of a مخيم. Empty for a level that asks for
  /// nothing further.
  final List<ModuleField> fields;

  /// The roles held at this level, in the order they are filled.
  final List<ModuleRole> roles;

  /// Whether a node here is picked from master data (a hotel) or named by hand
  /// (a sector).
  bool get isNamedByHand => referenceSetId == null;

  ModuleLevel withRolesAndFields(
    List<ModuleRole> roles,
    List<ModuleField> fields,
  ) => ModuleLevel(
    id: id,
    code: code,
    name: name,
    depth: depth,
    referenceSetId: referenceSetId,
    secondaryReferenceSetId: secondaryReferenceSetId,
    fields: fields,
    roles: roles,
  );

  factory ModuleLevel.fromMap(Map<String, dynamic> map) => ModuleLevel(
    id: map['id'] as String,
    code: map['code'] as String,
    name: LocalizedName.fromMap(map),
    depth: (map['depth'] as int?) ?? 1,
    referenceSetId: map['reference_set_id'] as String?,
    secondaryReferenceSetId: map['secondary_reference_set_id'] as String?,
  );
}

/// A kind of operational file. Everything that makes one type differ from
/// another — its fields, its tree, its roles, tasks and attachments — hangs off
/// this row, so adding a type is data entry rather than a schema change.
///
/// A file of a given type exists at most once in a season: the type's name is
/// the file's name, which is why a file carries no title of its own.
class ModuleType {
  const ModuleType({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.startCondition,
    this.endCondition,
    this.fields = const [],
    this.roles = const [],
    this.levels = const [],
    this.tasks = const [],
    this.taskGroups = const [],
  });

  final String id;
  final String code;
  final LocalizedName name;
  final LocalizedName? description;

  /// What opens a file of this type — "من تاريخ اعتماد مجموعات الحج السوري".
  /// The file still carries the date somebody entered; this says what that date
  /// is the date OF. Null for a type whose start was never stated as an event.
  final LocalizedName? startCondition;

  /// What closes a file of this type — the same event every season, so it is
  /// stated here rather than entered as a date on each file.
  final LocalizedName? endCondition;

  final List<ModuleField> fields;

  /// Roles held once for the whole file. Roles held per sector or per tower
  /// live on their [ModuleLevel] instead.
  final List<ModuleRole> roles;

  /// The tree this type's files are built as, outermost level first. Empty for
  /// a type that has no tree: الطوافة والنقل is a roster, not a hierarchy, and
  /// its people sit on the file itself.
  final List<ModuleLevel> levels;

  /// The duties of the file itself — a list the Administration wrote for the
  /// work rather than for any one of its roles, which every role draws on.
  /// Empty for a type whose duties all belong to particular posts.
  final List<RoleTask> tasks;

  /// The stages those duties fall into, in the order the work happens.
  final List<TaskGroup> taskGroups;

  /// Whether files of this type are built as sectors and towers, or are simply
  /// the list of the people in them.
  bool get hasTree => levels.isNotEmpty;

  /// Every duty that may be handed to a holder of [role]: the role's own, and
  /// the file's. Empty for a role whose duties are standing — those are his by
  /// holding the post at all, and there is nothing to hand out.
  List<RoleTask> assignableFor(ModuleRole role) =>
      role.tasksAreAssigned ? [...role.tasks, ...tasks] : const [];

  /// Everything a holder of [role] is answerable for, given what he was handed:
  /// his post's standing duties, plus his share of whatever is handed out.
  List<RoleTask> dutiesOf(ModuleRole role, Set<String> assigned) => [
    ...role.tasksFor(assigned),
    if (role.tasksAreAssigned)
      ...tasks.where((t) => assigned.contains(t.id)),
  ];

  /// [tasks] split into the stages of the work, in order. Duties belonging to
  /// no stage come first under no heading, and empty stages are dropped — a
  /// heading with nothing under it says only that something is missing.
  List<(TaskGroup?, List<RoleTask>)> byStage(List<RoleTask> tasks) {
    if (taskGroups.isEmpty) {
      return tasks.isEmpty ? const [] : [(null, tasks)];
    }
    return [
      for (final stage in <TaskGroup?>[null, ...taskGroups])
        if (tasks.where((t) => t.groupId == stage?.id).toList()
            case final inStage when inStage.isNotEmpty)
          (stage, inStage),
    ];
  }

  ModuleLevel? levelById(String? id) =>
      levels.where((l) => l.id == id).firstOrNull;

  ModuleLevel? get outermostLevel => levels.firstOrNull;

  /// The level nested directly inside [level], if any.
  ModuleLevel? levelBelow(ModuleLevel level) =>
      levels.where((l) => l.depth == level.depth + 1).firstOrNull;

  ModuleRole? roleById(String id) =>
      allRoles.where((r) => r.id == id).firstOrNull;

  /// Every role of the type, file-level and level-scoped alike.
  List<ModuleRole> get allRoles => [
    ...roles,
    for (final level in levels) ...level.roles,
  ];

  factory ModuleType.fromMap(Map<String, dynamic> map) {
    // Roles arrive in one flat list and are sorted into the level that holds
    // them; whatever names no level is held for the file as a whole.
    final roles = _bySortOrder(
      map['module_type_roles'],
    ).map(ModuleRole.fromMap).toList();
    // Fields are sorted the same way: whatever names a level is carried by
    // every node at it, and whatever names none belongs to the file.
    final fields = _bySortOrder(
      map['module_type_fields'],
    ).map(ModuleField.fromMap).toList();
    final levels = (((map['module_type_levels'] as List?) ?? const [])
            .cast<Map<String, dynamic>>())
        .map(ModuleLevel.fromMap)
        .toList();
    levels.sort((a, b) => a.depth.compareTo(b.depth));

    return ModuleType(
      id: map['id'] as String,
      code: map['code'] as String,
      name: LocalizedName.fromMap(map),
      description: map['description_ar'] == null
          ? null
          : LocalizedName.fromMap(map, prefix: 'description'),
      startCondition: map['start_condition_ar'] == null
          ? null
          : LocalizedName.fromMap(map, prefix: 'start_condition'),
      endCondition: map['end_condition_ar'] == null
          ? null
          : LocalizedName.fromMap(map, prefix: 'end_condition'),
      fields: fields.where((f) => f.levelId == null).toList(),
      tasks: _bySortOrder(map['module_type_tasks'])
          .map(RoleTask.fromMap)
          .toList(),
      taskGroups: _bySortOrder(map['module_type_task_groups'])
          .map(TaskGroup.fromMap)
          .toList(),
      roles: roles.where((r) => r.levelId == null).toList(),
      levels: [
        for (final level in levels)
          level.withRolesAndFields(
            roles.where((r) => r.levelId == level.id).toList(),
            fields.where((f) => f.levelId == level.id).toList(),
          ),
      ],
    );
  }
}
