import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/localized_name.dart';
import '../../profile/domain/profile.dart';
import '../data/modules_repository.dart';
import '../domain/module_type.dart';
import '../domain/operational_module.dart';
import '../domain/reference_item.dart';

enum EditorStatus { loading, ready, saving, error }

/// Why a save attempt did not go through. Returned from the save methods rather
/// than held in state: the same complaint repeated twice must still produce a
/// second message.
enum SaveOutcome { ok, missingDate, missingField, missingEntry, missingRole, failed }

class SaveResult {
  const SaveResult(this.outcome, {this.name, this.message});

  final SaveOutcome outcome;

  /// The field, entry or role that was left empty.
  final LocalizedName? name;
  final String? message;

  bool get ok => outcome == SaveOutcome.ok;
}

/// A sector or tower as the sheet hands it back: what it is, and who holds each
/// of its roles. Not yet persisted.
class NodeDraft {
  const NodeDraft({
    this.id,
    this.referenceItemId,
    this.label,
    this.roleMembers = const {},
  });

  /// Null when adding; set when editing an existing node.
  final String? id;

  /// The master-data entry this node stands for (a hotel), for levels that have
  /// a list.
  final String? referenceItemId;

  /// Its name, for levels that have none (a sector).
  final String? label;

  final Map<String, Set<String>> roleMembers;

  Set<String> membersOf(String roleId) => roleMembers[roleId] ?? const {};
}

class ModuleEditorState extends Equatable {
  const ModuleEditorState({
    this.status = EditorStatus.loading,
    this.step = 0,
    this.type,
    this.moduleId,
    this.startsOn,
    this.values = const {},
    this.pendingFiles = const {},
    this.nodes = const [],
    this.members = const [],
    this.employees = const [],
    this.referenceSets = const [],
    this.error,
  });

  final EditorStatus status;

  /// For a file built as a tree: 0 — the file itself, 1 — its sectors, 2 — the
  /// towers inside them. For a file that is only a roster, the tree steps
  /// collapse into one: 0 — the file, 1 — its people.
  final int step;

  final ModuleType? type;

  /// Null until the file has been created; the tree cannot be built before the
  /// row it hangs off exists.
  final String? moduleId;

  final DateTime? startsOn;

  /// Field values keyed by [ModuleField.key], as they will be persisted.
  final Map<String, dynamic> values;

  /// PDFs chosen on this device but not uploaded yet — a file id is needed for
  /// the storage path, so uploads wait until the row exists.
  final Map<String, File> pendingFiles;

  final List<ModuleNode> nodes;

  /// The people on the file itself, for a type with no tree. Each carries the
  /// duties handed to them.
  final List<ModuleMember> members;

  final List<Profile> employees;
  final List<ReferenceSet> referenceSets;
  final String? error;

  bool get isCreated => moduleId != null;

  /// Whether this file is built as sectors and towers, or is simply its roster.
  bool get hasTree => type?.hasTree ?? true;

  /// The last step of the wizard — the towers of a tree, or the roster of a
  /// file that has none.
  int get lastStep => hasTree ? 2 : 1;

  List<ModuleMember> membersOf(String roleId) =>
      members.where((m) => m.roleId == roleId).toList();

  Set<String> memberProfileIdsOf(String roleId) =>
      members.where((m) => m.roleId == roleId).map((m) => m.profileId).toSet();

  /// The sector level, and the tower level inside it.
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

  ReferenceSet? referenceSetById(String? id) =>
      referenceSets.where((s) => s.id == id).firstOrNull;

  ReferenceItem? referenceItem(String? setId, String? itemId) {
    if (itemId == null) return null;
    return referenceSetById(setId)?.items.where((i) => i.id == itemId).firstOrNull;
  }

  Profile? profileById(String id) =>
      employees.where((e) => e.id == id).firstOrNull;

  /// Entries already standing at [levelId] in this file. A hotel is entered
  /// once — the database enforces it, and the picker leaves it out rather than
  /// letting someone hit the error.
  Set<String> takenEntries(String levelId, {String? except}) => {
    for (final n in nodes)
      if (n.levelId == levelId && n.id != except && n.referenceItemId != null)
        n.referenceItemId!,
  };

  ModuleEditorState copyWith({
    EditorStatus? status,
    int? step,
    ModuleType? type,
    String? moduleId,
    DateTime? startsOn,
    Map<String, dynamic>? values,
    Map<String, File>? pendingFiles,
    List<ModuleNode>? nodes,
    List<ModuleMember>? members,
    List<Profile>? employees,
    List<ReferenceSet>? referenceSets,
    String? error,
  }) {
    return ModuleEditorState(
      status: status ?? this.status,
      step: step ?? this.step,
      type: type ?? this.type,
      moduleId: moduleId ?? this.moduleId,
      startsOn: startsOn ?? this.startsOn,
      values: values ?? this.values,
      pendingFiles: pendingFiles ?? this.pendingFiles,
      nodes: nodes ?? this.nodes,
      members: members ?? this.members,
      employees: employees ?? this.employees,
      referenceSets: referenceSets ?? this.referenceSets,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    step,
    type?.id,
    moduleId,
    startsOn,
    values,
    pendingFiles,
    nodes,
    members,
    employees,
    referenceSets,
    error,
  ];
}

/// Builds one operational file, in the order it is actually built: the file
/// itself, then its sectors, then the hotels inside each sector.
///
/// Each step is persisted as it is completed rather than held until the end. A
/// file is assembled over days — towers are added as they are confirmed — so
/// there is no moment at which "the whole thing" is ready to be saved at once.
class ModuleEditorCubit extends Cubit<ModuleEditorState> {
  ModuleEditorCubit(
    this._repo, {
    required this.moduleTypeId,
    required this.seasonId,
    this.existing,
  }) : super(const ModuleEditorState()) {
    _load();
  }

  final ModulesRepository _repo;
  final String moduleTypeId;
  final String seasonId;
  final OperationalModule? existing;

  bool get isEditing => existing != null;

  Future<void> _load() async {
    try {
      final type = await _repo.fetchModuleType(moduleTypeId);
      if (type == null) {
        emit(
          state.copyWith(
            status: EditorStatus.error,
            error: 'module type not found',
          ),
        );
        return;
      }
      final employees = await _repo.fetchAssignableEmployees(seasonId);
      // Inactive entries stay loaded: a tower may already point at one.
      final sets = await _repo.fetchReferenceSets(activeOnly: false);
      final nodes = existing == null || !type.hasTree
          ? const <ModuleNode>[]
          : await _repo.fetchNodes(existing!.id);
      final members = existing == null || type.hasTree
          ? const <ModuleMember>[]
          : await _repo.fetchMembers(existing!.id);

      emit(
        state.copyWith(
          status: EditorStatus.ready,
          type: type,
          moduleId: existing?.id,
          startsOn: existing?.startsOn,
          values: Map<String, dynamic>.from(existing?.data ?? const {}),
          nodes: nodes,
          members: members,
          employees: employees,
          referenceSets: sets,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: EditorStatus.error, error: e.toString()));
    }
  }

  Future<void> _reloadNodes() async {
    final id = state.moduleId;
    if (id == null) return;
    emit(state.copyWith(nodes: await _repo.fetchNodes(id)));
  }

  Future<void> _reloadMembers() async {
    final id = state.moduleId;
    if (id == null) return;
    emit(state.copyWith(members: await _repo.fetchMembers(id)));
  }

  void goTo(int step) => emit(state.copyWith(step: step));

  void setStartsOn(DateTime value) => emit(state.copyWith(startsOn: value));

  void setValue(String key, Object? value) {
    final values = Map<String, dynamic>.from(state.values);
    if (value == null || (value is String && value.isEmpty)) {
      values.remove(key);
    } else {
      values[key] = value;
    }
    emit(state.copyWith(values: values));
  }

  void attachFile(String key, File file, String fileName) {
    final pending = Map<String, File>.from(state.pendingFiles)..[key] = file;
    // Shown immediately; the path is filled in once the upload runs on save.
    final values = Map<String, dynamic>.from(state.values)
      ..[key] = {'path': '', 'name': fileName};
    emit(state.copyWith(pendingFiles: pending, values: values));
  }

  /// Step 1: the file itself. Creates it on the first pass and updates it
  /// afterwards, then moves on to the sectors.
  Future<SaveResult> saveInfo() async {
    final type = state.type;
    if (type == null) return const SaveResult(SaveOutcome.failed);

    final startsOn = state.startsOn;
    if (startsOn == null) return const SaveResult(SaveOutcome.missingDate);

    for (final f in type.fields.where((f) => f.isRequired)) {
      final v = state.values[f.key];
      final missing =
          v == null ||
          (v is String && v.trim().isEmpty) ||
          (f.kind == ModuleFieldKind.pdf &&
              ModuleFile.fromJson(v) == null &&
              !state.pendingFiles.containsKey(f.key));
      if (missing) return SaveResult(SaveOutcome.missingField, name: f.label);
    }

    emit(state.copyWith(status: EditorStatus.saving));
    try {
      final values = Map<String, dynamic>.from(state.values);

      // The row has to exist before files can be filed under its id.
      final id =
          state.moduleId ??
          await _repo.createModule(
            moduleTypeId: type.id,
            seasonId: seasonId,
            startsOn: startsOn,
            data: {
              for (final e in values.entries)
                if (!state.pendingFiles.containsKey(e.key)) e.key: e.value,
            },
          );

      for (final entry in state.pendingFiles.entries) {
        final name =
            (values[entry.key] as Map?)?['name'] as String? ?? 'file.pdf';
        final path = await _repo.uploadModuleFile(
          moduleId: id,
          fileName: name,
          file: entry.value,
        );
        values[entry.key] = ModuleFile(path: path, name: name).toJson();
      }

      await _repo.updateModule(id, startsOn: startsOn, data: values);

      emit(
        state.copyWith(
          status: EditorStatus.ready,
          moduleId: id,
          values: values,
          pendingFiles: const {},
          step: 1,
        ),
      );
      return const SaveResult(SaveOutcome.ok);
    } catch (e) {
      emit(state.copyWith(status: EditorStatus.ready));
      return SaveResult(SaveOutcome.failed, message: e.toString());
    }
  }

  /// Steps 2 and 3: adds or updates one sector or tower together with everyone
  /// holding a role in it.
  Future<SaveResult> saveNode({
    required ModuleLevel level,
    required NodeDraft draft,
    String? parentId,
  }) async {
    final moduleId = state.moduleId;
    if (moduleId == null) return const SaveResult(SaveOutcome.failed);

    if (level.isNamedByHand) {
      if ((draft.label ?? '').trim().isEmpty) {
        return SaveResult(SaveOutcome.missingEntry, name: level.name);
      }
    } else if (draft.referenceItemId == null) {
      return SaveResult(SaveOutcome.missingEntry, name: level.name);
    }
    for (final r in level.roles.where((r) => r.isRequired)) {
      if (draft.membersOf(r.id).isEmpty) {
        return SaveResult(SaveOutcome.missingRole, name: r.name);
      }
    }

    emit(state.copyWith(status: EditorStatus.saving));
    try {
      var id = draft.id;
      if (id == null) {
        final siblings = parentId == null
            ? state.parentNodes
            : state.childrenOf(parentId);
        id = await _repo.createNode(
          moduleId: moduleId,
          levelId: level.id,
          parentId: parentId,
          referenceItemId: draft.referenceItemId,
          label: draft.label?.trim(),
          sortOrder: siblings.length + 1,
        );
      } else {
        await _repo.updateNode(
          id,
          referenceItemId: draft.referenceItemId,
          label: draft.label?.trim(),
        );
      }

      for (final role in level.roles) {
        await _repo.setNodeRoleMembers(
          nodeId: id,
          roleId: role.id,
          profileIds: draft.membersOf(role.id),
        );
      }

      await _reloadNodes();
      emit(state.copyWith(status: EditorStatus.ready));
      return const SaveResult(SaveOutcome.ok);
    } catch (e) {
      emit(state.copyWith(status: EditorStatus.ready));
      return SaveResult(SaveOutcome.failed, message: e.toString());
    }
  }

  /// Step 2 of a file with no tree: puts people on one of its teams. Returns
  /// null on success, else the failure.
  ///
  /// Someone dropped from a team loses the duties he was handed there with him;
  /// someone who stays keeps his, which is why membership is diffed rather than
  /// rewritten.
  Future<String?> setRoleMembers(String roleId, Set<String> profileIds) async {
    final moduleId = state.moduleId;
    if (moduleId == null) return null;

    emit(state.copyWith(status: EditorStatus.saving));
    try {
      await _repo.setModuleRoleMembers(
        moduleId: moduleId,
        roleId: roleId,
        profileIds: profileIds,
      );
      await _reloadMembers();
      emit(state.copyWith(status: EditorStatus.ready));
      return null;
    } catch (e) {
      emit(state.copyWith(status: EditorStatus.ready));
      return e.toString();
    }
  }

  /// Hands one member his share of his team's duties. Handing him none is a
  /// legitimate outcome — he is on the team, and that is the posting.
  Future<String?> setMemberTasks(String memberId, Set<String> taskIds) async {
    emit(state.copyWith(status: EditorStatus.saving));
    try {
      await _repo.setAssignedTasks(memberId: memberId, taskIds: taskIds);
      await _reloadMembers();
      emit(state.copyWith(status: EditorStatus.ready));
      return null;
    } catch (e) {
      emit(state.copyWith(status: EditorStatus.ready));
      return e.toString();
    }
  }

  /// Returns null on success, else the failure. Removing a sector removes the
  /// towers under it.
  Future<String?> deleteNode(String id) async {
    try {
      await _repo.deleteNode(id);
      await _reloadNodes();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
