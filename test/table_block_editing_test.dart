import 'package:flutter_test/flutter_test.dart';
import 'package:hajjoperations/core/l10n/localized_name.dart';
import 'package:hajjoperations/features/modules/domain/reference_item.dart';
import 'package:hajjoperations/features/reports/application/report_editor_cubit.dart';
import 'package:hajjoperations/features/reports/domain/report.dart';

/// Editing a table that has an expansion, without corrupting it.
///
/// توزيع الوجبات is the shape that found all three of these: four typed
/// columns (التاريخ، الوجبة، النسبة، المجموع), thirteen generated ones spliced
/// between النسبة and المجموع, rows seventeen wide. Every rule here was broken
/// in a way that put a number under the wrong heading — the one error nobody
/// notices until the numbers are quoted.
void main() {
  ReferenceItem cluster(int i) => ReferenceItem(
    id: 'cluster-$i',
    setId: 'clusters-set',
    name: LocalizedName(ar: 'تكتل $i'),
  );

  final clusters = ReferenceSet(
    id: 'clusters-set',
    code: 'clusters',
    name: const LocalizedName(ar: 'التكتلات'),
    items: [for (var i = 0; i < 3; i++) cluster(i)],
  );

  /// A distribution-shaped block: typed columns أ ب ج د, expansion of three
  /// spliced at 3 (before د), rows seven wide.
  DraftBlock distribution() => DraftBlock(
    ReportBlockKind.table,
    data: {
      'columns': ['أ', 'ب', 'ج', 'د'],
      'expand': 'clusters',
      'expand_at': 3,
      'rows': [
        ['a', 'b', 'c', 'x0', 'x1', 'x2', 'd'],
      ],
    },
  );

  ReportEditorCubit cubit({DraftBlock? block}) {
    final c = ReportEditorCubit.forTest(
      const ReportEditorState(status: EditorStatus.ready),
    );
    c.emit(
      c.state.copyWith(
        referenceSets: [clusters],
        blocks: [block ?? distribution()],
      ),
    );
    return c;
  }

  group('the draft mirrors what the reader reads', () {
    test('expand_at reaches the draft', () {
      // This getter was MISSING from DraftBlock, which is half the corruption:
      // the editor read the generated block as sitting at the end while the
      // reader spliced it into the middle.
      expect(distribution().expandAt, 3);
    });

    test('and a typed column after the splice lands past the expansion', () {
      expect(distribution().effectiveIndexOf(3, 3), 6);
      expect(distribution().effectiveIndexOf(2, 3), 2);
    });
  });

  group('a new row', () {
    test('is born as wide as the table, not as wide as its typed columns', () {
      // Born four cells wide, a seventeen-column row was unfillable past
      // position 3 — and the first cluster count typed into it landed under
      // المجموع.
      final c = cubit()..addBlockRow(0);

      expect(c.state.blocks[0].rows.last, hasLength(7));
    });
  });

  group('editing the headings', () {
    test('renaming one keeps every generated cell', () {
      // realignRows returns rows of `after.length`. Handed the whole row, it
      // returned FOUR cells — the three cluster counts and the total were
      // simply gone, on a rename.
      final c = cubit()..setBlockColumns(0, ['أ', 'باء', 'ج', 'د']);

      expect(c.state.blocks[0].rows.single, [
        'a', 'b', 'c', 'x0', 'x1', 'x2', 'd',
      ]);
    });

    test('adding a typed column keeps the generated block where it was', () {
      final c = cubit()..setBlockColumns(0, ['أ', 'ب', 'ج', 'د', 'هـ']);

      final b = c.state.blocks[0];
      expect(b.expandAt, 3);
      expect(b.rows.single, ['a', 'b', 'c', 'x0', 'x1', 'x2', 'd', '']);
    });

    test('removing typed columns clamps the splice rather than losing it', () {
      final c = cubit()..setBlockColumns(0, ['أ', 'ب']);

      final b = c.state.blocks[0];
      expect(b.expandAt, 2);
      expect(b.rows.single, ['a', 'b', 'x0', 'x1', 'x2']);
    });
  });

  group('changing the expansion', () {
    test('cuts the generated cells OUT, keeping what sits after them', () {
      // The old truncation kept the first `columns.length` cells — which on
      // this shape kept the clusters and threw away المجموع.
      final c = cubit()..setBlockExpand(0, null);

      expect(c.state.blocks[0].rows.single, ['a', 'b', 'c', 'd']);
    });
  });

  test('a cell is written at the effective index the UI names', () {
    final c = cubit()..setBlockCell(0, 0, 6, 'total');

    expect(c.state.blocks[0].rows.single[6], 'total');
    expect(
      c.state.blocks[0].rows.single[3],
      'x0',
      reason: 'المجموع wrote over the first تكتل',
    );
  });
}
