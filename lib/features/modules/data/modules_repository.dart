import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../profile/domain/profile.dart';
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

  /// A type's whole schema: its fields, the levels of its tree, and every role
  /// with the standing tasks that come with it.
  static const _typeColumns =
      '*, '
      'module_type_fields(*), '
      'module_type_levels(*), '
      'module_type_roles(*, module_type_role_tasks(*))';

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
  Future<List<OperationalModule>> fetchModules() async {
    final rows = await supabase
        .from('modules')
        .select(_moduleColumns)
        .order('created_at', ascending: false);
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
  }) async {
    final row = await supabase
        .from('modules')
        .insert({
          'module_type_id': moduleTypeId,
          'season_id': seasonId,
          'starts_on': _asDate(startsOn),
          'data': data,
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
  }) async {
    await supabase
        .from('modules')
        .update({
          'starts_on': _asDate(startsOn),
          'data': data,
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

  // ----------------------------------------------------------------- nodes

  /// The whole tree of a file — sectors and the towers under them — with every
  /// role holder and their contact details, in one query. A file is small
  /// enough (tens of towers) that paging it would cost more than it saves.
  Future<List<ModuleNode>> fetchNodes(String moduleId) async {
    final rows = await supabase
        .from('module_nodes')
        // Embedded through `profile_id` explicitly: the table also points at
        // profiles via `assigned_by`, and a bare `profiles(...)` is ambiguous.
        .select('*, module_node_members(*, profiles:profile_id(*, job_titles(name)))')
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
  /// nodes. Types with a tree — every type today — have none.
  Future<List<ModuleMember>> fetchMembers(String moduleId) async {
    final rows = await supabase
        .from('module_members')
        .select('*, profiles:profile_id(*, job_titles(name))')
        .eq('module_id', moduleId);
    return (rows as List)
        .map((r) => ModuleMember.fromMap(r as Map<String, dynamic>))
        .toList();
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

  Future<void> addReferenceItem({
    required String setId,
    required String nameAr,
    String? nameEn,
    Map<String, dynamic> data = const {},
  }) async {
    await supabase.from('reference_items').insert({
      'set_id': setId,
      'name_ar': nameAr,
      'name_en': (nameEn == null || nameEn.isEmpty) ? null : nameEn,
      'data': data,
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

  /// Uploads [file] under `{moduleId}/{name}` in the private `modules` bucket
  /// and returns the storage path.
  Future<String> uploadModuleFile({
    required String moduleId,
    required String fileName,
    required File file,
  }) async {
    final path = '$moduleId/$fileName';
    await supabase.storage
        .from(_bucket)
        .upload(path, file, fileOptions: const FileOptions(upsert: true));
    return path;
  }

  /// A short-lived link to a module attachment. Signing goes through RLS, so a
  /// non-member cannot mint one.
  Future<String> signedUrl(String path, {int expiresInSeconds = 600}) {
    return supabase.storage.from(_bucket).createSignedUrl(path, expiresInSeconds);
  }

  // ------------------------------------------------------------- employees

  /// Employees assignable to a module: the active participants of [seasonId].
  /// Roles are filled from the people actually taking part in the season.
  Future<List<Profile>> fetchAssignableEmployees(String seasonId) async {
    final rows = await supabase
        .from('season_participants')
        .select('profiles!inner(*, job_titles(name))')
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
