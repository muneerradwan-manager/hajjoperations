import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/storage_key.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/complaint.dart';

/// Everything this feature asks of the server.
///
/// Almost all of it goes through RPCs rather than through `from('complaints')`,
/// and that is the point rather than an accident: the employee a complaint is
/// about has no read on the table at all — row security cannot hide a column,
/// so it hides the row — and reaches his own case only through functions that
/// return the words and the files and no name. See migration 0079.
class ComplaintsRepository {
  static const _bucket = 'complaints';

  /// How much of the register one read carries. The table grows for as long as
  /// the mission does, and neither the list nor a person needs all of it.
  static const listLimit = 100;

  // ------------------------------------------------------------------ reading

  /// The register. [all] is everyone's and asks for `complaints.view`; without
  /// it, this is what the caller filed.
  Future<List<Complaint>> fetchList({
    bool all = false,
    ComplaintTarget? target,
    String? targetId,
    bool includeDismissed = true,
    String? query,
  }) async {
    final rows = await supabase.rpc(
      'complaints_list',
      params: {
        'p_scope': all ? 'all' : 'mine',
        'p_target_type': target?.name,
        'p_target_id': targetId,
        'p_include_dismissed': includeDismissed,
        'p_query': query,
        'p_limit': listLimit,
      },
    );
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(Complaint.fromListRow)
        .toList();
  }

  /// What was filed about the caller. Takes no id, because there is no other
  /// person it could be asked about — which is a stronger guarantee than a
  /// check that it is being asked about the right one.
  Future<List<Complaint>> fetchAgainstMe() async {
    final rows = await supabase.rpc(
      'complaints_against_me',
      params: {'p_limit': listLimit},
    );
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(Complaint.fromAgainstMeRow)
        .toList();
  }

  /// The complaint and every reply, in order, each bubble named only to a
  /// reader who may know it.
  Future<List<ComplaintMessage>> fetchThread(String complaintId) async {
    final rows = await supabase.rpc(
      'complaint_thread',
      params: {'p_complaint_id': complaintId},
    );
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(ComplaintMessage.fromMap)
        .toList();
  }

  /// Counts about one employee — never a name. Answers for the caller himself
  /// too, which is what the panel on his own page reads.
  Future<ComplaintStanding> fetchStanding(String profileId) async {
    final rows = await supabase.rpc(
      'complaints_against',
      params: {'p_profile_id': profileId},
    );
    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return const ComplaintStanding();
    return ComplaintStanding.fromMap(list.first);
  }

  /// A short-lived link to an attachment. Signing goes through row security, so
  /// nobody outside the complaint can mint one.
  Future<String> signedUrl(
    String path, {
    int expiresInSeconds = 3600,
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

  // ------------------------------------------------------------------ writing

  /// Files one, and returns its id.
  ///
  /// The row is written first because the files are filed under it: the storage
  /// rule finds the complaint by the first folder of the path, so an upload
  /// that arrives before the row does is refused. Same order as a notification
  /// (see `notifications_repository.dart`).
  Future<String> file({
    required ComplaintTarget target,
    String? targetId,
    required String body,
    List<PendingAttachment> attachments = const [],
  }) async {
    final id =
        await supabase.rpc(
              'file_complaint',
              params: {
                'p_target_type': target.name,
                'p_target_id': target.needsTarget ? targetId : null,
                'p_body': body,
              },
            )
            as String;

    await _upload(complaintId: id, attachments: attachments);
    return id;
  }

  /// Replies, and returns the reply's id. Unbounded in number: nothing here or
  /// in the database counts them.
  Future<String> reply({
    required String complaintId,
    required String body,
    List<PendingAttachment> attachments = const [],
  }) async {
    final replyId =
        await supabase.rpc(
              'reply_to_complaint',
              params: {'p_complaint_id': complaintId, 'p_body': body},
            )
            as String;

    await _upload(
      complaintId: complaintId,
      replyId: replyId,
      attachments: attachments,
    );
    return replyId;
  }

  Future<void> setLocked(String complaintId, bool locked) async {
    await supabase.rpc(
      'set_complaint_lock',
      params: {'p_complaint_id': complaintId, 'p_locked': locked},
    );
  }

  Future<void> setDismissed(
    String complaintId,
    bool dismissed, {
    String? reason,
  }) async {
    await supabase.rpc(
      'set_complaint_dismissed',
      params: {
        'p_complaint_id': complaintId,
        'p_dismissed': dismissed,
        'p_reason': reason,
      },
    );
  }

  Future<void> delete(String complaintId) async {
    await supabase.from('complaints').delete().eq('id', complaintId);
  }

  /// Uploads under the complaint, and under the reply when there is one.
  ///
  /// The reply's folder nests inside the complaint's so that the first folder
  /// is always the complaint — one read rule then covers everything it owns.
  /// Nothing in the path names the person who uploaded it: a path is readable
  /// by the employee the complaint is about.
  Future<void> _upload({
    required String complaintId,
    String? replyId,
    required List<PendingAttachment> attachments,
  }) async {
    if (attachments.isEmpty) return;
    final folder = replyId == null
        ? complaintId
        : '$complaintId/replies/$replyId';

    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < attachments.length; i++) {
      final attachment = attachments[i];
      // Prefixed with the index: two photos straight from a camera roll can
      // arrive with the same name, and the second must not replace the first.
      final path = '$folder/${i}_${storageKey(attachment.name, fallback: '$i')}';
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
        'complaint_id': complaintId,
        'reply_id': replyId,
        'kind': attachment.kind.name,
        'path': path,
        'name': attachment.name,
        'mime_type': attachment.mimeType,
        'size_bytes': attachment.file.lengthSync(),
        'sort_order': i,
      });
    }
    await supabase.from('complaint_attachments').insert(rows);
  }

  // ------------------------------------------------------- what may be complained about

  /// The employees a complaint may name. The directory itself is behind a
  /// permission; this is the lighter list anyone may pick from, which is the
  /// same one the assignment screens read.
  Future<List<({String id, String name, String? photoUrl})>>
  fetchEmployeeTargets({String? query}) async {
    final me = supabase.auth.currentUser?.id;
    var request = supabase
        .from('profiles')
        .select('id, first_name, father_name, surname, photo_url')
        .eq('account_status', 'approved');
    if (me != null) request = request.neq('id', me);
    final rows = await request.limit(listLimit);

    return (rows as List).cast<Map<String, dynamic>>().map((row) {
      final name = [
        row['first_name'],
        row['father_name'],
        row['surname'],
      ].whereType<String>().where((p) => p.trim().isNotEmpty).join(' ');
      return (
        id: row['id'] as String,
        name: name,
        photoUrl: row['photo_url'] as String?,
      );
    }).toList();
  }

  /// The operational files, the reports, or the master-data items of one set —
  /// whichever kind the picker is standing on.
  Future<List<({String id, String name})>> fetchTargets(
    ComplaintTarget target,
  ) async {
    switch (target) {
      case ComplaintTarget.module:
        final rows = await supabase
            .from('modules')
            .select('id, module_types(name_ar)')
            .limit(listLimit);
        return (rows as List).cast<Map<String, dynamic>>().map((row) {
          final type = row['module_types'] as Map<String, dynamic>?;
          return (
            id: row['id'] as String,
            name: (type?['name_ar'] as String?) ?? '',
          );
        }).toList();

      case ComplaintTarget.report:
        final rows = await supabase
            .from('reports')
            .select('id, title')
            .order('updated_at', ascending: false)
            .limit(listLimit);
        return (rows as List)
            .cast<Map<String, dynamic>>()
            .map((row) => (
                  id: row['id'] as String,
                  name: (row['title'] as String?) ?? '',
                ))
            .toList();

      case ComplaintTarget.hotel:
      case ComplaintTarget.cluster:
      case ComplaintTarget.group:
        // The set's code is the enum value's own name, which is the whole
        // reason those three are separate values rather than one 'reference'.
        final rows = await supabase
            .from('reference_items')
            .select('id, name_ar, reference_sets!inner(code)')
            .eq('reference_sets.code', '${target.name}s')
            .eq('is_active', true)
            .order('sort_order')
            .limit(listLimit);
        return (rows as List)
            .cast<Map<String, dynamic>>()
            .map((row) => (
                  id: row['id'] as String,
                  name: (row['name_ar'] as String?) ?? '',
                ))
            .toList();

      case ComplaintTarget.employee:
      case ComplaintTarget.other:
        return const [];
    }
  }
}
