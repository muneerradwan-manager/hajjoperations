import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/localized_name.dart';
import '../../../core/supabase/supabase_client.dart';
import '../data/modules_repository.dart';
import '../domain/module_type.dart';
import '../domain/operational_module.dart';
import '../domain/reference_item.dart';

enum ModuleDetailStatus { loading, ready, error }

/// A role someone holds here, and the places they hold it in. One person may
/// run three towers under the same file, so the places are a list.
class RoleHere {
  const RoleHere({
    required this.role,
    this.places = const [],
    this.taskIds = const {},
    this.tasks = const [],
  });

  final ModuleRole role;
  final List<LocalizedName> places;

  /// The duties handed to this person in this role, for a role whose list is a
  /// menu. Gathered across every place they hold it.
  final Set<String> taskIds;

  /// What this person is actually answerable for: the standing duties of the
  /// post, plus his share of whatever is handed out — resolved against the type,
  /// which knows whether the menu is the role's own or the file's.
  final List<RoleTask> tasks;
}

class ModuleDetailState extends Equatable {
  const ModuleDetailState({
    this.status = ModuleDetailStatus.loading,
    this.module,
    this.type,
    this.nodes = const [],
    this.members = const [],
    this.referenceSets = const [],
    this.reports = const [],
    this.viewAsProfileId,
    this.error,
  });

  final ModuleDetailStatus status;
  final OperationalModule? module;
  final ModuleType? type;

  /// The whole tree, flat: sectors and the towers under them.
  final List<ModuleNode> nodes;

  /// People holding a role on the file itself rather than on a node.
  final List<ModuleMember> members;

  final List<ReferenceSet> referenceSets;

  /// The reports filed against this file, newest first. RLS already narrowed
  /// them: a member gets their own, a manager gets everyone's.
  final List<ModuleReport> reports;

  /// The signed-in person, always — reports are filed by whoever is looking,
  /// never by the employee whose page this was opened from.
  String? get _viewerId => supabase.auth.currentUser?.id;

  Set<String> get _holders => {
    for (final m in members) m.profileId,
    for (final n in nodes)
      for (final m in n.members) m.profileId,
  };

  /// Whether the viewer holds a role anywhere in this file. Only they may file
  /// a report — the database says so too, and this keeps the button honest.
  bool get isMember => _viewerId != null && _holders.contains(_viewerId);

  /// The report the viewer has already filed for the period in force, if any.
  /// Filing again edits it rather than adding a second, so the button says
  /// "edit" when this is set.
  ModuleReport? get myReportForThisPeriod {
    final me = _viewerId;
    if (me == null) return null;
    final cadence = module?.reportCadence ?? ReportCadence.none;
    final now = DateTime.now();
    return reports.where((r) {
      if (r.authorId != me) return false;
      return switch (cadence) {
        ReportCadence.once => true,
        ReportCadence.none => false,
        ReportCadence.daily || ReportCadence.weekly => r.periodStart != null &&
            !r.periodStart!.isAfter(now) &&
            now.difference(r.periodStart!).inDays <
                (cadence == ReportCadence.daily ? 1 : 7),
      };
    }).firstOrNull;
  }

  /// Whose duties this screen is about. Set when the file was opened from
  /// someone's employee page: the reader wants to know what THAT person is
  /// responsible for, not what they themselves are. Null means the viewer.
  final String? viewAsProfileId;

  final String? error;

  ModuleLevel? get parentLevel => type?.outermostLevel;
  ModuleLevel? get childLevel {
    final parent = parentLevel;
    return parent == null ? null : type?.levelBelow(parent);
  }

  List<ModuleNode> get parentNodes {
    final level = parentLevel;
    if (level == null) return const [];
    return nodes.where((n) => n.levelId == level.id).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<ModuleNode> childrenOf(String parentId) =>
      nodes.where((n) => n.parentId == parentId).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<ModuleMember> membersOf(String roleId) =>
      members.where((m) => m.roleId == roleId).toList();

  /// Everyone in the file, wherever they sit — what the header counts.
  int get peopleCount =>
      members.length + nodes.fold(0, (sum, n) => sum + n.members.length);

  /// Whose duties are being read: the person the screen was opened for, or the
  /// viewer themselves.
  String? get focusProfileId =>
      viewAsProfileId ?? supabase.auth.currentUser?.id;

  /// Set only when reading someone else's duties — the screen names them so it
  /// is never mistaken for the reader's own.
  String? get focusName {
    final id = viewAsProfileId;
    if (id == null) return null;
    for (final m in [...members, for (final n in nodes) ...n.members]) {
      if (m.profileId == id) return m.profile?.fullName;
    }
    return null;
  }

  /// The roles [focusProfileId] holds anywhere in this file, and where. A
  /// person may hold two — a sector supervisor who also runs one of its towers
  /// — so this is a list, and each role carries the places it is held in.
  List<RoleHere> get focusRoles {
    final id = focusProfileId;
    final type = this.type;
    if (id == null || type == null) return const [];

    final places = <String, List<LocalizedName>>{};
    final duties = <String, Set<String>>{};
    for (final m in members) {
      if (m.profileId != id) continue;
      places.putIfAbsent(m.roleId, () => []);
      (duties[m.roleId] ??= {}).addAll(m.taskIds);
    }
    for (final node in nodes) {
      final level = type.levelById(node.levelId);
      // A hotel is master data and carries both languages; a sector was named
      // by hand and carries only the one it was typed in.
      final name =
          referenceItem(level?.referenceSetId, node.referenceItemId)?.name ??
          (node.label == null ? null : LocalizedName(ar: node.label!));
      for (final m in node.members) {
        if (m.profileId != id) continue;
        final list = places.putIfAbsent(m.roleId, () => []);
        (duties[m.roleId] ??= {}).addAll(m.taskIds);
        if (name != null && !list.any((p) => p.ar == name.ar)) list.add(name);
      }
    }

    return [
      for (final role in type.allRoles)
        if (places.containsKey(role.id))
          RoleHere(
            role: role,
            places: places[role.id]!,
            taskIds: duties[role.id] ?? const {},
            tasks: type.dutiesOf(role, duties[role.id] ?? const {}),
          ),
    ];
  }

  /// Resolves a stored reference id to its display name.
  ReferenceItem? referenceItem(String? setId, Object? value) {
    if (setId == null || value is! String) return null;
    for (final set in referenceSets) {
      if (set.id != setId) continue;
      return set.items.where((i) => i.id == value).firstOrNull;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    status,
    module,
    type,
    nodes,
    members,
    referenceSets,
    reports,
    viewAsProfileId,
    error,
  ];
}

class ModuleDetailCubit extends Cubit<ModuleDetailState> {
  ModuleDetailCubit(this._repo, this.moduleId, {this.viewAsProfileId})
    : super(ModuleDetailState(viewAsProfileId: viewAsProfileId)) {
    load();
  }

  final ModulesRepository _repo;
  final String moduleId;

  /// Whose duties to show, when the file was opened from someone's employee
  /// page rather than from the reader's own list.
  final String? viewAsProfileId;

  /// Files the viewer's report for the period in force. Returns null on
  /// success, else what went wrong.
  Future<String?> submitReport(String body) async {
    try {
      await _repo.submitReport(moduleId: moduleId, body: body);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> load() async {
    try {
      final module = await _repo.fetchModule(moduleId);
      if (module == null) {
        emit(
          ModuleDetailState(
            status: ModuleDetailStatus.error,
            error: 'module not found',
            viewAsProfileId: viewAsProfileId,
          ),
        );
        return;
      }
      final type = await _repo.fetchModuleType(module.moduleTypeId);
      final nodes = await _repo.fetchNodes(moduleId);
      final members = await _repo.fetchMembers(moduleId);
      // Inactive entries stay loaded: a tower may already point at one.
      final sets = await _repo.fetchReferenceSets(activeOnly: false);
      final reports = module.reportCadence.asksForReports
          ? await _repo.fetchReports(moduleId)
          : const <ModuleReport>[];
      emit(
        ModuleDetailState(
          status: ModuleDetailStatus.ready,
          module: module,
          type: type,
          nodes: nodes,
          members: members,
          referenceSets: sets,
          reports: reports,
          viewAsProfileId: viewAsProfileId,
        ),
      );
    } catch (e) {
      emit(
        ModuleDetailState(
          status: ModuleDetailStatus.error,
          error: e.toString(),
          viewAsProfileId: viewAsProfileId,
        ),
      );
    }
  }

  /// Flips activation. Activating is what releases the file to its members —
  /// the database notifies them. Returns null on success, else the failure.
  Future<String?> toggleActive() async {
    final module = state.module;
    if (module == null) return null;
    try {
      await _repo.setActive(module.id, !module.isActive);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Returns null on success, else the failure.
  Future<String?> delete() async {
    final module = state.module;
    if (module == null) return null;
    try {
      await _repo.deleteModule(module.id);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// A short-lived link to an attachment, or null if it could not be signed.
  Future<String?> signedUrl(String path) async {
    try {
      return await _repo.signedUrl(path);
    } catch (_) {
      return null;
    }
  }
}
