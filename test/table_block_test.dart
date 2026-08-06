import 'package:flutter_test/flutter_test.dart';
import 'package:hajjoperations/features/reports/domain/report_block.dart';

ReportBlock table(Map<String, dynamic> data) =>
    ReportBlock(id: 'b-1', kind: ReportBlockKind.table, data: data);

/// A table written inside a قرار, reaching what only a report TYPE could reach.
///
/// The three meal shapes — توزيع، مواعيد، مكونات — were report types of their
/// own because a hand-written table could not do two things: grow a column per
/// تكتل from master data, and print a repeated value once against the rows it
/// covers. A type that exists only to supply those two is not a kind of
/// document; it is a table with extra powers. So the powers moved to the table
/// and the types stopped being needed (0102).
void main() {
  group('a column per entry of a list', () {
    test('the block names the list, not its entries', () {
      // By CODE rather than by id, and that is the whole reason this survives a
      // season roll: the entries differ next year, the list does not. A
      // document written this season still resolves against next season's
      // تكتلات without anybody opening it.
      final block = table({
        'columns': ['التاريخ', 'الوجبة'],
        'expand': 'clusters',
      });

      expect(block.expandSetCode, 'clusters');
      expect(block.columns, ['التاريخ', 'الوجبة']);
    });

    test('and the headings it actually has are both together', () {
      final block = table({
        'columns': ['التاريخ', 'الوجبة'],
        'expand': 'clusters',
      });

      expect(
        block.effectiveColumns(['تكتل الكعبة', 'تكتل عطاء']),
        ['التاريخ', 'الوجبة', 'تكتل الكعبة', 'تكتل عطاء'],
      );
    });

    test('an ordinary table ignores what it was handed', () {
      // No `expand`, so nothing is appended even if a caller resolves something
      // — the block decides, not the screen.
      final block = table({
        'columns': ['البند', 'العدد'],
      });

      expect(block.expandSetCode, isNull);
      expect(block.effectiveColumns(['تكتل الكعبة']), ['البند', 'العدد']);
    });

    test('an empty expand is no expand', () {
      // A dropdown set back to "none" writes '' rather than removing the key,
      // and '' must not read as a list whose code is the empty string.
      expect(table({'expand': ''}).expandSetCode, isNull);
      expect(table({'expand': '  '}).expandSetCode, isNull);
    });
  });

  group('a value printed once against the rows it covers', () {
    test('which columns merge is per column, and false past the end', () {
      final block = table({
        'columns': ['التاريخ', 'الوجبة', 'النسبة'],
        'spans': [true, false],
      });

      expect(block.spansAt(0), isTrue);
      expect(block.spansAt(1), isFalse);
      // Never declared, because `spans` was written when the table had two
      // columns and a third was added after.
      expect(block.spansAt(2), isFalse);
      // And past the columns entirely.
      expect(block.spansAt(9), isFalse);
    });

    test('a table that never declared any merges nothing', () {
      final block = table({
        'columns': ['البند', 'العدد'],
      });

      expect(block.spans, isEmpty);
      expect(block.spansAt(0), isFalse);
    });

    test('a non-boolean in the list is not a merge', () {
      // The jsonb is written by an editor and read by a reader, and anything
      // that ever put a string there must not read as true.
      final block = table({
        'columns': ['أ', 'ب'],
        'spans': ['yes', 1],
      });

      expect(block.spansAt(0), isFalse);
      expect(block.spansAt(1), isFalse);
    });
  });

  test('an empty table is still empty when it only names a list', () {
    // `expand` alone is a table somebody started and did not fill. It must not
    // render as a header row over nothing.
    expect(table({'expand': 'clusters'}).isEmpty, isTrue);
    expect(
      table({
        'columns': ['أ'],
        'rows': [
          ['1'],
        ],
      }).isEmpty,
      isFalse,
    );
  });
}
