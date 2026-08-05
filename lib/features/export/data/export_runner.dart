import 'dart:typed_data';

import '../domain/export_dataset.dart';
import 'csv_writer.dart';
import 'export_values.dart';
import 'pdf_writer.dart';

enum ExportFormat {
  csv,
  pdf;

  String get extension => switch (this) {
    ExportFormat.csv => 'csv',
    ExportFormat.pdf => 'pdf',
  };

  String get mimeType => switch (this) {
    ExportFormat.csv => 'text/csv',
    ExportFormat.pdf => 'application/pdf',
  };
}

/// A finished file, in memory, on its way to wherever the person sends it.
class ExportFile {
  const ExportFile({
    required this.name,
    required this.bytes,
    required this.format,
    required this.rowCount,
  });

  final String name;
  final Uint8List bytes;
  final ExportFormat format;

  /// Told to the person afterwards. "Exported" and "exported nothing" look
  /// identical once the file is in a folder, and the second one usually means a
  /// filter was left on rather than that there is nothing there.
  final int rowCount;
}

/// Takes a dataset, a request and a format, and produces the file.
///
/// The three steps are kept apart because each is a different kind of mistake:
/// fetching is where the wrong rows come from, assembling is where the wrong
/// columns do, and writing is where a correct table becomes an unreadable file.
abstract final class ExportRunner {
  static Future<ExportFile> run({
    required ExportDataset dataset,
    required ExportRequest request,
    required ExportFormat format,
    required List<ExportColumn> columns,
    required String subtitle,
    required String pageLabel,
  }) async {
    final table = await buildTable(
      dataset: dataset,
      request: request,
      columns: columns,
    );

    final bytes = switch (format) {
      ExportFormat.csv => CsvWriter.write(table),
      ExportFormat.pdf => await PdfWriter.write(
        table,
        subtitle: subtitle,
        pageLabel: pageLabel,
      ),
    };

    return ExportFile(
      name: fileName(dataset, format),
      bytes: bytes,
      format: format,
      rowCount: table.rows.length,
    );
  }

  /// Fetches and narrows, in the dataset's column order.
  ///
  /// [columns] is the full set the screen offered — the dataset's own plus any
  /// resolved from a chosen option — and the request says which of them were
  /// ticked. Ordering comes from this list rather than from the ticking, so
  /// that two people exporting the same dataset get columns in the same places.
  static Future<ExportTable> buildTable({
    required ExportDataset dataset,
    required ExportRequest request,
    required List<ExportColumn> columns,
  }) async {
    final chosen = [
      for (final column in columns)
        if (request.wants(column.key)) column,
    ];

    final rows = await dataset.fetch(request);

    return ExportTable(
      title: request.text(dataset.name),
      headers: [for (final column in chosen) request.text(column.label)],
      rows: [
        for (final row in rows)
          [
            for (final column in chosen)
              ExportValues.text(row[column.key]),
          ],
      ],
    );
  }

  /// `employees-2026-08-04.csv`.
  ///
  /// ASCII, and dated. The dataset id rather than its Arabic name because this
  /// goes into a file system, through a share sheet, and often into an email —
  /// three places where an Arabic file name survives sometimes and arrives as
  /// percent-escapes the rest of the time. The Arabic title is inside the file,
  /// where it is safe.
  static String fileName(ExportDataset dataset, ExportFormat format) =>
      '${dataset.id}-${ExportValues.date(DateTime.now())}.${format.extension}';
}
