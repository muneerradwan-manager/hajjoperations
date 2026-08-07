import 'package:equatable/equatable.dart';

import '../../../core/attachments/attachment.dart';
import '../../../core/bloc/safe_cubit.dart';
import '../../../core/offline/outbox.dart';
import '../../../core/offline/snapshots.dart';
import '../../../core/offline/save_outcome.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../seasons/data/seasons_repository.dart';
import '../data/tasks_outbox.dart';
import '../data/tasks_repository.dart';
import '../domain/personal_task.dart';

enum TasksStatus { loading, ready, error }

class TasksState extends Equatable {
  const TasksState({
    this.status = TasksStatus.loading,
    this.mine = const [],
    this.assignedByMe = const [],
    this.seasonId,
    this.error,
    this.savedAt,
  });

  final TasksStatus status;

  /// Everything on the viewer's list, self-written and assigned alike.
  final List<PersonalTask> mine;

  /// What the viewer wrote onto other people's lists. Empty for most people.
  final List<PersonalTask> assignedByMe;

  /// The season in force, for the roster the assignment picker reads. A task
  /// itself has no season; the ROSTER does — «من في البعثة هذا الموسم» is the
  /// question that page answers, along with which files each of them serves in.
  final String? seasonId;

  final String? error;

  /// When this list was last true, if it is being shown from disk.
  ///
  /// Null on a live read. Carrying the TIME rather than a bare `isStale` flag
  /// is the point: "a saved copy" invites the reader to guess how old, and
  /// standing at a gate with no signal, how old it is is the only thing they
  /// need in order to decide whether to trust it.
  final DateTime? savedAt;

  /// The viewer's own notes to themselves — full control.
  List<PersonalTask> get own => [
    for (final t in mine)
      if (!t.isAssigned) t,
  ];

  /// What somebody with the grant put on the viewer's list — state only.
  List<PersonalTask> get assignedToMe => [
    for (final t in mine)
      if (t.isAssigned) t,
  ];

  @override
  List<Object?> get props => [
    status,
    mine,
    assignedByMe,
    seasonId,
    error,
    savedAt,
  ];
}

class TasksCubit extends SafeCubit<TasksState> {
  TasksCubit(this._repo, {this.manage = false}) : super(const TasksState()) {
    load();
  }

  final TasksRepository _repo;

  /// Which of the two screens this cubit serves. «مهامي» reads the viewer's
  /// own list and nothing else; «إدارة المهام» — the permission-gated door —
  /// reads what the viewer wrote onto other people's lists.
  final bool manage;

  Future<void> load() async {
    try {
      // «مهامي» is the one of the two screens read in the field, so it is the
      // one that falls back to disk. «إسناد المهام» is desk work behind a
      // permission — nobody assigns tasks standing in Mina — and a saved copy
      // of what you put on other people's lists would be answering a question
      // nobody asked with no signal.
      final mineRead = manage
          ? const Cached(<PersonalTask>[])
          : await _repo.fetchMine();
      final mine = mineRead.data;
      final assigned = manage
          ? await _repo.fetchAssignedByMe()
          : const <PersonalTask>[];
      // The season is only the roster the picker reads; failing to find one
      // must not take the list of assignments down with it.
      String? seasonId = state.seasonId;
      if (manage && seasonId == null) {
        try {
          seasonId = (await SeasonsRepository().fetchCurrentSeason())?.id;
        } catch (_) {}
      }
      emit(
        TasksState(
          status: TasksStatus.ready,
          mine: mine,
          assignedByMe: assigned,
          seasonId: seasonId,
          savedAt: mineRead.savedAt,
        ),
      );
    } catch (e) {
      emit(TasksState(status: TasksStatus.error, error: e.toString()));
    }
  }

  /// Writes a task — the caller's own when [profileIds] is empty, onto every
  /// list it names otherwise. Returns null on success, else the failure.
  Future<String?> create({
    required String title,
    String? description,
    DateTime? dueOn,
    Set<String> profileIds = const {},
  }) async {
    try {
      await _repo.create(
        title: title,
        description: description,
        dueOn: dueOn,
        profileIds: profileIds,
      );
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> update({
    required String id,
    required String title,
    String? description,
    DateTime? dueOn,
  }) async {
    try {
      await _repo.update(
        id: id,
        title: title,
        description: description,
        dueOn: dueOn,
      );
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> delete(PersonalTask task) async {
    try {
      await _repo.delete(task);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Says how a task is going, with whatever note and evidence came with it.
  ///
  /// Kept for sending later if the network is what stopped it — this is the
  /// write made standing in front of the thing, and the photograph cannot be
  /// retaken (see [TasksOutbox]).
  Future<SaveOutcome> setTaskState(
    PersonalTask task,
    TaskState newState, {
    String? note,
    List<PendingAttachment> attachments = const [],
    List<StoredAttachment> removed = const [],
  }) async {
    try {
      final sent = await sendOrQueue(
        send: () async {
          await _repo.setState(taskId: task.id, state: newState, note: note);
          if (attachments.isNotEmpty || removed.isNotEmpty) {
            await _repo.setAttachments(
              taskId: task.id,
              attachments: attachments,
              removed: removed,
            );
          }
        },
        kind: TasksOutbox.state,
        payload: TasksOutbox.statePayload(
          taskId: task.id,
          state: newState,
          note: note,
          removed: removed,
        ),
        label: task.title,
        attachments: attachments,
      );
      if (sent) await load();
      return sent ? const SaveOutcome.sent() : const SaveOutcome.queued();
    } catch (e) {
      return SaveOutcome.failed(e.toString());
    }
  }

  /// The signed link the attachment views ask for.
  Future<String> signAttachment(
    String path, {
    bool download = false,
    String? downloadName,
  }) => _repo.signedUrl(path, download: download, downloadName: downloadName);

  /// The viewer, for telling "mine" from "assigned" without another read.
  static String? get viewerId => supabase.auth.currentUser?.id;
}
