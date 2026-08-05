import '../../../core/attachments/attachment.dart';
import '../../../core/offline/outbox.dart';
import '../../../core/offline/outbox_entry.dart';
import '../domain/module_task.dart';
import 'modules_repository.dart';

/// The two writes of an operational file that happen in the field, and what it
/// takes to send them again later.
///
/// Only two, and the choice is the point. Everything else this app writes —
/// building a file, assigning its members, editing the catalog, deciding an
/// approval — is done sitting down, on a connection, by somebody who can be
/// told to try again. These two are done standing in a camp: **moving a duty
/// along**, and **filing the file's report**. They are also the two that carry
/// photographs, and a photograph of a camp at eight in the evening cannot be
/// retaken at eleven.
///
/// The knowledge of how to send them lives here rather than in the queue,
/// because the queue must not know what a module is; and beside the repository
/// rather than in the cubit, because a cubit belongs to a screen and this has
/// to run when there is no screen.
abstract final class ModuleOutbox {
  /// Names, not numbers, and never renamed: an entry written by last week's
  /// build is read by this one, and a kind it cannot match is work it cannot
  /// send.
  static const taskState = 'module.task_state';
  static const report = 'module.report';

  static void register(Outbox outbox) {
    outbox.register(taskState, _sendTaskState);
    outbox.register(report, _sendReport);
  }

  // ------------------------------------------------------------------ duties

  static Map<String, dynamic> taskStatePayload({
    required String moduleId,
    required TaskState state,
    required ModuleTaskLine line,
    String? note,
    List<StoredAttachment> removed = const [],
  }) => {
    'module_id': moduleId,
    'state': state.dbName,
    'type_task_id': line.typeTaskId,
    'module_task_id': line.moduleTaskId,
    'node_id': line.nodeId,
    'profile_id': line.profileId,
    'note': note,
    'removed': [for (final attachment in removed) attachment.toMap()],
  };

  static Future<void> _sendTaskState(OutboxEntry entry) async {
    final repo = ModulesRepository();
    final payload = entry.payload;
    final moduleId = payload['module_id'] as String;

    // Exactly the sequence the online path runs, for exactly the reason: the
    // state row has to exist before storage will accept a file under its id.
    final statusId = await repo.setTaskState(
      moduleId: moduleId,
      state: TaskState.fromDb(payload['state'] as String?),
      typeTaskId: payload['type_task_id'] as String?,
      moduleTaskId: payload['module_task_id'] as String?,
      nodeId: payload['node_id'] as String?,
      profileId: payload['profile_id'] as String?,
      note: payload['note'] as String?,
    );

    final removed = _removed(payload);
    if (entry.files.isEmpty && removed.isEmpty) return;

    await repo.setTaskAttachments(
      moduleId: moduleId,
      statusId: statusId,
      attachments: [for (final file in entry.files) file.pending],
      removed: removed,
    );
  }

  // ----------------------------------------------------------------- reports

  static Map<String, dynamic> reportPayload({
    required String moduleId,
    String? notes,
    List<StoredAttachment> removed = const [],
  }) => {
    'module_id': moduleId,
    'notes': notes,
    'removed': [for (final attachment in removed) attachment.toMap()],
  };

  static Future<void> _sendReport(OutboxEntry entry) async {
    final repo = ModulesRepository();
    final payload = entry.payload;

    await repo.submitReport(
      moduleId: payload['module_id'] as String,
      notes: payload['notes'] as String?,
      attachments: [for (final file in entry.files) file.pending],
      removed: _removed(payload),
    );
  }

  static List<StoredAttachment> _removed(Map<String, dynamic> payload) => [
    for (final row in (payload['removed'] as List?) ?? const [])
      StoredAttachment.fromMap((row as Map).cast<String, dynamic>()),
  ];
}
