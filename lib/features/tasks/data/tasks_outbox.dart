import '../../../core/attachments/attachment.dart';
import '../../../core/offline/outbox.dart';
import '../../../core/offline/outbox_entry.dart';
import '../domain/personal_task.dart';
import 'tasks_repository.dart';

/// The one write of a personal task that happens in the field: saying how it
/// is going, with the note and the evidence that came with it.
///
/// Writing the task itself — a title, a date — is done sitting down and can be
/// asked again. Moving it to منجز with a photograph is done standing in front
/// of the thing, and the photograph cannot be retaken. Same rule as the module
/// report (see [ModuleOutbox]): the state change is what queues.
abstract final class TasksOutbox {
  /// Named, never renamed: an entry written by last week's build must be read
  /// by this one.
  static const state = 'personal.task_state';

  static void register(Outbox outbox) {
    outbox.register(state, _sendState);
  }

  static Map<String, dynamic> statePayload({
    required String taskId,
    required TaskState state,
    String? note,
    List<StoredAttachment> removed = const [],
  }) => {
    'task_id': taskId,
    'state': state.dbName,
    'note': note,
    'removed': [for (final attachment in removed) attachment.toMap()],
  };

  static Future<void> _sendState(OutboxEntry entry) async {
    final repo = TasksRepository();
    final payload = entry.payload;
    final taskId = payload['task_id'] as String;

    await repo.setState(
      taskId: taskId,
      state: TaskState.fromDb(payload['state'] as String?),
      note: payload['note'] as String?,
    );

    final removed = [
      for (final row in (payload['removed'] as List?) ?? const [])
        StoredAttachment.fromMap((row as Map).cast<String, dynamic>()),
    ];
    if (entry.files.isEmpty && removed.isEmpty) return;

    await repo.setAttachments(
      taskId: taskId,
      attachments: [for (final file in entry.files) file.pending],
      removed: removed,
    );
  }
}
