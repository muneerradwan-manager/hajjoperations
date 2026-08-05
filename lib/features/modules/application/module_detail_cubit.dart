import 'package:equatable/equatable.dart';

import '../../../core/bloc/safe_cubit.dart';
import '../../../core/l10n/localized_name.dart';
import '../../../core/offline/outbox.dart';
import '../../../core/offline/save_outcome.dart';
import '../../../core/supabase/supabase_client.dart';
import '../data/module_outbox.dart';
import '../data/modules_repository.dart';
import '../domain/module_task.dart';
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
    this.myRatings = const {},
    this.myRatingSummary = RatingSummary.none,
    this.board = ModuleTaskBoard.empty,
    this.showAllTasks = false,
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

  /// The stars the VIEWER has given, by colleague. Only ever his own: nobody
  /// may read what anyone else gave, which is what makes rating anonymous.
  final Map<String, int> myRatings;

  /// And what the viewer received here — an average and a count, never names.
  final RatingSummary myRatingSummary;

  /// The duties in force here for [focusProfileId] — the file's, then those of
  /// every post he holds, then whatever was written for him by name. Assembled
  /// by the database (`module_task_board`, 0083); see [ModuleTaskBoard].
  final ModuleTaskBoard board;

  /// Whether the board was asked for the WHOLE file rather than one man's share
  /// of it. Only whoever runs the file gets anything extra for it — the widened
  /// query is still read through the same RLS as the narrow one.
  final bool showAllTasks;

  /// Whether this file is finished and open for its people to rate each other.
  /// A file with no end date is never open, even switched off: nobody has
  /// declared it over.
  bool get canRate =>
      (module?.hasEnded ?? false) && isMember && _viewerId != null;

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

  /// The name of anyone posted anywhere in this file. Read off the roster
  /// already in hand — a personal duty names a man the reader is looking at
  /// either way, so there is nothing to fetch.
  String? nameOf(String? profileId) {
    if (profileId == null) return null;
    for (final m in [...members, for (final n in nodes) ...n.members]) {
      if (m.profileId == profileId) return m.profile?.fullName;
    }
    return null;
  }

  ModuleRole? roleById(String? id) => id == null ? null : type?.roleById(id);

  /// Where a duty is owed — "البرج/الفندق: فندق الصفوة". Null for a post held
  /// on the file itself: there the file IS the place, and naming it again under
  /// every duty would say nothing.
  LocalizedName? placeOf(String? nodeId) {
    if (nodeId == null) return null;
    final node = nodes.where((n) => n.id == nodeId).firstOrNull;
    if (node == null) return null;
    final level = type?.levelById(node.levelId);
    // A hotel is master data and carries both languages; a sector was named by
    // hand and carries only the one it was typed in, and falls back to it.
    final name =
        referenceItem(level?.referenceSetId, node.referenceItemId)?.name ??
        (node.label == null ? null : LocalizedName(ar: node.label!));
    if (name == null) return null;
    String join(String? level, String node) =>
        [level, node].nonNulls.where((s) => s.isNotEmpty).join(': ');
    return LocalizedName(
      ar: join(level?.name.ar, name.ar),
      en: join(level?.name.en, name.en ?? name.ar),
    );
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

  /// One master-data list by id — used to NAME the list itself, where the
  /// reader needs to be told what is missing rather than shown a blank.
  ReferenceSet? referenceSetById(String? id) =>
      id == null ? null : referenceSets.where((s) => s.id == id).firstOrNull;

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
    myRatings,
    myRatingSummary,
    board,
    showAllTasks,
    viewAsProfileId,
    error,
  ];
}

class ModuleDetailCubit extends SafeCubit<ModuleDetailState> {
  ModuleDetailCubit(this._repo, this.moduleId, {this.viewAsProfileId})
    : super(ModuleDetailState(viewAsProfileId: viewAsProfileId)) {
    load();
  }

  final ModulesRepository _repo;
  final String moduleId;

  /// Whose duties to show, when the file was opened from someone's employee
  /// page rather than from the reader's own list.
  final String? viewAsProfileId;

  /// Files the viewer's report for the period in force: what they attached,
  /// what they took back off, and any notes.
  ///
  /// Kept for sending later if the network is what stopped it — this is the
  /// evening report from a camp, and a man who has just photographed it will
  /// not photograph it again.
  Future<SaveOutcome> submitReport({
    String? notes,
    List<PendingAttachment> attachments = const [],
    List<StoredAttachment> removed = const [],
  }) async {
    try {
      final sent = await sendOrQueue(
        send: () => _repo.submitReport(
          moduleId: moduleId,
          notes: notes,
          attachments: attachments,
          removed: removed,
        ),
        kind: ModuleOutbox.report,
        payload: ModuleOutbox.reportPayload(
          moduleId: moduleId,
          notes: notes,
          removed: removed,
        ),
        label: state.module?.moduleTypeName?.ar,
        attachments: attachments,
      );
      // Only when it actually landed. Re-reading after a queue would blank the
      // page back to what the server still says, which is the state before the
      // thing the person just did.
      if (sent) await load();
      return sent ? const SaveOutcome.sent() : const SaveOutcome.queued();
    } catch (e) {
      return SaveOutcome.failed(e.toString());
    }
  }

  // ------------------------------------------------------------------ duties

  Future<ModuleTaskBoard> _fetchBoard() async => ModuleTaskBoard(
    lines: await _repo.fetchTaskBoard(
      moduleId: moduleId,
      profileId: viewAsProfileId,
      all: state.showAllTasks,
    ),
  );

  /// Re-reads the duties alone. The rest of the page — the tree, the roster,
  /// the reports — cannot have moved because somebody ticked a duty, and
  /// reloading it would blink the whole screen for one line of it.
  Future<void> _reloadBoard() async {
    emit(_copyWith(board: await _fetchBoard()));
  }

  ModuleDetailState _copyWith({
    ModuleTaskBoard? board,
    bool? showAllTasks,
    Map<String, int>? myRatings,
  }) => ModuleDetailState(
    status: state.status,
    module: state.module,
    type: state.type,
    nodes: state.nodes,
    members: state.members,
    referenceSets: state.referenceSets,
    reports: state.reports,
    myRatings: myRatings ?? state.myRatings,
    myRatingSummary: state.myRatingSummary,
    board: board ?? state.board,
    showAllTasks: showAllTasks ?? state.showAllTasks,
    viewAsProfileId: state.viewAsProfileId,
    error: state.error,
  );

  /// Switches between "my duties here" and every duty in the file. Only ever
  /// offered to whoever runs it; the database narrows the answer again for
  /// anyone else who asks.
  Future<void> setShowAllTasks(bool all) async {
    if (all == state.showAllTasks) return;
    emit(_copyWith(showAllTasks: all));
    emit(_copyWith(board: await _fetchBoard()));
  }

  /// Moves one duty along, with whatever note and evidence came with it.
  ///
  /// Kept for sending later if the network is what stopped it. This is the
  /// write a man makes standing in front of the thing he is reporting on, and
  /// it is the one the whole season is read back from.
  Future<SaveOutcome> setTaskState(
    ModuleTaskLine line,
    TaskState newState, {
    String? note,
    List<PendingAttachment> attachments = const [],
    List<StoredAttachment> removed = const [],
  }) async {
    try {
      final sent = await sendOrQueue(
        send: () async {
          // The state row first: the evidence is stored under its id, and
          // storage will not accept a file until it exists.
          final statusId = await _repo.setTaskState(
            moduleId: moduleId,
            state: newState,
            typeTaskId: line.typeTaskId,
            moduleTaskId: line.moduleTaskId,
            nodeId: line.nodeId,
            profileId: line.profileId,
            note: note,
          );
          if (attachments.isNotEmpty || removed.isNotEmpty) {
            await _repo.setTaskAttachments(
              moduleId: moduleId,
              statusId: statusId,
              attachments: attachments,
              removed: removed,
            );
          }
        },
        kind: ModuleOutbox.taskState,
        payload: ModuleOutbox.taskStatePayload(
          moduleId: moduleId,
          state: newState,
          line: line,
          note: note,
          removed: removed,
        ),
        label: line.title.ar,
        attachments: attachments,
      );
      if (sent) await _reloadBoard();
      return sent ? const SaveOutcome.sent() : const SaveOutcome.queued();
    } catch (e) {
      return SaveOutcome.failed(e.toString());
    }
  }

  /// Writes a duty onto this file — the third scope, and the two exceptional
  /// halves of the other two. Returns null on success, else the failure.
  Future<String?> createTask({
    required TaskScope scope,
    required String titleAr,
    String? titleEn,
    String? descriptionAr,
    String? roleId,
    String? profileId,
    String? groupId,
    DateTime? dueOn,
  }) async {
    try {
      await _repo.createFileTask(
        moduleId: moduleId,
        scope: scope,
        titleAr: titleAr,
        titleEn: titleEn,
        descriptionAr: descriptionAr,
        roleId: roleId,
        profileId: profileId,
        groupId: groupId,
        dueOn: dueOn,
      );
      await _reloadBoard();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateTask({
    required String id,
    required String titleAr,
    String? titleEn,
    String? descriptionAr,
    String? groupId,
    DateTime? dueOn,
  }) async {
    try {
      await _repo.updateFileTask(
        id: id,
        titleAr: titleAr,
        titleEn: titleEn,
        descriptionAr: descriptionAr,
        groupId: groupId,
        dueOn: dueOn,
      );
      await _reloadBoard();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteTask(String id) async {
    try {
      await _repo.deleteFileTask(id);
      await _reloadBoard();
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
      // Only a finished file has any of this: nothing to draw, nothing to ask
      // for, and two calls saved on every other file in the app.
      final ratings = module.hasEnded
          ? await _repo.fetchMyRatings(moduleId)
          : const <String, int>{};
      final summary = module.hasEnded
          ? await _repo.fetchMyRatingSummary(moduleId)
          : RatingSummary.none;
      // The duties of the file, of the posts held in it, and of the man — one
      // call, because only the database can work out the middle one.
      final board = await _fetchBoard();

      emit(
        ModuleDetailState(
          status: ModuleDetailStatus.ready,
          module: module,
          type: type,
          nodes: nodes,
          members: members,
          referenceSets: sets,
          reports: reports,
          myRatings: ratings,
          myRatingSummary: summary,
          board: board,
          showAllTasks: state.showAllTasks,
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

  /// Rates a colleague of this file, or changes what was said before. [stars]
  /// of null takes it back entirely, which is not the same as giving one.
  ///
  /// Returns null on success, else the failure. The database refuses this
  /// unless the file has ended and both people were in it — the button is only
  /// ever the polite half of that.
  Future<String?> rate(String rateeId, int? stars) async {
    final module = state.module;
    if (module == null) return null;
    try {
      if (stars == null) {
        await _repo.clearRating(moduleId: module.id, rateeId: rateeId);
      } else {
        await _repo.rate(
          moduleId: module.id,
          rateeId: rateeId,
          stars: stars,
        );
      }
      // Only what the viewer gave is re-read. His own result cannot have
      // changed — nobody rates himself — and re-reading it would suggest the
      // two are connected.
      emit(_copyWith(myRatings: await _repo.fetchMyRatings(module.id)));
      return null;
    } catch (e) {
      return e.toString();
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

  /// The same, for the attachment views, which want the failure rather than a
  /// null they would have to explain to the reader themselves.
  Future<String> signAttachment(
    String path, {
    bool download = false,
    String? downloadName,
  }) => _repo.signedUrl(path, download: download, downloadName: downloadName);
}
