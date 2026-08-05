import '../../../core/attachments/attachment.dart';
import '../../../core/l10n/localized_name.dart';
import 'report_block.dart';

export 'report_block.dart';

export '../../../core/attachments/attachment.dart';

/// The paper a report was typed from. Same shape as every other attachment in
/// the app, pointing into the private `reports` bucket.
typedef ReportAttachment = StoredAttachment;

/// One row of a report's table.
///
/// Its values are keyed by the column's key — and, for a column that expands
/// over a master-data list, by the reference item's id. So a distribution row
/// holds `day`, `meal`, `ratio`, `total`, and one entry per تكتل under that
/// cluster's id.
class ReportRow {
  const ReportRow({required this.id, this.data = const {}, this.sortOrder = 0});

  final String id;
  final Map<String, dynamic> data;
  final int sortOrder;

  String value(String key) => data[key]?.toString() ?? '';

  factory ReportRow.fromMap(Map<String, dynamic> map) => ReportRow(
    id: map['id'] as String,
    data: Map<String, dynamic>.from(
      (map['data'] as Map?) ?? const <String, dynamic>{},
    ),
    sortOrder: (map['sort_order'] as int?) ?? 0,
  );
}

/// A published **قرار** — a decision: what it says about itself, and its table.
///
/// The word in the code and the word on the screen do not match, and the
/// mismatch is deliberate rather than an oversight.
///
/// What this feature holds are the mission's DECISIONS — the numbered
/// resolutions and circulars published to everybody, each with its number, its
/// scope and the table under it. It was built and named "reports" by mistake,
/// and the screens now say القرارات / Decisions, which is what the Administration
/// has always called them.
///
/// The identifiers did not follow: the table is `reports`, the routes are
/// `/reports` and `/reports/manage`, the permission codes are `reports.*`, and
/// six migrations up to 0071 are written against those names. Renaming them
/// would be a schema change, a permission migration and a re-grant for every
/// account holding one — real risk taken during a season, to fix a word that
/// nobody but a developer reads.
///
/// **Do not confuse this with a تقرير.** That word is still in use and still
/// correct, for a different thing entirely: `module_reports`, what a member
/// files against his own operational file on its cadence (0044). The two are
/// separate tables, separate screens and separate permissions, and the Arabic
/// labels now keep them apart — القرارات here, التقارير there.
class Report {
  const Report({
    required this.id,
    required this.reportTypeId,
    required this.title,
    this.number,
    this.seasonId,
    this.seasonHijriYear,
    this.typeName,
    this.data = const {},
    this.isPublished = false,
    this.rows = const [],
    this.blocks = const [],
    this.attachments = const [],
    required this.updatedAt,
  });

  final String id;
  final String reportTypeId;
  final String title;

  /// The reference number it was issued under — 3190, 3190/47 — when it has
  /// one. Free text, because that is how they are written, and optional,
  /// because a meal timetable is published without one.
  final String? number;

  /// Null means GENERAL: true whichever season is being run. Most of what gets
  /// written down outlives one year, which is why it is the default.
  final String? seasonId;
  final int? seasonHijriYear;

  /// Joined for the list, which shows what kind of report each one is.
  final LocalizedName? typeName;

  /// Header field values, keyed by the type's field keys.
  final Map<String, dynamic> data;

  final bool isPublished;
  final List<ReportRow> rows;

  /// What a WRITTEN report contains, in reading order. Empty for a typed one,
  /// whose content is its table.
  final List<ReportBlock> blocks;

  final List<ReportAttachment> attachments;
  final DateTime updatedAt;

  bool get isSeasonal => seasonId != null;

  Report withRows(List<ReportRow> rows) => _copy(rows: rows);
  Report withAttachments(List<ReportAttachment> a) => _copy(attachments: a);

  /// Whether this one is written rather than typed — which decides whether the
  /// page draws blocks or a table.
  bool get isWritten => blocks.isNotEmpty;

  Report _copy({List<ReportRow>? rows, List<ReportAttachment>? attachments}) =>
      Report(
        id: id,
        reportTypeId: reportTypeId,
        title: title,
        number: number,
        seasonId: seasonId,
        seasonHijriYear: seasonHijriYear,
        typeName: typeName,
        data: data,
        isPublished: isPublished,
        rows: rows ?? this.rows,
        blocks: blocks,
        attachments: attachments ?? this.attachments,
        updatedAt: updatedAt,
      );

  factory Report.fromMap(Map<String, dynamic> map) {
    final type = map['report_types'] as Map<String, dynamic>?;
    final season = map['seasons'] as Map<String, dynamic>?;
    final rows =
        ((map['report_rows'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(ReportRow.fromMap)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final blocks =
        ((map['report_blocks'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(ReportBlock.fromMap)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Report(
      id: map['id'] as String,
      reportTypeId: map['report_type_id'] as String,
      title: map['title'] as String,
      number: map['number'] as String?,
      seasonId: map['season_id'] as String?,
      seasonHijriYear: season?['hijri_year'] as int?,
      typeName: type == null ? null : LocalizedName.fromMap(type),
      data: Map<String, dynamic>.from(
        (map['data'] as Map?) ?? const <String, dynamic>{},
      ),
      isPublished: (map['is_published'] as bool?) ?? false,
      rows: rows,
      blocks: blocks,
      attachments: ((map['report_attachments'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(ReportAttachment.fromMap)
          .toList(),
      // Local time, not the server's UTC: shown to a person, and near
      // midnight the raw value even lands on the wrong date.
      updatedAt: DateTime.parse(
        (map['updated_at'] ?? map['created_at']) as String,
      ).toLocal(),
    );
  }
}
