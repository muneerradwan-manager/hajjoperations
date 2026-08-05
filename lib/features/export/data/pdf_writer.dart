import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/export_dataset.dart';
import 'export_values.dart';

/// Turns a table into a printable document that reads right to left.
///
/// The font is the whole difficulty, and it is worth stating why there is a
/// second copy of it in `assets/fonts/pdf/`.
///
/// The app's own itfQomra ships as `OTTO` — OpenType with CFF outlines. Flutter
/// renders that happily; the `pdf` package cannot embed it at all, because a
/// PDF font is built out of the `glyf` and `loca` tables that a CFF file does
/// not have. So the same typeface is kept a second time with its curves
/// converted to the quadratic form TrueType uses. It is the same design to
/// well inside a printed dot; it is not a different font, and the exported
/// sheet is in the app's own hand.
///
/// Shaping and ordering are the package's, not ours: given a right-to-left
/// [pw.Directionality] and a font carrying the Arabic presentation forms, it
/// joins the letters and lays the line out itself. What we owe it is a font
/// that HAS those forms — which `test/pdf_font_test.dart` is there to keep
/// true, because the failure mode is a page of blank boxes rather than an
/// error.
class PdfWriter {
  const PdfWriter._();

  static pw.Font? _regular;
  static pw.Font? _bold;

  /// Loaded once. A font is a megabyte of parsed tables and an export screen
  /// can be used several times in a sitting.
  static Future<void> _loadFonts() async {
    if (_regular != null) return;
    _regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/pdf/itfQomraArabic-Regular.ttf'),
    );
    _bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/pdf/itfQomraArabic-Bold.ttf'),
    );
  }

  /// A theme that can draw Arabic, for any other page this app prints.
  ///
  /// Shared rather than copied. The conversion in `assets/fonts/pdf/` is the
  /// only reason ANY document here can render Arabic at all, and a second
  /// screen that quietly used the package's default font would print a page of
  /// empty boxes — which looks like a bug in the content rather than a missing
  /// font, and is how somebody ends up "fixing" the wrong thing.
  static Future<pw.ThemeData> arabicTheme() async {
    await _loadFonts();
    return pw.ThemeData.withFont(base: _regular!, bold: _bold!);
  }

  static Future<Uint8List> write(
    ExportTable table, {
    required String subtitle,
    required String pageLabel,
  }) async {
    await _loadFonts();

    final theme = pw.ThemeData.withFont(base: _regular!, bold: _bold!);
    final document = pw.Document(theme: theme);

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          // Landscape, because these are wide things: a roster with a name, a
          // trade, two telephone numbers and an email does not fit a portrait
          // page without becoming unreadable, and an unreadable sheet is the
          // same as no sheet.
          pageFormat: PdfPageFormat.a4.landscape.copyWith(
            marginLeft: 24,
            marginRight: 24,
            marginTop: 28,
            marginBottom: 28,
          ),
          theme: theme,
          textDirection: pw.TextDirection.rtl,
        ),
        header: (context) => _header(table.title, subtitle, context),
        footer: (context) => _footer(context, pageLabel),
        build: (context) => [
          if (table.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 40),
              child: pw.Text(
                subtitle,
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: table.headers,
              data: table.rows,
              border: pw.TableBorder.all(color: PdfColors.grey400, width: .4),
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF016D5D),
              ),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              // Alternating rows: forty names in one block is a block a reader
              // loses his line in.
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF3F6F5),
              ),
              cellAlignment: pw.Alignment.centerRight,
              headerAlignment: pw.Alignment.centerRight,
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
              headerPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 5,
              ),
            ),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _header(String title, String subtitle, pw.Context context) {
    // Only on the first page. Repeating a title above every page of a
    // forty-page roster wastes the line that the columns need.
    if (context.pageNumber > 1) return pw.SizedBox();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            subtitle,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 6),
          pw.Divider(height: 1, color: PdfColors.grey400),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context context, String pageLabel) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 6),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          ExportValues.moment(DateTime.now()),
          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
        ),
        pw.Text(
          '$pageLabel ${context.pageNumber} / ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
        ),
      ],
    ),
  );
}
