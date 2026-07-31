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

/// A published report: what it says about itself, and its table.
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
      updatedAt: DateTime.parse(
        (map['updated_at'] ?? map['created_at']) as String,
      ),
    );
  }
}
