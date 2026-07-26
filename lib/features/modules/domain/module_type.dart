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
    this.referenceSetId,
    this.isRequired = false,
  });

  final String id;
  final String key;
  final LocalizedName label;
  final ModuleFieldKind kind;

  /// Which master-data list backs the dropdown, for [ModuleFieldKind.reference].
  final String? referenceSetId;
  final bool isRequired;

  factory ModuleField.fromMap(Map<String, dynamic> map) => ModuleField(
    id: map['id'] as String,
    key: map['key'] as String,
    label: LocalizedName.fromMap(map, prefix: 'label'),
    kind: ModuleFieldKind.fromDb(map['kind'] as String?),
    referenceSetId: map['reference_set_id'] as String?,
    isRequired: (map['is_required'] as bool?) ?? false,
  );
}

/// A duty attached to a role, defined once per module type.
///
/// Whether it is carried by every holder of that role or handed to particular
/// ones is the role's business, not the task's — see
/// [ModuleRole.tasksAreAssigned].
class RoleTask {
  const RoleTask({required this.id, required this.title, this.description});

  final String id;
  final LocalizedName title;
  final LocalizedName? description;

  factory RoleTask.fromMap(Map<String, dynamic> map) => RoleTask(
    id: map['id'] as String,
    title: LocalizedName.fromMap(map, prefix: 'title'),
    description: map['description_ar'] == null
        ? null
        : LocalizedName.fromMap(map, prefix: 'description'),
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
    tasks: _bySortOrder(map['module_type_role_tasks'])
        .map(RoleTask.fromMap)
        .toList(),
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
    this.roles = const [],
  });

  final String id;
  final String code;
  final LocalizedName name;

  /// 1 is the outermost level; each level nests inside the one before it.
  final int depth;
  final String? referenceSetId;

  /// The roles held at this level, in the order they are filled.
  final List<ModuleRole> roles;

  /// Whether a node here is picked from master data (a hotel) or named by hand
  /// (a sector).
  bool get isNamedByHand => referenceSetId == null;

  ModuleLevel withRoles(List<ModuleRole> roles) => ModuleLevel(
    id: id,
    code: code,
    name: name,
    depth: depth,
    referenceSetId: referenceSetId,
    roles: roles,
  );

  factory ModuleLevel.fromMap(Map<String, dynamic> map) => ModuleLevel(
    id: map['id'] as String,
    code: map['code'] as String,
    name: LocalizedName.fromMap(map),
    depth: (map['depth'] as int?) ?? 1,
    referenceSetId: map['reference_set_id'] as String?,
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
    this.endCondition,
    this.fields = const [],
    this.roles = const [],
    this.levels = const [],
  });

  final String id;
  final String code;
  final LocalizedName name;
  final LocalizedName? description;

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

  /// Whether files of this type are built as sectors and towers, or are simply
  /// the list of the people in them.
  bool get hasTree => levels.isNotEmpty;

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
      endCondition: map['end_condition_ar'] == null
          ? null
          : LocalizedName.fromMap(map, prefix: 'end_condition'),
      fields: _bySortOrder(map['module_type_fields'])
          .map(ModuleField.fromMap)
          .toList(),
      roles: roles.where((r) => r.levelId == null).toList(),
      levels: [
        for (final level in levels)
          level.withRoles(roles.where((r) => r.levelId == level.id).toList()),
      ],
    );
  }
}
