import 'package:flutter_test/flutter_test.dart';
import 'package:hajjoperations/features/reports/domain/table_columns.dart';

/// A table's rows are positioned against its columns, so every change to the
/// columns has to move the cells with them. Getting it wrong puts a column of
/// numbers under the wrong heading — which nobody notices until they are
/// quoted, and by then the report has been read.
void main() {
  const rows = [
    ['8 ذي الحجة', 'غداء', '250'],
    ['9 ذي الحجة', 'فطور', '1010'],
  ];
  const before = ['اليوم', 'الوجبة', 'العدد'];

  group('realignRows', () {
    test('nothing changed leaves every cell where it was', () {
      expect(
        realignRows(before: before, after: before, rows: rows),
        rows,
      );
    });

    test('a column added at the end leaves the rest alone and blanks the new', () {
      expect(
        realignRows(
          before: before,
          after: [...before, 'ملاحظات'],
          rows: rows,
        ),
        [
          ['8 ذي الحجة', 'غداء', '250', ''],
          ['9 ذي الحجة', 'فطور', '1010', ''],
        ],
      );
    });

    test('a column added in the MIDDLE does not shift what follows it', () {
      // The failure this exists for: inserting a heading and finding every
      // number after it now reads under its neighbour.
      expect(
        realignRows(
          before: before,
          after: ['اليوم', 'نوعها', 'الوجبة', 'العدد'],
          rows: rows,
        ),
        [
          ['8 ذي الحجة', '', 'غداء', '250'],
          ['9 ذي الحجة', '', 'فطور', '1010'],
        ],
      );
    });

    test('a removed column takes only its own cells', () {
      expect(
        realignRows(
          before: before,
          after: ['اليوم', 'العدد'],
          rows: rows,
        ),
        [
          ['8 ذي الحجة', '250'],
          ['9 ذي الحجة', '1010'],
        ],
      );
    });

    test('reordering carries each column with its heading', () {
      expect(
        realignRows(
          before: before,
          after: ['العدد', 'اليوم', 'الوجبة'],
          rows: rows,
        ),
        [
          ['250', '8 ذي الحجة', 'غداء'],
          ['1010', '9 ذي الحجة', 'فطور'],
        ],
      );
    });

    test('renaming one heading KEEPS its column', () {
      // The whole reason this function exists. Matching purely by name would
      // empty the column, because the new name was never in the old list —
      // and correcting a typo in a heading would silently discard a column of
      // numbers.
      expect(
        realignRows(
          before: before,
          after: ['التاريخ', 'الوجبة', 'العدد'],
          rows: rows,
        ),
        [
          ['8 ذي الحجة', 'غداء', '250'],
          ['9 ذي الحجة', 'فطور', '1010'],
        ],
      );
    });

    test('renaming the LAST heading keeps its column too', () {
      expect(
        realignRows(
          before: before,
          after: ['اليوم', 'الوجبة', 'المجموع'],
          rows: rows,
        ),
        rows,
      );
    });

    test('two headings changing at once is not guessed at', () {
      // Two renames, a swap and four separate edits are indistinguishable.
      // Guessing would move a column under the wrong heading on a guess, which
      // is worse than emptying it honestly.
      final out = realignRows(
        before: before,
        after: ['التاريخ', 'الصنف', 'العدد'],
        rows: rows,
      );
      expect(out, [
        ['', '', '250'],
        ['', '', '1010'],
      ]);
    });

    test('a swap is a reorder, not a rename', () {
      expect(
        realignRows(
          before: ['أ', 'ب'],
          after: ['ب', 'أ'],
          rows: const [
            ['1', '2'],
          ],
        ),
        [
          ['2', '1'],
        ],
      );
    });

    test('a short row is padded rather than throwing', () {
      // Rows entered before a column was added are shorter than the column
      // list, and reading past their end must not crash the editor.
      expect(
        realignRows(
          before: before,
          after: before,
          rows: const [
            ['8 ذي الحجة'],
          ],
        ),
        [
          ['8 ذي الحجة', '', ''],
        ],
      );
    });

    test('emptying the columns empties the rows with them', () {
      expect(
        realignRows(before: before, after: const [], rows: rows),
        [<String>[], <String>[]],
      );
    });

    test('no rows is no work', () {
      expect(
        realignRows(before: before, after: const ['أ'], rows: const []),
        isEmpty,
      );
    });
  });
}
