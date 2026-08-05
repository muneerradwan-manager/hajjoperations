import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajjoperations/core/constants/permission_codes.dart';
import 'package:hajjoperations/core/l10n/localized_name.dart';
import 'package:hajjoperations/features/export/data/export_catalog.dart';
import 'package:hajjoperations/features/export/data/export_runner.dart';
import 'package:hajjoperations/features/export/domain/export_dataset.dart';
import 'package:hajjoperations/l10n/app_localizations.dart';

LocalizedName n(String ar, [String? en]) => LocalizedName(ar: ar, en: en);

/// A dataset with no database behind it, so the assembling can be tested apart
/// from the fetching. They fail differently and should be caught apart:
/// fetching is where the wrong ROWS come from, assembling is where the wrong
/// COLUMNS do.
class _Fake extends ExportDataset {
  _Fake({this.rows = const []});

  final List<Map<String, String>> rows;

  @override
  String get id => 'fake';

  @override
  LocalizedName get name => n('وهمي', 'Fake');

  @override
  String? get permission => null;

  @override
  List<ExportColumn> get columns => [
    ExportColumn(key: 'name', label: n('الاسم', 'Name')),
    ExportColumn(key: 'job', label: n('المهنة', 'Job')),
    ExportColumn(key: 'email', label: n('البريد', 'Email')),
    ExportColumn(key: 'id', label: n('المعرّف', 'Id'), byDefault: false),
  ];

  @override
  Future<List<Map<String, String>>> fetch(ExportRequest request) async => rows;
}

void main() {
  late AppLocalizations ar;
  late AppLocalizations en;

  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    ar = await AppLocalizations.delegate.load(const Locale('ar'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  ExportRequest request(Set<String> columns, {bool arabic = true}) =>
      ExportRequest(
        columnKeys: columns,
        l: arabic ? ar : en,
        languageCode: arabic ? 'ar' : 'en',
      );

  group('choosing the columns', () {
    final dataset = _Fake(
      rows: [
        {'name': 'منير', 'job': 'مشرف', 'email': 'a@b.c', 'id': '1'},
        {'name': 'أحمد', 'job': 'سائق', 'email': 'd@e.f', 'id': '2'},
      ],
    );

    test('only what was ticked comes out', () async {
      final table = await ExportRunner.buildTable(
        dataset: dataset,
        request: request({'name', 'job'}),
        columns: dataset.columns,
      );

      expect(table.headers, ['الاسم', 'المهنة']);
      expect(table.rows.first, ['منير', 'مشرف']);
    });

    test('the order is the dataset\'s, not the order of ticking', () async {
      // A sheet whose columns land in different places depending on which
      // checkbox somebody pressed first is a sheet nobody can put beside
      // another one.
      final table = await ExportRunner.buildTable(
        dataset: dataset,
        request: request({'email', 'name'}),
        columns: dataset.columns,
      );

      expect(table.headers, ['الاسم', 'البريد']);
    });

    test('the defaults are the ticked ones', () {
      expect(dataset.defaultColumns, {'name', 'job', 'email'});
      expect(
        dataset.defaultColumns,
        isNot(contains('id')),
        reason: 'the long tail is offered, not given',
      );
    });

    test('a column no row has anything for is an empty cell, not a gap', () async {
      final sparse = _Fake(rows: [
        {'name': 'منير'},
      ]);

      final table = await ExportRunner.buildTable(
        dataset: sparse,
        request: request({'name', 'job', 'email'}),
        columns: sparse.columns,
      );

      expect(
        table.rows.single,
        ['منير', '', ''],
        reason: 'a short row would shift every cell after it into the wrong '
            'column, and nothing would say so',
      );
    });

    test('no rows still produces the headings', () async {
      final table = await ExportRunner.buildTable(
        dataset: _Fake(),
        request: request({'name'}),
        columns: _Fake().columns,
      );

      expect(table.headers, ['الاسم']);
      expect(table.rows, isEmpty);
    });
  });

  group('language', () {
    test('the headings follow the language the export was asked for', () async {
      final dataset = _Fake();
      final table = await ExportRunner.buildTable(
        dataset: dataset,
        request: request({'name', 'job'}, arabic: false),
        columns: dataset.columns,
      );

      expect(table.headers, ['Name', 'Job']);
      expect(table.title, 'Fake');
    });

    test('an untranslated name falls back to Arabic rather than to blank', () {
      // Master data is content: half the lists were never given an English
      // name, and a blank column heading is worse than an Arabic one.
      expect(n('التكتلات').inLanguage('en'), 'التكتلات');
      expect(n('التكتلات', '').inLanguage('en'), 'التكتلات');
      expect(n('التكتلات', 'Clusters').inLanguage('en'), 'Clusters');
    });
  });

  group('the file name', () {
    test('it is ASCII and dated', () {
      final name = ExportRunner.fileName(_Fake(), ExportFormat.csv);

      expect(name, matches(RegExp(r'^fake-\d{4}-\d{2}-\d{2}\.csv$')));
      expect(
        name.codeUnits.every((c) => c < 128),
        isTrue,
        reason: 'it goes through a file system, a share sheet and an email, '
            'and an Arabic file name survives only some of those',
      );
    });

    test('the format decides the extension', () {
      expect(
        ExportRunner.fileName(_Fake(), ExportFormat.pdf),
        endsWith('.pdf'),
      );
    });
  });

  group('who is offered what', () {
    test('a dataset behind a permission is not offered without it', () {
      final offered = ExportCatalog.visibleTo(isAdmin: false, permissions: {});

      expect(
        offered.map((d) => d.id),
        isNot(contains('employees')),
        reason: 'employees.view opens the directory; without it there is '
            'nothing to take out of it either',
      );
    });

    test('holding the permission offers it', () {
      final offered = ExportCatalog.visibleTo(
        isAdmin: false,
        permissions: {PermissionCodes.employeesView},
      );

      expect(offered.map((d) => d.id), contains('employees'));
    });

    test('an admin is offered everything', () {
      final offered = ExportCatalog.visibleTo(isAdmin: true, permissions: {});

      expect(offered.length, ExportCatalog.all.length);
    });

    test('what needs no permission is always offered', () {
      final offered = ExportCatalog.visibleTo(isAdmin: false, permissions: {});

      expect(
        offered.map((d) => d.id),
        containsAll(['modules', 'reports']),
        reason: 'these are narrowed by row security rather than by a code, '
            'and a person sees exactly what he sees on their screens',
      );
    });

    test('every dataset in the catalogue has a distinct id', () {
      // The id is written into the file name and is how a dataset is found
      // again. Two of them sharing one is a bug that shows up as the wrong
      // export.
      final ids = ExportCatalog.all.map((d) => d.id).toList();

      expect(ids.toSet().length, ids.length);
    });

    test('every column key within a dataset is distinct', () {
      for (final dataset in ExportCatalog.all) {
        final keys = dataset.columns.map((c) => c.key).toList();
        expect(
          keys.toSet().length,
          keys.length,
          reason: 'in ${dataset.id}, a duplicate key means one column silently '
              'takes the other\'s values',
        );
      }
    });

    test('every dataset gives something by default', () {
      for (final dataset in ExportCatalog.all) {
        expect(
          dataset.defaultColumns,
          isNotEmpty,
          reason: '${dataset.id} would open with the export button dead',
        );
      }
    });
  });
}
