import 'dart:convert';
import 'dart:typed_data';

import '../domain/export_dataset.dart';

/// Turns a table into a CSV file Excel will open correctly in Arabic.
///
/// "Correctly" is the whole difficulty, and none of it is about commas.
///
///   * **The byte-order mark.** Excel on Windows does not read a plain UTF-8
///     CSV as UTF-8. It reads it in the machine's ANSI code page, and every
///     Arabic name in the file arrives as mojibake — the single most common way
///     an Arabic export is "broken" while being a perfectly valid file. Three
///     bytes at the front fix it, and nothing else does.
///   * **CRLF.** Excel's own dialect. A lone `\n` is tolerated by most
///     importers and by not quite all of them.
///
/// **There is deliberately no `sep=,` line, and it must not be added back.**
///
/// It looks like it belongs here. Excel splits on the list separator of the
/// reader's locale, so a comma-separated file can open as one long column on a
/// machine set to use semicolons, and `sep=,` on the first line is the standard
/// cure for that. It was here, and it broke this exporter.
///
/// The two fixes are each correct and cannot be used together: when the first
/// line is `sep=`, Excel takes a different path into the file and **stops
/// honouring the byte-order mark**, falling back to the ANSI code page — which
/// turns every Arabic name into mojibake. The symptom is the one the BOM was
/// put here to prevent, and it is caused by the line meant to help.
///
/// So the mark stays and the hint goes, because the two failures are not equal.
/// Without the mark, every cell is unreadable and the file is worthless. Without
/// the hint, the worst case is READABLE text that landed in one column, which a
/// person can split in ten seconds — and on most machines it does not happen at
/// all.
class CsvWriter {
  const CsvWriter._();

  static const _bom = [0xEF, 0xBB, 0xBF];
  static const _crlf = '\r\n';

  static Uint8List write(ExportTable table) {
    final buffer = StringBuffer()
      ..write(table.headers.map(escape).join(','))
      ..write(_crlf);

    for (final row in table.rows) {
      buffer
        ..write(row.map(escape).join(','))
        ..write(_crlf);
    }

    return Uint8List.fromList([..._bom, ...utf8.encode(buffer.toString())]);
  }

  /// Quotes a field when it has to be, and doubles any quote inside it.
  ///
  /// A leading `=`, `+`, `-` or `@` is prefixed with an apostrophe. That is not
  /// tidiness: a cell beginning with one of those is a FORMULA to Excel, and a
  /// value out of a free-text note — which in this app can be anything a person
  /// typed into a duty — becomes something the spreadsheet executes when the
  /// file is opened. The apostrophe is Excel's own way of saying "this is
  /// text"; it is not shown in the cell and does not survive a copy.
  static String escape(String value) {
    var text = value;
    if (text.isNotEmpty && const ['=', '+', '-', '@'].contains(text[0])) {
      text = "'$text";
    }
    final needsQuotes =
        text.contains(',') ||
        text.contains('"') ||
        text.contains('\n') ||
        text.contains('\r') ||
        text != text.trim();
    if (!needsQuotes) return text;
    return '"${text.replaceAll('"', '""')}"';
  }
}
