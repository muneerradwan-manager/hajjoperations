import 'package:flutter_test/flutter_test.dart';
import 'package:hajjoperations/core/l10n/localized_name.dart';
import 'package:hajjoperations/features/modules/domain/module_task.dart';
import 'package:hajjoperations/features/modules/domain/module_type.dart';

/// A duty belongs to the work, not to the man doing it — and the one place that
/// claim can break silently is the grouping.
///
/// A role duty is owed once PER PLACE the post is held at. مشرف البرج running
/// three towers owes "جولة يومية على الغرف" three times, and merging them into
/// one line would let two towers go unvisited behind a green tick earned in the
/// third. Every test below is about that not happening.
void main() {
  ModuleTaskLine line({
    required TaskScope scope,
    String id = 't1',
    String? roleId,
    String? nodeId,
    String? profileId,
    String? groupId,
    TaskState state = TaskState.notStarted,
  }) => ModuleTaskLine(
    typeTaskId: id,
    scope: scope,
    roleId: roleId,
    nodeId: nodeId,
    profileId: profileId,
    groupId: groupId,
    title: LocalizedName(ar: id),
    state: state,
  );

  group('the three levels come apart cleanly', () {
    final board = ModuleTaskBoard(
      lines: [
        line(scope: TaskScope.file, id: 'f1'),
        line(scope: TaskScope.file, id: 'f2'),
        line(scope: TaskScope.role, id: 'r1', roleId: 'tower', nodeId: 'safwa'),
        line(scope: TaskScope.personal, id: 'p1', profileId: 'ahmad'),
      ],
    );

    test('a file duty is neither a role duty nor anybody\'s own', () {
      expect(board.fileTasks.map((t) => t.typeTaskId), ['f1', 'f2']);
      expect(board.roleGroups.single.tasks.single.typeTaskId, 'r1');
      expect(board.personalTasks.single.typeTaskId, 'p1');
    });

    test('a personal duty is filed under the man it names', () {
      expect(board.personalByProfile.keys, ['ahmad']);
    });
  });

  test('the same duty at two towers is two lines, not one', () {
    final board = ModuleTaskBoard(
      lines: [
        line(
          scope: TaskScope.role,
          id: 'rounds',
          roleId: 'tower',
          nodeId: 'safwa',
          state: TaskState.done,
        ),
        line(
          scope: TaskScope.role,
          id: 'rounds',
          roleId: 'tower',
          nodeId: 'noor',
        ),
      ],
    );

    final groups = board.roleGroups;
    expect(groups.length, 2, reason: 'one group per PLACE, not per post');
    expect(groups.map((g) => g.nodeId), ['safwa', 'noor']);
    // The whole point: finishing one tower does not finish the other.
    expect(ModuleTaskBoard.progressOf(groups.first.tasks), (1, 1));
    expect(ModuleTaskBoard.progressOf(groups.last.tasks), (0, 1));
  });

  test('the key of a line separates the places the same duty is owed at', () {
    final safwa = line(
      scope: TaskScope.role,
      id: 'rounds',
      roleId: 'tower',
      nodeId: 'safwa',
    );
    final noor = line(
      scope: TaskScope.role,
      id: 'rounds',
      roleId: 'tower',
      nodeId: 'noor',
    );
    expect(safwa.key, isNot(noor.key));
  });

  test('a post held on the file itself has no place under it', () {
    final board = ModuleTaskBoard(
      lines: [line(scope: TaskScope.role, id: 'r1', roleId: 'team')],
    );
    expect(board.roleGroups.single.nodeId, isNull);
  });

  test('progress counts only what is finished', () {
    final board = ModuleTaskBoard(
      lines: [
        line(scope: TaskScope.file, id: 'a', state: TaskState.done),
        line(scope: TaskScope.file, id: 'b', state: TaskState.inProgress),
        line(scope: TaskScope.file, id: 'c'),
      ],
    );
    expect(
      board.progress,
      (1, 3),
      reason: 'قيد التنفيذ is not half a tick — it is not a tick',
    );
  });

  group('the stages of the work', () {
    const planning = TaskGroup(
      id: 'g1',
      code: 'planning',
      name: LocalizedName(ar: 'التخطيط'),
    );
    const makkah = TaskGroup(
      id: 'g2',
      code: 'makkah',
      name: LocalizedName(ar: 'مكة'),
    );
    const type = ModuleType(
      id: 'type',
      code: 'c',
      name: LocalizedName(ar: 'ملف'),
      taskGroups: [planning, makkah],
    );

    test('duties belonging to no stage come first, under no heading', () {
      final grouped = type.groupByStage(
        [
          line(scope: TaskScope.file, id: 'loose'),
          line(scope: TaskScope.file, id: 'planned', groupId: 'g1'),
        ],
        (t) => t.groupId,
      );
      expect(grouped.first.$1, isNull);
      expect(grouped.first.$2.single.typeTaskId, 'loose');
      expect(grouped.last.$1?.id, 'g1');
    });

    test('an empty stage is dropped rather than left as a bare heading', () {
      final grouped = type.groupByStage(
        [line(scope: TaskScope.file, id: 'planned', groupId: 'g1')],
        (t) => t.groupId,
      );
      expect(grouped.map((g) => g.$1?.id), ['g1']);
    });

    test('a type with no stages lays its duties out in one run', () {
      const plain = ModuleType(
        id: 'type',
        code: 'c',
        name: LocalizedName(ar: 'ملف'),
      );
      final grouped = plain.groupByStage(
        [line(scope: TaskScope.file, id: 'a')],
        (t) => t.groupId,
      );
      expect(grouped.single.$1, isNull);
      expect(grouped.single.$2.length, 1);
    });
  });

  group('reading what the database sent', () {
    test('a line with no state row yet reads as not started', () {
      final parsed = ModuleTaskLine.fromMap({
        'status_id': null,
        'type_task_id': 't1',
        'module_task_id': null,
        'scope': 'file',
        'role_id': null,
        'node_id': null,
        'profile_id': null,
        'group_id': null,
        'title_ar': 'اعتماد كشوف المجموعات',
        'title_en': null,
        'description_ar': null,
        'description_en': null,
        'due_on': null,
        'sort_order': 1,
        'state': null,
        'note': null,
        'updated_by': null,
        'updated_by_name': null,
        'updated_at': null,
        'can_update': true,
      });

      expect(parsed.state, TaskState.notStarted);
      expect(parsed.scope, TaskScope.file);
      expect(parsed.title.ar, 'اعتماد كشوف المجموعات');
      expect(parsed.isOwnedByFile, isFalse);
    });

    test('a duty written on the file is the editable kind', () {
      final parsed = ModuleTaskLine.fromMap({
        'type_task_id': null,
        'module_task_id': 'm1',
        'scope': 'personal',
        'profile_id': 'ahmad',
        'title_ar': 'استلام العهدة',
        'state': 'in_progress',
        'sort_order': 0,
        'can_update': true,
      });

      expect(parsed.isOwnedByFile, isTrue);
      expect(parsed.state, TaskState.inProgress);
      expect(parsed.scope, TaskScope.personal);
    });

    test('an unknown state is not started rather than a crash', () {
      expect(TaskState.fromDb('something_else'), TaskState.notStarted);
      expect(TaskScope.fromDb(null), TaskScope.file);
    });

    test('the names the database expects are the ones we send', () {
      expect(TaskState.done.dbName, 'done');
      expect(TaskState.notStarted.dbName, 'not_started');
      expect(TaskScope.personal.dbName, 'personal');
    });
  });
}
