import '../../../core/l10n/localized_name.dart';
import '../../profile/domain/profile.dart';

/// A PDF stored in the private `modules` bucket. The path is what lives in
/// `modules.data`; a signed URL is minted on demand when someone opens it.
class ModuleFile {
  const ModuleFile({required this.path, required this.name});

  final String path;
  final String name;

  Map<String, dynamic> toJson() => {'path': path, 'name': name};

  static ModuleFile? fromJson(Object? value) {
    if (value is! Map) return null;
    final path = value['path'] as String?;
    if (path == null || path.isEmpty) return null;
    return ModuleFile(path: path, name: (value['name'] as String?) ?? path);
  }
}

/// A person holding a role somewhere in a file: either on the file itself, or
/// on one of its nodes.
class ModuleMember {
  const ModuleMember({
    required this.id,
    required this.roleId,
    required this.profileId,
    this.moduleId,
    this.nodeId,
    this.taskIds = const {},
    this.profile,
  });

  final String id;
  final String roleId;
  final String profileId;

  /// Set for a file-level role; null for a role held on a node.
  final String? moduleId;

  /// Set for a role held on a sector or a tower; null for a file-level role.
  final String? nodeId;

  /// The duties this person was handed here, for a role whose task list is a
  /// menu rather than a standing one ([ModuleRole.tasksAreAssigned]). Empty
  /// both when nothing was handed out and when there was nothing to hand out —
  /// the role says which.
  final Set<String> taskIds;

  /// Joined when the query embeds `profiles(...)`.
  final Profile? profile;

  factory ModuleMember.fromMap(Map<String, dynamic> map) {
    final joined = map['profiles'];
    return ModuleMember(
      id: map['id'] as String,
      roleId: map['role_id'] as String,
      profileId: map['profile_id'] as String,
      moduleId: map['module_id'] as String?,
      nodeId: map['node_id'] as String?,
      taskIds: {
        for (final t in ((map['module_assigned_tasks'] as List?) ?? const [])
            .cast<Map<String, dynamic>>())
          t['task_id'] as String,
      },
      profile: joined is Map<String, dynamic> ? Profile.fromMap(joined) : null,
    );
  }
}

/// One place inside a file: a sector, or a tower within it.
///
/// A node is either an entry from master data — a tower *is* a hotel — or, when
/// its level has no list, something named for this file alone ("القطاع الأول").
class ModuleNode {
  const ModuleNode({
    required this.id,
    required this.moduleId,
    required this.levelId,
    this.parentId,
    this.referenceItemId,
    this.label,
    this.sortOrder = 0,
    this.members = const [],
  });

  final String id;
  final String moduleId;
  final String levelId;

  /// The node this one sits inside — a tower's sector. Null at the top level.
  final String? parentId;

  final String? referenceItemId;
  final String? label;
  final int sortOrder;
  final List<ModuleMember> members;

  List<ModuleMember> membersOf(String roleId) =>
      members.where((m) => m.roleId == roleId).toList();

  Set<String> profileIdsOf(String roleId) =>
      members.where((m) => m.roleId == roleId).map((m) => m.profileId).toSet();

  ModuleNode withMembers(List<ModuleMember> members) => ModuleNode(
    id: id,
    moduleId: moduleId,
    levelId: levelId,
    parentId: parentId,
    referenceItemId: referenceItemId,
    label: label,
    sortOrder: sortOrder,
    members: members,
  );

  factory ModuleNode.fromMap(Map<String, dynamic> map) {
    final members = ((map['module_node_members'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ModuleMember.fromMap)
        .toList();
    return ModuleNode(
      id: map['id'] as String,
      moduleId: map['module_id'] as String,
      levelId: map['level_id'] as String,
      parentId: map['parent_id'] as String?,
      referenceItemId: map['reference_item_id'] as String?,
      label: map['label'] as String?,
      sortOrder: (map['sort_order'] as int?) ?? 0,
      members: members,
    );
  }
}

/// A file seen from the person's side: which file, where in it, and in what
/// capacity. One employee may hold roles in several files, and in several
/// places within one — a sector supervisor covers every tower under him.
class ModuleAssignment {
  const ModuleAssignment({
    required this.module,
    required this.roleName,
    this.placeName,
  });

  final OperationalModule module;
  final LocalizedName roleName;

  /// Where in the file — "البرج/الفندق: فندق الصفوة". Null for a role held on
  /// the file as a whole.
  final String? placeName;

  /// From `module_node_members`, which carries the node this role sits on.
  factory ModuleAssignment.fromNodeMap(Map<String, dynamic> map) {
    final node = (map['module_nodes'] as Map?)?.cast<String, dynamic>();
    final level = (node?['module_type_levels'] as Map?)?.cast<String, dynamic>();
    final item = (node?['reference_items'] as Map?)?.cast<String, dynamic>();

    // "البرج/الفندق: فندق الصفوة" — the level, then whichever of the two ways
    // of naming a node its level uses.
    final parts = [
      (level?['name_ar'] as String?) ?? '',
      (item?['name_ar'] as String?) ?? (node?['label'] as String?) ?? '',
    ].where((s) => s.isNotEmpty);

    return ModuleAssignment(
      module: OperationalModule.fromMap(
        (node?['modules'] as Map).cast<String, dynamic>(),
      ),
      roleName: LocalizedName.fromMap(
        (map['module_type_roles'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      placeName: parts.join(': '),
    );
  }

  /// From `module_members` — a role held on the file itself.
  factory ModuleAssignment.fromModuleMap(Map<String, dynamic> map) =>
      ModuleAssignment(
        module: OperationalModule.fromMap(
          (map['modules'] as Map).cast<String, dynamic>(),
        ),
        roleName: LocalizedName.fromMap(
          (map['module_type_roles'] as Map?)?.cast<String, dynamic>() ??
              const {},
        ),
      );
}

/// An operational file: one unit of season work, shaped by its type.
///
/// It has no title — a file is created once per season and its type names it.
/// It has a start date; its end is not a date but an event fixed by the type
/// ("ترحيل آخر حاج إلى المدينة المنورة").
class OperationalModule {
  const OperationalModule({
    required this.id,
    required this.moduleTypeId,
    required this.seasonId,
    this.startsOn,
    this.data = const {},
    this.isActive = false,
    this.seasonHijriYear,
    this.moduleTypeName,
    this.endCondition,
    this.createdAt,
  });

  final String id;
  final String moduleTypeId;
  final String seasonId;

  /// When work at the towers begins.
  final DateTime? startsOn;

  /// Field values keyed by [ModuleField.key].
  final Map<String, dynamic> data;

  /// Files stay invisible to their members until an admin activates them.
  final bool isActive;

  /// Joined for list rendering, so a card can be drawn without a second query.
  final int? seasonHijriYear;
  final LocalizedName? moduleTypeName;
  final LocalizedName? endCondition;
  final DateTime? createdAt;

  ModuleFile? fileAt(String key) => ModuleFile.fromJson(data[key]);

  factory OperationalModule.fromMap(Map<String, dynamic> map) {
    final season = map['seasons'];
    final type = (map['module_types'] as Map?)?.cast<String, dynamic>();
    return OperationalModule(
      id: map['id'] as String,
      moduleTypeId: map['module_type_id'] as String,
      seasonId: map['season_id'] as String,
      startsOn: map['starts_on'] == null
          ? null
          : DateTime.tryParse(map['starts_on'] as String),
      data: Map<String, dynamic>.from(
        (map['data'] as Map?) ?? const <String, dynamic>{},
      ),
      isActive: (map['is_active'] as bool?) ?? false,
      seasonHijriYear: season is Map ? season['hijri_year'] as int? : null,
      moduleTypeName: type == null ? null : LocalizedName.fromMap(type),
      endCondition: type == null || type['end_condition_ar'] == null
          ? null
          : LocalizedName.fromMap(type, prefix: 'end_condition'),
      createdAt: map['created_at'] == null
          ? null
          : DateTime.parse(map['created_at'] as String),
    );
  }
}
