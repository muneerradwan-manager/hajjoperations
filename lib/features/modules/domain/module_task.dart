import '../../../core/attachments/attachment.dart';
import '../../../core/l10n/localized_name.dart';

/// What a duty is attached to. Never a person by default — that is the whole
/// point of the three, and [personal] is the exception the other two exist to
/// make rare.
///
/// Mirrors the `module_task_scope` enum (0083).
enum TaskScope {
  /// The file's own work. Every member sees the same list and any of them may
  /// move it along — ملف المتابعة والتقييم is nothing but this.
  file,

  /// The duties of a post. Whoever holds مشرف البرج carries them by holding it;
  /// replacing the man leaves the list, and its progress, exactly where it was.
  role,

  /// One duty written for one man, by exception. Visible to him and to whoever
  /// runs the file, and to nobody else.
  personal;

  static TaskScope fromDb(String? value) => switch (value) {
    'role' => TaskScope.role,
    'personal' => TaskScope.personal,
    _ => TaskScope.file,
  };

  String get dbName => switch (this) {
    TaskScope.file => 'file',
    TaskScope.role => 'role',
    TaskScope.personal => 'personal',
  };
}

/// How a duty is going. Mirrors `module_task_state` (0083).
///
/// Three rather than two: قيد التنفيذ is where most duties in a season actually
/// sit, and a checkbox that cannot say it makes the man holding it choose
/// between claiming he has finished and claiming he has not begun.
enum TaskState {
  notStarted,
  inProgress,
  done;

  static TaskState fromDb(String? value) => switch (value) {
    'in_progress' => TaskState.inProgress,
    'done' => TaskState.done,
    _ => TaskState.notStarted,
  };

  String get dbName => switch (this) {
    TaskState.notStarted => 'not_started',
    TaskState.inProgress => 'in_progress',
    TaskState.done => 'done',
  };

  bool get isDone => this == TaskState.done;
}

/// One duty on one board: what it is, where it applies, and how it is going.
///
/// A line is the join of a definition — from the type's catalog or written on
/// this file — and a state. The database assembles it (`module_task_board`),
/// because the middle scope cannot be assembled anywhere else: "the duties of
/// my role" means, for each post I hold, at each برج I hold it in, and a client
/// would need the roster, the tree and the catalog in hand to work it out.
class ModuleTaskLine {
  const ModuleTaskLine({
    required this.scope,
    required this.title,
    required this.state,
    this.statusId,
    this.typeTaskId,
    this.moduleTaskId,
    this.roleId,
    this.nodeId,
    this.profileId,
    this.groupId,
    this.description,
    this.dueOn,
    this.sortOrder = 0,
    this.note,
    this.updatedBy,
    this.updatedByName,
    this.updatedAt,
    this.canUpdate = false,
    this.attachments = const [],
  });

  /// The state row, once one exists. Null until somebody has touched this duty
  /// — absence IS [TaskState.notStarted], so a file of two hundred duties costs
  /// no rows at all until work starts.
  final String? statusId;

  /// The definition: one of the two is set, never both. A duty from the type's
  /// standing catalog, or one written on this file for this season.
  final String? typeTaskId;
  final String? moduleTaskId;

  final TaskScope scope;

  /// The post, for [TaskScope.role].
  final String? roleId;

  /// The برج or القطاع the post is held at, for a role held at a level. Null
  /// for a role held on the file itself — there the file is the place.
  final String? nodeId;

  /// The man, for [TaskScope.personal].
  final String? profileId;

  /// The stage of the work (`module_type_task_groups`), when the type has any.
  final String? groupId;

  final LocalizedName title;
  final LocalizedName? description;

  /// When it is wanted by. Only a duty written on a file can carry one: the
  /// catalog is written once for every season and a date in it would be a date
  /// in the wrong year.
  final DateTime? dueOn;

  final int sortOrder;

  final TaskState state;

  /// What the man wanted to say about it — "الغرف ٤٠١ و٤٠٢ مغلقة".
  final String? note;

  final String? updatedBy;
  final String? updatedByName;
  final DateTime? updatedAt;

  /// Whether the READER may move this line, which is not the same as whether it
  /// is on his board: a supervisor reading a colleague's duties sees them all
  /// and may touch only what the three rules let him.
  final bool canUpdate;

  /// The evidence filed against it, fetched alongside the board.
  final List<StoredAttachment> attachments;

  /// What identifies this line to the app: the duty, and the place or person it
  /// applies at. The same catalog duty appears once per برج, so the duty's id
  /// alone would collide across them.
  String get key => [
    typeTaskId ?? moduleTaskId ?? '',
    nodeId ?? '',
    profileId ?? '',
  ].join('/');

  /// Whether this duty was written on the file rather than taken from the
  /// type's catalog — the only kind that can be edited or removed here.
  bool get isOwnedByFile => moduleTaskId != null;

  ModuleTaskLine withAttachments(List<StoredAttachment> attachments) =>
      ModuleTaskLine(
        scope: scope,
        title: title,
        state: state,
        statusId: statusId,
        typeTaskId: typeTaskId,
        moduleTaskId: moduleTaskId,
        roleId: roleId,
        nodeId: nodeId,
        profileId: profileId,
        groupId: groupId,
        description: description,
        dueOn: dueOn,
        sortOrder: sortOrder,
        note: note,
        updatedBy: updatedBy,
        updatedByName: updatedByName,
        updatedAt: updatedAt,
        canUpdate: canUpdate,
        attachments: attachments,
      );

  factory ModuleTaskLine.fromMap(Map<String, dynamic> map) => ModuleTaskLine(
    statusId: map['status_id'] as String?,
    typeTaskId: map['type_task_id'] as String?,
    moduleTaskId: map['module_task_id'] as String?,
    scope: TaskScope.fromDb(map['scope'] as String?),
    roleId: map['role_id'] as String?,
    nodeId: map['node_id'] as String?,
    profileId: map['profile_id'] as String?,
    groupId: map['group_id'] as String?,
    title: LocalizedName.fromMap(map, prefix: 'title'),
    description: map['description_ar'] == null
        ? null
        : LocalizedName.fromMap(map, prefix: 'description'),
    dueOn: map['due_on'] == null
        ? null
        : DateTime.tryParse(map['due_on'] as String),
    sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    state: TaskState.fromDb(map['state'] as String?),
    note: map['note'] as String?,
    updatedBy: map['updated_by'] as String?,
    updatedByName: map['updated_by_name'] as String?,
    updatedAt: map['updated_at'] == null
        ? null
        : DateTime.parse(map['updated_at'] as String).toLocal(),
    canUpdate: (map['can_update'] as bool?) ?? false,
  );
}

/// The duties of one post at one place — "مشرف البرج، برج الصفوة" — and what
/// they add up to.
///
/// One group per place rather than per post, because that is where the work
/// happens: the same man running three towers owes the same three duties three
/// times over, and one merged list would let two of them disappear behind the
/// third.
class RoleTaskGroup {
  const RoleTaskGroup({
    required this.roleId,
    required this.nodeId,
    required this.tasks,
  });

  final String roleId;

  /// Null for a post held on the file itself.
  final String? nodeId;

  final List<ModuleTaskLine> tasks;

  String get key => '$roleId/${nodeId ?? ''}';
}

/// What one person should see when he opens a file, in the order he should see
/// it: the file's duties, then his post's, then his own.
class ModuleTaskBoard {
  const ModuleTaskBoard({this.lines = const []});

  static const empty = ModuleTaskBoard();

  final List<ModuleTaskLine> lines;

  bool get isEmpty => lines.isEmpty;

  List<ModuleTaskLine> get fileTasks =>
      lines.where((t) => t.scope == TaskScope.file).toList();

  List<ModuleTaskLine> get personalTasks =>
      lines.where((t) => t.scope == TaskScope.personal).toList();

  /// The role duties, gathered by the place they are owed at, in the order the
  /// board returned them.
  List<RoleTaskGroup> get roleGroups {
    final groups = <String, List<ModuleTaskLine>>{};
    final order = <String>[];
    for (final task in lines) {
      if (task.scope != TaskScope.role || task.roleId == null) continue;
      final key = '${task.roleId}/${task.nodeId ?? ''}';
      if (!groups.containsKey(key)) order.add(key);
      (groups[key] ??= []).add(task);
    }
    return [
      for (final key in order)
        RoleTaskGroup(
          roleId: groups[key]!.first.roleId!,
          nodeId: groups[key]!.first.nodeId,
          tasks: groups[key]!,
        ),
    ];
  }

  /// The personal duties, gathered by the man they were written for. One group
  /// on a reader's own board; one per man when the whole file is being read.
  Map<String, List<ModuleTaskLine>> get personalByProfile {
    final byProfile = <String, List<ModuleTaskLine>>{};
    for (final task in personalTasks) {
      final id = task.profileId;
      if (id != null) (byProfile[id] ??= []).add(task);
    }
    return byProfile;
  }

  static (int done, int total) progressOf(List<ModuleTaskLine> tasks) =>
      (tasks.where((t) => t.state.isDone).length, tasks.length);

  (int done, int total) get progress => progressOf(lines);
}
