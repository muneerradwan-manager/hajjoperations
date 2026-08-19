import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajjoperations/core/l10n/localized_name.dart';
import 'package:hajjoperations/features/export/data/csv_writer.dart';
import 'package:hajjoperations/features/export/data/export_catalog.dart';
import 'package:hajjoperations/features/export/domain/export_dataset.dart';

/// An export is a DOCUMENT now, not a sheet.
///
/// It used to be three datasets — the files, the members of a file, the duties
/// of a file — which is three wrong answers to one question. Nobody exports
/// "the members of a file" as an errand of its own: they are asked for تشكيل
/// فرق المشاعر and they want the file. So they exported the roster, went back
/// and exported the duties, and ended holding two sheets that nothing tied
/// together and no record of which file either came from.
///
/// The parts of a thing cannot be one table — a roster and a set of duties do
/// not share a set of columns — so the writers had to learn sections. What is
/// asserted here is that they did, and that a plain list did not change shape
/// underneath them on the way.
LocalizedName n(String ar, [String? en]) => LocalizedName(ar: ar, en: en);

ExportTable table(
  String title,
  List<String> headers,
  List<List<String>> rows,
) => ExportTable(title: title, headers: headers, rows: rows);

String csv(ExportDocument document) =>
    utf8.decode(CsvWriter.write(document).sublist(3)); // past the BOM

void main() {
  setUpAll(() => WidgetsFlutterBinding.ensureInitialized());

  group('the catalogue after the change', () {
    test('one file dataset, and the three it replaced are gone', () {
      final ids = ExportCatalog.all.map((d) => d.id).toSet();

      expect(ids, contains('module'));
      expect(ids, isNot(contains('modules')));
      expect(ids, isNot(contains('module_members')));
      expect(ids, isNot(contains('module_tasks')));
    });

    test('the file is exported by its parts, and it insists on a file', () {
      final dataset = ExportCatalog.byId('module')!;

      expect(dataset.columns.map((c) => c.key), [
        'info',
        'members',
        'tasks',
        'reports',
      ]);
      // Every part on by default: somebody asking for a file wants the file.
      expect(dataset.defaultColumns.length, dataset.columns.length);

      // "Everything in" no file in particular is not a question with an answer.
      final option = dataset.options.singleWhere((o) => o.key == 'module');
      expect(option.required, isTrue);
    });

    test('a decision may be named, and need not be', () {
      final dataset = ExportCatalog.byId('reports')!;
      final option = dataset.options.singleWhere((o) => o.key == 'report');

      // Optional on purpose: unanswered it is the index of what has been
      // issued, which is the question somebody asks BEFORE they know which
      // decision they want. Required would have taken that away.
      expect(option.required, isFalse);
    });

    test('the parts are labelled parts, and columns columns', () {
      expect(ExportCatalog.byId('module')!.partsLabel.ar, 'الأقسام');
      expect(ExportCatalog.byId('employees')!.partsLabel.ar, 'الأعمدة');
    });
  });

  group('a field value a person can read', () {
    test('a stored file gives up its name, never its path', () {
      // The bug this exists for, exactly as it reached a real sheet:
      //   {name: تكليف اداري.docx, path: 8c2b8c25-…/3142-_47.docx}
      // A storage key, printed in the cell where the document's name belongs,
      // in a file that then goes to whoever asked for it. `toString()` on a
      // Map is never a value — it is the absence of a decision about one.
      expect(
        exportFieldValue({
          'name': 'تكليف اداري 2413-47هـ.docx',
          'path': '8c2b8c25-c182/3142-_47.docx',
        }),
        'تكليف اداري 2413-47هـ.docx',
      );
    });

    test('a stored file with no name is named by what it is', () {
      expect(exportFieldValue({'path': 'a/b.docx'}), '—');
    });

    test('ordinary values pass through, and nothing is nothing', () {
      expect(exportFieldValue('120'), '120');
      expect(exportFieldValue(null), '');
      expect(exportFieldValue(const <String, dynamic>{}), '');
    });

    test('a list of files reads as a list of names', () {
      expect(
        exportFieldValue([
          {'name': 'أ.pdf', 'path': 'x'},
          {'name': 'ب.pdf', 'path': 'y'},
        ]),
        'أ.pdf، ب.pdf',
      );
    });
  });

  group('the season, and what it narrows', () {
    test('a decision is narrowed by season; a file is not asked', () {
      // «عام» is offered only where a general row can exist. A decision may
      // belong to no season — most of what the mission writes down outlives one
      // year — and a file may not, so a season filter there would narrow
      // nothing that naming the file has not already decided.
      //
      // Not `await option.choices(...)`: that reads the seasons out of the
      // database, and what is worth pinning here is the shape of the screen,
      // which is settled before anything is fetched.
      final reports = ExportCatalog.byId('reports')!;
      final season = reports.options.singleWhere((o) => o.key == 'season');
      expect(season.required, isFalse);

      final module = ExportCatalog.byId('module')!;
      expect(module.options.where((o) => o.key == 'season'), isEmpty);
    });

    test('the decision list is re-asked when the season changes', () {
      // Declared rather than inferred: without it the screen offered every
      // decision the mission has ever issued under a heading naming one season
      // — and an answer already given could survive into the request while
      // nothing on screen still showed it.
      final reports = ExportCatalog.byId('reports')!;
      final report = reports.options.singleWhere((o) => o.key == 'report');

      expect(report.dependsOn, contains('season'));
    });

    test('«عام» is a sentinel, not something that could be a season id', () {
      // It is the ABSENCE of a season. Were it ever a real uuid the two would
      // be indistinguishable at the point where the meaning is decided.
      expect(kGeneralSeason, 'general');
      expect(kGeneralSeason.contains('-'), isFalse);
    });
  });

  group('a column nobody can read', () {
    test('a column empty in every row is dropped, the name never', () {
      // «الموقع: على الملف نفسه» was printed on all twenty rows of a file with
      // no tree — one sentence repeated down a column, and not one fact in it.
      // The roster's columns are not chosen by the reader, so the sheet is the
      // only thing that can decide a column is not worth its width.
      final rows = [
        ['منير', 'مشرف', '', 'مشرف', '', '', 'a@b.c'],
        ['أحمد', 'عضو', '', 'سائق', '', '', 'd@e.f'],
      ];
      final keep = [
        for (var c = 0; c < 7; c++)
          if (c == 0 || rows.any((r) => r[c].trim().isNotEmpty)) c,
      ];

      expect(keep, [0, 1, 3, 6]);
    });

    test('the name column survives even when it is empty', () {
      // A nameless roster is not a shorter roster.
      final rows = [
        ['', 'مشرف'],
      ];
      final keep = [
        for (var c = 0; c < 2; c++)
          if (c == 0 || rows.any((r) => r[c].trim().isNotEmpty)) c,
      ];

      expect(keep, contains(0));
    });
  });

  group('what the CSV looks like', () {
    test('one section is a plain sheet, exactly as it always was', () {
      final out = csv(
        ExportDocument(
          title: 'الموظفون',
          sections: [
            table(
              'الموظفون',
              ['الاسم', 'المهنة'],
              [
                ['منير', 'مشرف'],
              ],
            ),
          ],
        ),
      );

      // No heading, no blank line — a list must not grow furniture because the
      // writer learned to do something else.
      expect(out, 'الاسم,المهنة\r\nمنير,مشرف\r\n');
    });

    test('several are named and separated by a blank line', () {
      final out = csv(
        ExportDocument(
          title: 'ملف تشغيلي',
          sections: [
            table(
              'معلومات الملف',
              ['البند', 'القيمة'],
              [
                ['النوع', 'فرق المشاعر'],
              ],
            ),
            table(
              'الأعضاء',
              ['الاسم', 'الصفات'],
              [
                ['منير', 'مشرف'],
              ],
            ),
          ],
        ),
      );

      expect(out.split('\r\n'), [
        'معلومات الملف',
        'البند,القيمة',
        'النوع,فرق المشاعر',
        '',
        'الأعضاء',
        'الاسم,الصفات',
        'منير,مشرف',
        '',
      ]);
    });

    test('a section note rides under its heading', () {
      final out = csv(
        ExportDocument(
          title: 'قرار',
          sections: [
            table(
              'بيانات القرار',
              ['البند', 'القيمة'],
              [
                ['الرقم', '3190'],
              ],
            ),
            ExportTable(
              title: 'المتن',
              note: 'كما كُتب، بترتيبه.',
              headers: const ['النوع', 'النص'],
              rows: const [
                ['فقرة', 'نص القرار'],
              ],
            ),
          ],
        ),
      );

      expect(out, contains('المتن\r\nكما كُتب، بترتيبه.\r\nالنوع,النص\r\n'));
    });
  });

  group('what the person is told afterwards', () {
    test('the row count is counted across every section', () {
      // "Exported" and "exported nothing" look identical once the file is in a
      // folder. Counting one section would have called a four-section file of
      // ninety rows an export of two.
      final document = ExportDocument(
        title: 'ملف',
        sections: [
          table(
            'أ',
            ['x'],
            [
              ['1'],
              ['2'],
            ],
          ),
          table(
            'ب',
            ['y'],
            [
              ['3'],
            ],
          ),
        ],
      );

      expect(document.rowCount, 3);
      expect(document.isEmpty, isFalse);
    });

    test('every section empty is an empty export', () {
      final document = ExportDocument(
        title: 'ملف',
        sections: [
          table('أ', ['x'], const []),
          table('ب', ['y'], const []),
        ],
      );

      expect(document.rowCount, 0);
      expect(document.isEmpty, isTrue);
    });
  });
}
