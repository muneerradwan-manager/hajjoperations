import '../../../core/attachments/attachment.dart';

/// How a task is going. Mirrors the `task_state` enum (0083, renamed 0105).
///
/// Three rather than two: قيد التنفيذ is where most tasks actually sit, and a
/// checkbox that cannot say it makes the person holding it choose between
/// claiming they have finished and claiming they have not begun.
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

/// One task on one person's list (`personal_tasks`, 0105).
///
/// The whole design is one comparison: [createdBy] equal to [profileId] is a
/// task the person wrote for themselves — theirs entirely, to edit, delete,
/// move and evidence. Anything else was ASSIGNED, and the only thing its owner
/// may do to it is say how it is going.
///
/// No season, no operational file. A task belongs to a person the way check-in
/// belongs to a place (0098): the operational files describe their work, and
/// the tracking of it lives with whoever carries it.
class PersonalTask {
  const PersonalTask({
    required this.id,
    required this.profileId,
    required this.createdBy,
    required this.title,
    required this.state,
    this.description,
    this.dueOn,
    this.note,
    this.ownerName,
    this.authorName,
    this.updatedAt,
    this.attachments = const [],
  });

  final String id;

  /// Whose list it sits on.
  final String profileId;

  /// Who wrote it. Equal to [profileId] for the common case.
  final String createdBy;

  /// One language, whichever the writer was thinking in — this is a private
  /// list, not the Administration's paperwork.
  final String title;
  final String? description;

  final DateTime? dueOn;

  final TaskState state;

  /// What the owner wanted to say about how it is going.
  final String? note;

  /// The owner's name, embedded when someone reads what they assigned.
  final String? ownerName;

  /// The author's name, embedded so an assignee can see who is asking.
  final String? authorName;

  final DateTime? updatedAt;

  final List<StoredAttachment> attachments;

  /// Whether this task was assigned rather than self-written.
  bool get isAssigned => createdBy != profileId;

  PersonalTask withAttachments(List<StoredAttachment> attachments) =>
      PersonalTask(
        id: id,
        profileId: profileId,
        createdBy: createdBy,
        title: title,
        state: state,
        description: description,
        dueOn: dueOn,
        note: note,
        ownerName: ownerName,
        authorName: authorName,
        updatedAt: updatedAt,
        attachments: attachments,
      );

  static String? _name(Map<String, dynamic>? profile) {
    if (profile == null) return null;
    final name = [
      profile['first_name'],
      profile['father_name'],
      profile['surname'],
    ].whereType<String>().where((p) => p.isNotEmpty).join(' ');
    return name.isEmpty ? null : name;
  }

  factory PersonalTask.fromMap(Map<String, dynamic> map) => PersonalTask(
    id: map['id'] as String,
    profileId: map['profile_id'] as String,
    createdBy: map['created_by'] as String,
    title: map['title'] as String,
    description: map['description'] as String?,
    dueOn: map['due_on'] == null
        ? null
        : DateTime.tryParse(map['due_on'] as String),
    state: TaskState.fromDb(map['state'] as String?),
    note: map['note'] as String?,
    ownerName: _name((map['owner'] as Map?)?.cast<String, dynamic>()),
    authorName: _name((map['author'] as Map?)?.cast<String, dynamic>()),
    updatedAt: map['updated_at'] == null
        ? null
        : DateTime.parse(map['updated_at'] as String).toLocal(),
  );

  static (int done, int total) progressOf(List<PersonalTask> tasks) =>
      (tasks.where((t) => t.state.isDone).length, tasks.length);
}
