import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/storage_key.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../profile/domain/profile.dart';
import '../domain/assignable_employee.dart';
import '../domain/module_type.dart';
import '../domain/operational_module.dart';
import '../domain/reference_item.dart';

/// Data access for operational files, their type catalog and the master data
/// behind their dropdowns. Visibility is enforced by RLS (0017, 0024) — a plain
/// select already returns only what the caller is allowed to see.
class ModulesRepository {
  static const _bucket = 'modules';

  /// What a file needs joined to be rendered: the type that names it and states
  /// how it ends, and the season it belongs to.
  static const _moduleColumns =
      '*, '
      'module_types(name_ar, name_en, end_condition_ar, end_condition_en), '
      'seasons(hijri_year)';

  /// A type's whole schema: its fields, the levels of its tree, the duties of
  /// the file itself and the stages they fall into, and every role with the
  /// duties that belong to that post.
  ///
  /// `module_type_tasks` is embedded twice on purpose, once down each of the two
  /// paths that reach it — a duty belongs either to the file or to one of its
  /// roles, so neither embed sees the other's rows.
  static const _typeColumns =
      '*, '
      'module_type_fields(*), '
      'module_type_levels(*), '
      'module_type_task_groups(*), '
      'module_type_tasks(*), '
      'module_type_roles(*, module_type_tasks(*))';

  // ------------------------------------------------------------- type catalog

  /// The file types available for creation, with their full schema in one round
  /// trip.
  Future<List<ModuleType>> fetchModuleTypes({bool activeOnly = true}) async {
    var query = supabase.from('module_types').select(_typeColumns);
    if (activeOnly) query = query.eq('is_active', true);
    final rows = await query.order('sort_order');
    return (rows as List)
        .map((r) => ModuleType.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<ModuleType?> fetchModuleType(String id) async {
    final row = await supabase
        .from('module_types')
        .select(_typeColumns)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : ModuleType.fromMap(row);
  }

  // ----------------------------------------------------------------- files

  /// Every file the caller may see: managers get all of them, everyone else
  /// gets the activated files they hold a role in.
  ///
  /// [seasonId] narrows it to one season, which is what the list wants: the
  /// season in force is a choice the admin makes, and everything shown under it
  /// should belong to it. Null returns every season, for callers that mean to
  /// look across them.
  Future<List<OperationalModule>> fetchModules({String? seasonId}) async {
    var query = supabase.from('modules').select(_moduleColumns);
    if (seasonId != null) query = query.eq('season_id', seasonId);
    final rows = await query.order('created_at', ascending: false);
    final modules = (rows as List)
        .map((r) => OperationalModule.fromMap(r as Map<String, dynamic>))
        .toList();
    // Newest season first, then newest file inside it.
    modules.sort((a, b) {
      final byYear = (b.seasonHijriYear ?? 0).compareTo(a.seasonHijriYear ?? 0);
      if (byYear != 0) return byYear;
      return (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0));
    });
    return modules;
  }

  Future<OperationalModule?> fetchModule(String id) async {
    final row = await supabase
        .from('modules')
        .select(_moduleColumns)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : OperationalModule.fromMap(row);
  }

  /// A file of a kind exists at most once in a season. Consulted before
  /// offering to create one, so the type is simply not on offer twice.
  Future<OperationalModule?> fetchModuleOfType({
    required String moduleTypeId,
    required String seasonId,
  }) async {
    final row = await supabase
        .from('modules')
        .select(_moduleColumns)
        .eq('module_type_id', moduleTypeId)
        .eq('season_id', seasonId)
        .maybeSingle();
    return row == null ? null : OperationalModule.fromMap(row);
  }

  /// Creates a file in the draft (inactive) state and returns its id. It gets
  /// no name: the type names it.
  Future<String> createModule({
    required String moduleTypeId,
    required String seasonId,
    required DateTime startsOn,
    required Map<String, dynamic> data,
    ReportCadence? reportCadence,
  }) async {
    final row = await supabase
        .from('modules')
        .insert({
          'module_type_id': moduleTypeId,
          'season_id': seasonId,
          'starts_on': _asDate(startsOn),
          'data': data,
          'report_cadence': (reportCadence ?? ReportCadence.none).name,
          'created_by': supabase.auth.currentUser?.id,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> updateModule(
    String id, {
    required DateTime startsOn,
    required Map<String, dynamic> data,
    ReportCadence? reportCadence,
  }) async {
    await supabase
        .from('modules')
        .update({
          'starts_on': _asDate(startsOn),
          'data': data,
          if (reportCadence != null) 'report_cadence': reportCadence.name,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  static String _asDate(DateTime value) =>
      value.toIso8601String().split('T').first;

  /// Activating a module is what makes it visible to its members — the database
  /// notifies everyone already assigned (trigger `modules_notify_activation`).
  Future<void> setActive(String id, bool isActive) async {
    await supabase
        .from('modules')
        .update({
          'is_active': isActive,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> deleteModule(String id) async {
    await supabase.from('modules').delete().eq('id', id);
  }

  // --------------------------------------------------------------- reports

  /// The reports filed against a file. RLS decides the scope: a member sees
  /// their own, a manager sees everyone's.
  Future<List<ModuleReport>> fetchReports(String moduleId) async {
    final rows = await supabase
        .from('module_reports')
        .select(
          '*, module_report_attachments(*), '
          'profiles:author_id(*, job_titles(name, name_en))',
        )
        .eq('module_id', moduleId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => ModuleReport.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Files a report for the period the file is currently in: what was attached,
  /// and whatever notes came with it.
  ///
  /// The period is worked out in the database, not here: a phone with a wrong
  /// clock, or in another timezone, would otherwise decide for itself which day
  /// it was reporting for. Filing twice in one period edits the first — which is
  /// why [removed] exists, so a photo of the wrong tower can be taken back off.
  Future<void> submitReport({
    required String moduleId,
    String? notes,
    List<PendingAttachment> attachments = const [],
    List<StoredAttachment> removed = const [],
  }) async {
    // The row first: the files are stored under its id, and storage will not
    // accept them until it exists.
    final reportId =
        await supabase.rpc(
              'submit_module_report',
              params: {'p_module_id': moduleId, 'p_body': notes},
            )
            as String;

    for (final attachment in removed) {
      await supabase.from('module_report_attachments').delete().eq(
        'id',
        attachment.id,
      );
      await supabase.storage.from(_bucket).remove([attachment.path]);
    }

    if (attachments.isEmpty) return;

    // Where the next one starts, so re-filing does not overwrite what is
    // already there — two photos off one camera roll can share a name, and the
    // second must not replace the first.
    final existing = await supabase
        .from('module_report_attachments')
        .select('sort_order')
        .eq('report_id', reportId)
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
          '$moduleId/reports/$reportId/${next}_'
          '${storageKey(attachment.name, fallback: '$next')}';
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
        'report_id': reportId,
        'kind': attachment.kind.name,
        'path': path,
        'name': attachment.name,
        'mime_type': attachment.mimeType,
        'size_bytes': attachment.file.lengthSync(),
        'sort_order': next,
      });
    }
    await supabase.from('module_report_attachments').insert(rows);
  }

  // ----------------------------------------------------------------- nodes

  /// The whole tree of a file — sectors and the towers under them — with every
  /// role holder and their contact details, in one query. A file is small
  /// enough (tens of towers) that paging it would cost more than it saves.
  Future<List<ModuleNode>> fetchNodes(String moduleId) async {
    final rows = await supabase
        .from('module_nodes')
        // Embedded through `profile_id` explicitly: the table also points at
        // profiles via `assigned_by`, and a bare `profiles(...)` is ambiguous.
        .select(
          '*, module_node_members(*, module_assigned_tasks(task_id), '
          'profiles:profile_id(*, job_titles(name, name_en)))',
        )
        .eq('module_id', moduleId)
        .order('sort_order');
    return (rows as List)
        .map((r) => ModuleNode.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Adds a sector or a tower and returns its id. [referenceItemId] is set when
  /// the level draws from master data (a tower is a hotel); [label] when it does
  /// not (a sector is named here).
  Future<String> createNode({
    required String moduleId,
    required String levelId,
    String? parentId,
    String? referenceItemId,
    String? label,
    int sortOrder = 0,
  }) async {
    final row = await supabase
        .from('module_nodes')
        .insert({
          'module_id': moduleId,
          'level_id': levelId,
          'parent_id': parentId,
          'reference_item_id': referenceItemId,
          'label': label,
          'sort_order': sortOrder,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> updateNode(
    String id, {
    String? referenceItemId,
    String? label,
  }) async {
    await supabase
        .from('module_nodes')
        .update({'reference_item_id': referenceItemId, 'label': label})
        .eq('id', id);
  }

  /// Removes a sector or tower. Its towers, and everyone assigned anywhere
  /// beneath it, go with it (`on delete cascade`).
  Future<void> deleteNode(String id) async {
    await supabase.from('module_nodes').delete().eq('id', id);
  }

  // --------------------------------------------------------------- members

  /// The people holding a role on the file itself, rather than on one of its
  /// nodes — the whole roster of a file with no tree, and each one's duties.
  Future<List<ModuleMember>> fetchMembers(String moduleId) async {
    final rows = await supabase
        .from('module_members')
        .select(
          '*, module_assigned_tasks(task_id), '
          'profiles:profile_id(*, job_titles(name, name_en))',
        )
        .eq('module_id', moduleId);
    final members = (rows as List)
        .map((r) => ModuleMember.fromMap(r as Map<String, dynamic>))
        .toList();
    members.sort(
      (a, b) => (a.profile?.fullName ?? '').compareTo(b.profile?.fullName ?? ''),
    );
    return members;
  }

  /// Every file this employee holds a role in, and where in it, newest season
  /// first. One person serves in several places at once — a sector supervisor
  /// covers every tower under him — so this is a list, not a single value.
  ///
  /// `!inner` keeps the joins honest: a file the caller may not see is dropped
  /// rather than surfacing as a membership with nothing behind it.
  Future<List<ModuleAssignment>> fetchAssignmentsForProfile(
    String profileId,
  ) async {
    final nodeRows = await supabase
        .from('module_node_members')
        .select('''
          module_type_roles!inner(name_ar, name_en),
          module_nodes!inner(
            label,
            module_type_levels!inner(name_ar, name_en),
            reference_items(name_ar, name_en),
            modules!inner($_moduleColumns)
          )
        ''')
        .eq('profile_id', profileId);

    final moduleRows = await supabase
        .from('module_members')
        .select('''
          module_type_roles!inner(name_ar, name_en),
          modules!inner($_moduleColumns)
        ''')
        .eq('profile_id', profileId);

    final assignments = [
      for (final r in (nodeRows as List).cast<Map<String, dynamic>>())
        ModuleAssignment.fromNodeMap(r),
      for (final r in (moduleRows as List).cast<Map<String, dynamic>>())
        ModuleAssignment.fromModuleMap(r),
    ];
    assignments.sort((a, b) {
      final byYear = (b.module.seasonHijriYear ?? 0).compareTo(
        a.module.seasonHijriYear ?? 0,
      );
      if (byYear != 0) return byYear;
      return (a.placeName ?? '').compareTo(b.placeName ?? '');
    });
    return assignments;
  }

  /// Replaces the people holding [roleId] on a node. Members that stay are left
  /// untouched so they are not re-notified.
  Future<void> setNodeRoleMembers({
    required String nodeId,
    required String roleId,
    required Set<String> profileIds,
  }) async {
    final existing = await supabase
        .from('module_node_members')
        .select('profile_id')
        .eq('node_id', nodeId)
        .eq('role_id', roleId);
    final current = (existing as List)
        .map((r) => r['profile_id'] as String)
        .toSet();

    final removed = current.difference(profileIds);
    if (removed.isNotEmpty) {
      await supabase
          .from('module_node_members')
          .delete()
          .eq('node_id', nodeId)
          .eq('role_id', roleId)
          .inFilter('profile_id', removed.toList());
    }

    final added = profileIds.difference(current);
    if (added.isNotEmpty) {
      await supabase.from('module_node_members').insert([
        for (final id in added)
          {
            'node_id': nodeId,
            'role_id': roleId,
            'profile_id': id,
            'assigned_by': supabase.auth.currentUser?.id,
          },
      ]);
    }
  }

  /// The same, for a file with no tree: replaces the people holding [roleId] on
  /// the file itself. Members that stay are left untouched, so they are neither
  /// re-notified nor stripped of the duties they were already handed — those
  /// hang off the membership row and would go with it.
  Future<void> setModuleRoleMembers({
    required String moduleId,
    required String roleId,
    required Set<String> profileIds,
  }) async {
    final existing = await supabase
        .from('module_members')
        .select('profile_id')
        .eq('module_id', moduleId)
        .eq('role_id', roleId);
    final current = (existing as List)
        .map((r) => r['profile_id'] as String)
        .toSet();

    final removed = current.difference(profileIds);
    if (removed.isNotEmpty) {
      await supabase
          .from('module_members')
          .delete()
          .eq('module_id', moduleId)
          .eq('role_id', roleId)
          .inFilter('profile_id', removed.toList());
    }

    final added = profileIds.difference(current);
    if (added.isNotEmpty) {
      await supabase.from('module_members').insert([
        for (final id in added)
          {
            'module_id': moduleId,
            'role_id': roleId,
            'profile_id': id,
            'assigned_by': supabase.auth.currentUser?.id,
          },
      ]);
    }
  }

  /// Hands one member the duties that are his, and takes back the ones that are
  /// no longer. Diffed rather than wiped and rewritten so that who assigned what,
  /// and when, survives an unrelated edit.
  Future<void> setAssignedTasks({
    required String memberId,
    required Set<String> taskIds,
  }) async {
    final existing = await supabase
        .from('module_assigned_tasks')
        .select('task_id')
        .eq('member_id', memberId);
    final current = (existing as List)
        .map((r) => r['task_id'] as String)
        .toSet();

    final removed = current.difference(taskIds);
    if (removed.isNotEmpty) {
      await supabase
          .from('module_assigned_tasks')
          .delete()
          .eq('member_id', memberId)
          .inFilter('task_id', removed.toList());
    }

    final added = taskIds.difference(current);
    if (added.isNotEmpty) {
      await supabase.from('module_assigned_tasks').insert([
        for (final id in added)
          {
            'member_id': memberId,
            'task_id': id,
            'assigned_by': supabase.auth.currentUser?.id,
          },
      ]);
    }
  }

  // ----------------------------------------------------------- master data

  /// The master-data lists with their item schema and their entries.
  ///
  /// The schema comes back in its own query rather than as an embed:
  /// `reference_set_fields` points at `reference_sets` twice — once for the set
  /// it belongs to, once for the set a reference field targets — and PostgREST
  /// rejects the embed as ambiguous.
  Future<List<ReferenceSet>> fetchReferenceSets({bool activeOnly = true}) async {
    final rows = await supabase
        .from('reference_sets')
        .select('*, reference_items(*)')
        .order('code');
    final fieldRows = await supabase
        .from('reference_set_fields')
        .select()
        .order('sort_order');

    final fieldsBySet = <String, List<Map<String, dynamic>>>{};
    for (final row in (fieldRows as List).cast<Map<String, dynamic>>()) {
      (fieldsBySet[row['set_id'] as String] ??= []).add(row);
    }

    final sets = (rows as List)
        .cast<Map<String, dynamic>>()
        .map(
          (r) => ReferenceSet.fromMap({
            ...r,
            'reference_set_fields': fieldsBySet[r['id'] as String] ?? const [],
          }),
        )
        .toList();
    if (!activeOnly) return sets;
    return [
      for (final s in sets)
        s.copyWith(items: s.items.where((i) => i.isActive).toList()),
    ];
  }

  /// Copies a season-scoped list from one season into another, as COPIES.
  ///
  /// Every entry becomes a new row: from then on the two seasons know nothing
  /// about each other, and deleting a hotel from 1449 leaves 1448 untouched.
  /// Names already present in the target are skipped, so it can be run twice,
  /// or after a few entries were typed by hand.
  ///
  /// Returns how many were added.
  Future<int> copyReferenceItems({
    required String setId,
    required String fromSeasonId,
    required String toSeasonId,
  }) async {
    final copied = await supabase.rpc(
      'copy_reference_items',
      params: {
        'p_set_id': setId,
        'p_from_season': fromSeasonId,
        'p_to_season': toSeasonId,
      },
    );
    return (copied as num?)?.toInt() ?? 0;
  }

  /// Takes the sectors of another file in the same season — the name, and
  /// whoever holds each post that both files know by the same code — as COPIES.
  ///
  /// The two files know nothing about each other afterwards: renaming a sector
  /// here leaves the other standing under its old name, and deleting it here
  /// does not touch it there. Names already present are skipped, so running it
  /// twice adds nothing the second time.
  ///
  /// Returns how many sectors were added — not how many people.
  Future<int> copyModuleSectors({
    required String fromModuleId,
    required String toModuleId,
  }) async {
    final copied = await supabase.rpc(
      'copy_module_sectors',
      params: {'p_from_module': fromModuleId, 'p_to_module': toModuleId},
    );
    return (copied as num?)?.toInt() ?? 0;
  }

  Future<void> addReferenceItem({
    required String setId,
    required String nameAr,
    String? nameEn,
    Map<String, dynamic> data = const {},
    String? seasonId,
  }) async {
    await supabase.from('reference_items').insert({
      'set_id': setId,
      'name_ar': nameAr,
      'name_en': (nameEn == null || nameEn.isEmpty) ? null : nameEn,
      'data': data,
      // Null for a set that is not season-scoped — a city belongs to no year.
      'season_id': seasonId,
    });
  }

  Future<void> updateReferenceItem({
    required String id,
    required String nameAr,
    String? nameEn,
    Map<String, dynamic> data = const {},
  }) async {
    await supabase
        .from('reference_items')
        .update({
          'name_ar': nameAr,
          'name_en': (nameEn == null || nameEn.isEmpty) ? null : nameEn,
          'data': data,
        })
        .eq('id', id);
  }

  /// Deletes an entry outright. A database trigger refuses the delete when a
  /// module — or another entry — still points at it, so the lists a module was
  /// built from cannot vanish underneath it.
  Future<void> deleteReferenceItem(String id) async {
    await supabase.from('reference_items').delete().eq('id', id);
  }

  // -------------------------------------------------------------- storage

  /// Uploads [file] under `{moduleId}/{key}` in the private `modules` bucket
  /// and returns the storage path.
  ///
  /// The key is not the file name: storage refuses a non-ASCII one, and these
  /// arrive named in Arabic. [fieldKey] — the module field the file belongs to —
  /// keeps two of them apart when both names strip to nothing.
  Future<String> uploadModuleFile({
    required String moduleId,
    required String fileName,
    required File file,
    String? fieldKey,
  }) async {
    final path =
        '$moduleId/${storageKey(fileName, fallback: fieldKey ?? 'file')}';
    await supabase.storage
        .from(_bucket)
        .upload(path, file, fileOptions: const FileOptions(upsert: true));
    return path;
  }

  /// A short-lived link to a module attachment. Signing goes through RLS, so a
  /// non-member cannot mint one.
  ///
  /// [download] asks storage to serve it as a download named [downloadName]
  /// rather than rendering it in place — which is the difference between "open
  /// the photo" and "save the photo".
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

  // ------------------------------------------------------------- employees

  /// One page of candidates for a role, searched and filtered in the database.
  ///
  /// [query] matches a name however it was typed — the three name columns are
  /// joined before matching — and the job title with it. [isExternal] narrows to
  /// one kind of participant, or to neither when null. Each candidate carries
  /// the files they already serve in, which is the fact that decides most of
  /// these choices and could not be seen while choosing until now.
  Future<List<AssignableEmployee>> searchAssignableEmployees({
    required String seasonId,
    String query = '',
    bool? isExternal,
    int limit = 40,
    int offset = 0,
  }) async {
    final rows = await supabase.rpc(
      'assignable_employees',
      params: {
        'p_season_id': seasonId,
        'p_query': query.trim().isEmpty ? null : query.trim(),
        'p_is_external': isExternal,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return ((rows as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(AssignableEmployee.fromMap)
        .toList();
  }

  /// Employees assignable to a module: the active participants of [seasonId].
  ///
  /// Still the whole list, and still the right call for the editor itself,
  /// which resolves names for people already placed. Choosing someone new goes
  /// through [searchAssignableEmployees] instead.
  Future<List<Profile>> fetchAssignableEmployees(String seasonId) async {
    final rows = await supabase
        .from('season_participants')
        .select('profiles!inner(*, job_titles(name, name_en))')
        .eq('season_id', seasonId)
        .eq('status', 'active');
    final people = (rows as List)
        .map(
          (r) => Profile.fromMap(
            (r as Map<String, dynamic>)['profiles'] as Map<String, dynamic>,
          ),
        )
        .where((p) => !p.isSuspended)
        .toList();
    people.sort((a, b) => a.fullName.compareTo(b.fullName));
    return people;
  }
}
