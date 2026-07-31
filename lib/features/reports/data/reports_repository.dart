import '../../../core/supabase/supabase_client.dart';
import '../domain/report.dart';
import '../domain/report_type.dart';

/// Reading the reports section.
///
/// RLS does the deciding: a published report is readable by any approved
/// account, an unpublished one only by whoever manages reports. So nothing here
/// filters on `is_published` — asking the database twice for the same rule is
/// how the two answers come to disagree.
class ReportsRepository {
  static const _columns = '''
    id, report_type_id, season_id, title, data, is_published, updated_at,
    created_at,
    report_types(name_ar, name_en),
    seasons(hijri_year)
  ''';

  /// The catalog: every kind of report, with its header fields and its columns.
  Future<List<ReportType>> fetchTypes() async {
    final rows = await supabase
        .from('report_types')
        .select(
          '*, report_type_fields(*), report_type_columns(*)',
        )
        .order('sort_order');
    return (rows as List)
        .map((r) => ReportType.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// The list, newest first.
  ///
  /// [seasonId] narrows to one season AND the general reports — a general
  /// report is true in every season, so filtering it out of one would be
  /// hiding something that applies. Null returns everything readable.
  Future<List<Report>> fetchReports({String? seasonId}) async {
    final query = supabase.from('reports').select(_columns);
    final rows = await (seasonId == null
            ? query
            : query.or('season_id.is.null,season_id.eq.$seasonId'))
        .order('updated_at', ascending: false);
    return (rows as List)
        .map((r) => Report.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// One report in full: its header, its table and its attachments.
  Future<Report?> fetchReport(String id) async {
    final row = await supabase
        .from('reports')
        .select('$_columns, report_rows(*), report_attachments(*)')
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Report.fromMap(row);
  }

  /// A signed URL for an attachment, minted on demand — the bucket is private.
  ///
  /// Same shape as the notifications signer, because [AttachmentSigner] is what
  /// the shared attachments widget takes: with [download], storage is asked to
  /// hand the file over under the name the filer's device gave it rather than
  /// opening it in a tab.
  Future<String> signedUrl(
    String path, {
    int expiresInSeconds = 3600,
    bool download = false,
    String? downloadName,
  }) {
    return supabase.storage
        .from('reports')
        .createSignedUrl(path, expiresInSeconds)
        .then((url) {
          if (!download) return url;
          final separator = url.contains('?') ? '&' : '?';
          final name = Uri.encodeComponent(downloadName ?? '');
          return '$url${separator}download${name.isEmpty ? '' : '=$name'}';
        });
  }
}
