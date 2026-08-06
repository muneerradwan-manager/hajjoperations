import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/attachments/attachment.dart';
import '../../../core/supabase/storage_key.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/personal_task.dart';

/// Reads and writes one person's task list (`personal_tasks`, 0105).
///
/// No module id anywhere in the file: this system has no relation to the
/// operational files. A task belongs to a person, and the two queries below
/// are the two directions that relation is read in — what is on MY list, and
/// what I put on somebody else's.
class TasksRepository {
  static const _bucket = 'tasks';

  /// The name columns of the two people a task can involve, embedded through
  /// the two foreign keys so neither list prints a uuid.
  static const _embeds =
      '*, '
      'owner:profiles!personal_tasks_profile_id_fkey'
      '(first_name, father_name, surname), '
      'author:profiles!personal_tasks_created_by_fkey'
      '(first_name, father_name, surname)';

  /// Everything on the caller's list — written by themselves and assigned to
  /// them alike — undone work first, then by due date, then newest.
  Future<List<PersonalTask>> fetchMine() async {
    final me = supabase.auth.currentUser?.id;
    if (me == null) return const [];
    final rows = await supabase
        .from('personal_tasks')
        .select(_embeds)
        .eq('profile_id', me)
        .order('created_at', ascending: false);
    return _withAttachments(_parse(rows));
  }

  /// What the caller wrote onto other people's lists, to follow up on. Empty
  /// for anyone who never assigned anything, which is most people.
  Future<List<PersonalTask>> fetchAssignedByMe() async {
    final me = supabase.auth.currentUser?.id;
    if (me == null) return const [];
    final rows = await supabase
        .from('personal_tasks')
        .select(_embeds)
        .eq('created_by', me)
        .neq('profile_id', me)
        .order('created_at', ascending: false);
    return _withAttachments(_parse(rows));
  }

  List<PersonalTask> _parse(dynamic rows) => ((rows as List?) ?? const [])
      .cast<Map<String, dynamic>>()
      .map(PersonalTask.fromMap)
      .toList();

  /// The evidence, in one round trip for the whole list.
  Future<List<PersonalTask>> _withAttachments(List<PersonalTask> tasks) async {
    if (tasks.isEmpty) return tasks;
    final files = await supabase
        .from('personal_task_attachments')
        .select()
        .inFilter('task_id', [for (final t in tasks) t.id])
        .order('sort_order');
    if ((files as List).isEmpty) return tasks;

    final byTask = <String, List<StoredAttachment>>{};
    for (final row in files.cast<Map<String, dynamic>>()) {
      (byTask[row['task_id'] as String] ??= []).add(
        StoredAttachment.fromMap(row),
      );
    }
    return [
      for (final task in tasks)
        if (byTask[task.id] case final attachments?)
          task.withAttachments(attachments)
        else
          task,
    ];
  }

  /// Writes a task — onto the caller's own list when [profileIds] is empty,
  /// onto everybody it names otherwise (which the database allows only to
  /// `tasks.assign`).
  ///
  /// Several people, one statement: assigning "استلام كشوف الحجاج" to six
  /// supervisors is ONE decision, and six round trips would let it half-fail —
  /// four notified, two not, and nothing to say which. Each named person gets
  /// a row of their own, because from there each carries it separately.
  ///
  /// Returns the new rows' ids, in the order they were written; evidence is
  /// stored under them.
  Future<List<String>> create({
    required String title,
    String? description,
    DateTime? dueOn,
    Set<String> profileIds = const {},
  }) async {
    final me = supabase.auth.currentUser?.id;
    final owners = profileIds.isEmpty ? <String?>[me] : profileIds.toList();
    final rows = await supabase
        .from('personal_tasks')
        .insert([
          for (final owner in owners)
            {
              'profile_id': owner,
              'created_by': me,
              'title': title,
              'description': (description == null || description.isEmpty)
                  ? null
                  : description,
              'due_on': dueOn == null ? null : _asDate(dueOn),
            },
        ])
        .select('id');
    return [
      for (final row in (rows as List).cast<Map<String, dynamic>>())
        row['id'] as String,
    ];
  }

  /// Corrects a task the caller has full control of — their own, or one they
  /// assigned. The owner of an ASSIGNED task never reaches here; the database
  /// refuses them, and the screen does not offer it.
  Future<void> update({
    required String id,
    required String title,
    String? description,
    DateTime? dueOn,
  }) async {
    await supabase
        .from('personal_tasks')
        .update({
          'title': title,
          'description': (description == null || description.isEmpty)
              ? null
              : description,
          'due_on': dueOn == null ? null : _asDate(dueOn),
        })
        .eq('id', id);
  }

  /// Removes a task, its evidence rows (`cascade`) and their files. The files
  /// first: once the row is gone, the storage rule that allows their deletion
  /// has nothing to answer from.
  Future<void> delete(PersonalTask task) async {
    if (task.attachments.isNotEmpty) {
      await supabase.storage.from(_bucket).remove([
        for (final a in task.attachments) a.path,
      ]);
    }
    await supabase.from('personal_tasks').delete().eq('id', task.id);
  }

  /// Says how a task is going. Through an RPC rather than a plain update
  /// because for an assigned task this is the ONE write its owner may make,
  /// and the row policy that guards the rest cannot see columns.
  Future<void> setState({
    required String taskId,
    required TaskState state,
    String? note,
  }) async {
    await supabase.rpc(
      'set_personal_task_state',
      params: {
        'p_task_id': taskId,
        'p_state': state.dbName,
        'p_note': note,
      },
    );
  }

  /// Files evidence against a task, and takes back whatever was removed.
  Future<void> setAttachments({
    required String taskId,
    List<PendingAttachment> attachments = const [],
    List<StoredAttachment> removed = const [],
  }) async {
    for (final attachment in removed) {
      await supabase
          .from('personal_task_attachments')
          .delete()
          .eq('id', attachment.id);
      await supabase.storage.from(_bucket).remove([attachment.path]);
    }
    if (attachments.isEmpty) return;

    // Where the next one starts, so filing twice does not overwrite what is
    // already there — two photos off one camera roll can share a name.
    final existing = await supabase
        .from('personal_task_attachments')
        .select('sort_order')
        .eq('task_id', taskId)
        .order('sort_order', ascending: false)
        .limit(1);
    var next =
        ((existing as List).firstOrNull as Map<String, dynamic>?)?['sort_order']
            as int? ??
        -1;

    final rows = <Map<String, dynamic>>[];
    for (final attachment in attachments) {
      next++;
      final path =
          '$taskId/${next}_${storageKey(attachment.name, fallback: '$next')}';
      await supabase.storage
          .from(_bucket)
          .upload(
            path,
            attachment.file,
            fileOptions: FileOptions(
              upsert: true,
              contentType: attachment.mimeType,
            ),
          );
      rows.add({
        'task_id': taskId,
        'kind': attachment.kind.name,
        'path': path,
        'name': attachment.name,
        'mime_type': attachment.mimeType,
        'size_bytes': attachment.file.lengthSync(),
        'sort_order': next,
      });
    }
    await supabase.from('personal_task_attachments').insert(rows);
  }

  /// A short-lived link to an attachment. Signing goes through row security,
  /// so a link only ever comes back for a file the caller may see.
  Future<String> signedUrl(
    String path, {
    int expiresInSeconds = 600,
    bool download = false,
    String? downloadName,
  }) {
    return supabase.storage
        .from(_bucket)
        .createSignedUrl(path, expiresInSeconds)
        .then((url) {
          if (!download) return url;
          final separator = url.contains('?') ? '&' : '?';
          final name = Uri.encodeComponent(downloadName ?? '');
          return '$url${separator}download${name.isEmpty ? '' : '=$name'}';
        });
  }

  String _asDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
