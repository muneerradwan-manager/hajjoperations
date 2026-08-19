import '../../../core/l10n/localized_name.dart';
import '../../../l10n/app_localizations.dart';

/// One field a dataset can put in a column.
///
/// A dataset offers every column it HAS; the person exporting picks the ones he
/// wants and their order is this list's order. Nothing is computed for a column
/// nobody asked for.
class ExportColumn {
  const ExportColumn({
    required this.key,
    required this.label,
    this.byDefault = true,
  });

  /// Stable, and the key each row is written under. Never renamed: it is what a
  /// saved selection is remembered by.
  final String key;

  final LocalizedName label;

  /// Whether it starts ticked. The identifying columns do; a person opening a
  /// list of forty fields should get a sensible sheet by pressing export, and
  /// should have to ask for the rest.
  final bool byDefault;
}

/// A choice a dataset needs before it can fetch anything — which season, which
/// master-data list, which operational file.
///
/// Kept separate from the columns because it changes WHICH ROWS there are, not
/// which parts of them are shown. Getting that wrong is how an export quietly
/// returns last season's people.
class ExportOption {
  const ExportOption({
    required this.key,
    required this.label,
    required this.choices,
    this.required = true,
    this.dependsOn = const {},
  });

  final String key;
  final LocalizedName label;

  /// Resolved when the screen opens, because most of these are database lists.
  ///
  /// It is handed the answers given SO FAR, so an option can narrow itself by
  /// one above it: naming the season and then being offered every decision the
  /// mission has ever issued is the screen contradicting itself in the space of
  /// two rows.
  final Future<List<ExportChoice>> Function(Map<String, String> answers)
  choices;

  final bool required;

  /// The options whose answers change THIS one's list.
  ///
  /// Declared rather than inferred, and re-resolved rather than filtered in
  /// place: an answer that is no longer among the choices has to be dropped,
  /// not left sitting in the request where nothing on screen shows it.
  final Set<String> dependsOn;
}

class ExportChoice {
  const ExportChoice({required this.id, required this.label});
  final String id;
  final LocalizedName label;
}

/// What the person asked for.
class ExportRequest {
  const ExportRequest({
    required this.columnKeys,
    required this.l,
    required this.languageCode,
    this.options = const {},
  });

  /// Which columns, and in the dataset's own order rather than in the order
  /// they happened to be ticked.
  final Set<String> columnKeys;

  /// The answers to [ExportDataset.options], by key.
  final Map<String, String> options;

  /// The language the file comes out in, carried rather than read from a
  /// context: the file is built after the screen that asked for it may already
  /// have gone, and half a sheet in each language is not a sheet.
  final AppLocalizations l;
  final String languageCode;

  String? option(String key) => options[key];

  bool wants(String columnKey) => columnKeys.contains(columnKey);

  String text(LocalizedName? name) => name?.inLanguage(languageCode) ?? '';
}

/// One kind of thing that can be taken out of this app.
///
/// The catalogue is deliberately built out of these rather than out of an
/// export button on each screen. A button on a screen exports what that screen
/// happens to be showing — the filter that was applied, the hundred rows that
/// were loaded — and the person cannot tell which. A dataset states what it
/// fetches and is answerable for it.
///
/// Every one of them reads through the ordinary repositories, so row security
/// narrows an export exactly as it narrows the screen. [permission] is what
/// decides whether the dataset is OFFERED; it is not what makes it safe.
abstract class ExportDataset {
  const ExportDataset();

  /// Stable identifier. Written into the file name and into a saved selection.
  String get id;

  LocalizedName get name;

  /// The permission code that opens it, or null when anybody may.
  String? get permission;

  List<ExportColumn> get columns;

  List<ExportOption> get options => const [];

  /// Columns that only exist once an option has been answered.
  ///
  /// The master-data lists are why. A hotel has a capacity and a camp has a
  /// location — extra fields the Administration adds to a list during a season,
  /// held in the row's own JSON. They are real columns of that list and a
  /// person exporting the hotels should be offered them; but they cannot be
  /// named until he has said WHICH list, and a catalogue that had to be edited
  /// whenever a field was added would always be a season behind.
  ///
  /// Resolved by the screen after the options are chosen, and appended to
  /// [columns]. Off by default: they are the long tail, and the sheet a person
  /// gets for pressing export should be the short one.
  Future<List<ExportColumn>> extraColumns(Map<String, String> options) async =>
      const [];

  /// What the ticked list is CALLED on this dataset's card.
  ///
  /// A list of people is narrowed by columns. A thing exported whole — one
  /// file, one decision — is not: its parts are a roster and a set of duties
  /// and a body of text, each with columns of its own that the reader never
  /// chooses between. Calling both "الأعمدة" made the second read as though
  /// ticking «الأعضاء» would add a column called members.
  LocalizedName get partsLabel =>
      const LocalizedName(ar: 'الأعمدة', en: 'Columns');

  /// The whole export, as one or more titled tables.
  ///
  /// A list is one table. A THING is several — the file's own particulars, then
  /// its roster, then its duties — and they cannot be one table because they do
  /// not share a set of columns. That is the difference this method exists to
  /// carry; see [ExportListDataset] for the common case.
  ///
  /// [chosen] is what was ticked, already narrowed and in this dataset's own
  /// order.
  Future<List<ExportTable>> build(
    ExportRequest request,
    List<ExportColumn> chosen,
  );

  /// The columns the person gets before touching anything.
  Set<String> get defaultColumns => {
    for (final column in columns)
      if (column.byDefault) column.key,
  };
}

/// A dataset that is ONE list: a set of columns, and the rows under them.
///
/// Nearly all of them. It states its columns, it fetches its rows keyed by
/// those columns, and the narrowing is done here rather than in each of them.
abstract class ExportListDataset extends ExportDataset {
  const ExportListDataset();

  /// Reads the rows. Each row is keyed by [ExportColumn.key]; a key the row has
  /// nothing for is simply absent and comes out as an empty cell.
  Future<List<Map<String, String>>> fetch(ExportRequest request);

  @override
  Future<List<ExportTable>> build(
    ExportRequest request,
    List<ExportColumn> chosen,
  ) async {
    final rows = await fetch(request);
    return [
      ExportTable(
        title: request.text(name),
        headers: [for (final column in chosen) request.text(column.label)],
        rows: [
          for (final row in rows)
            [for (final column in chosen) row[column.key] ?? ''],
        ],
      ),
    ];
  }
}

/// A finished export: the headings, and the rows under them, both already
/// narrowed to what was asked for and in the dataset's column order.
class ExportTable {
  const ExportTable({
    required this.title,
    required this.headers,
    required this.rows,
    this.note,
  });

  final String title;
  final List<String> headers;
  final List<List<String>> rows;

  /// A line under the heading, where the section needs one — the body of a
  /// decision, which is prose and not a table, and would otherwise arrive as a
  /// one-column sheet with no explanation of why.
  final String? note;

  bool get isEmpty => rows.isEmpty;
}

/// A finished export: the sections, in the order they are read.
///
/// One section for a list, several for a thing taken whole. The writers take
/// this rather than a table so that neither of them has to know which it is.
class ExportDocument {
  const ExportDocument({required this.title, required this.sections});

  final String title;
  final List<ExportTable> sections;

  /// Counted across every section, because that is the number the person is
  /// told afterwards and "exported nothing" is the thing it has to catch.
  int get rowCount =>
      sections.fold(0, (total, section) => total + section.rows.length);

  bool get isEmpty => sections.every((section) => section.isEmpty);
}
