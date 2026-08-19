import 'dart:math' as math;
import 'dart:typed_data';

import 'package:bidi/bidi.dart' as bidi;
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
/// That copy is also PATCHED, by `tool/fill_pdf_font_ligatures.py`, and this is
/// the part to remember when it is ever rebuilt. The typeface declares the
/// eight lam-alef presentation forms and draws none of them: on screen nothing
/// ever asks — HarfBuzz joins lam and alef through the font's own init/fina
/// forms — and this package asks for nothing else. The script fills them in
/// from those same two forms. Without it every «لا», «الإلكتروني» and
/// «الميلاد» in an exported sheet prints with a Latin letter in the middle of
/// it, because an empty glyph is read from the offset of the one stored after
/// it. `test/pdf_font_test.dart` fails if the patch is ever lost.
///
/// Shaping and ordering are the package's, not ours: given a right-to-left
/// [pw.Directionality] and a font carrying the Arabic presentation forms, it
/// joins the letters and lays the line out itself. What we owe it is a font
/// that HAS those forms, and columns wide enough that it never has to break a
/// word — see [_columnWidths], because its shaper runs once, before the line
/// breaker, and a word cut afterwards comes out backwards.
class PdfWriter {
  const PdfWriter._();

  static pw.Font? _regular;
  static pw.Font? _bold;
  static ByteData? _regularBytes;
  static ByteData? _boldBytes;

  /// Loaded once. A font is a megabyte of parsed tables and an export screen
  /// can be used several times in a sitting.
  ///
  /// The bytes are kept beside the built fonts because the column measuring in
  /// [_columnWidths] needs a [PdfFont] of its own — a `pw.Font` only becomes
  /// one inside a build, and the page's width has to be settled before there is
  /// a page to build.
  static Future<void> _loadFonts() async {
    if (_regular != null) return;
    _regularBytes = await rootBundle.load(
      'assets/fonts/pdf/itfQomraArabic-Regular.ttf',
    );
    _boldBytes = await rootBundle.load(
      'assets/fonts/pdf/itfQomraArabic-Bold.ttf',
    );
    _regular = pw.Font.ttf(_regularBytes!);
    _bold = pw.Font.ttf(_boldBytes!);
  }

  static const _headerSize = 9.0;
  static const _cellSize = 8.5;

  /// The horizontal padding inside a cell, on each side, plus the rule.
  static const _cellInset = 4.0 * 2 + 1;

  /// A column never narrower than this, however short its contents — a column
  /// of «ذكر» still needs a heading over it.
  static const _minColumn = 34.0;

  /// …and never wider. The cap is what a long unbroken Latin run — an address,
  /// a UUID — is allowed to claim before it is left to wrap. Those break
  /// mid-token and read perfectly well; the Arabic words this whole measurement
  /// exists for are far below it.
  static const _maxColumn = 150.0;

  /// How much of the table is measured. Every row of a four-thousand-name
  /// roster would be forty thousand string measurements for an answer the first
  /// few hundred already give: a column's widest word is a property of the KIND
  /// of thing in it, not of how many there are.
  static const _rowsSampled = 300;

  /// Where the sheet stops growing sideways. Past this the columns are left to
  /// wrap rather than the page becoming a scroll nothing can print.
  static const _maxPageWidth = 2400.0;

  static final _whitespace = RegExp(r'\s+');

  /// What each column needs to never break a word in half.
  ///
  /// This is the measurement that keeps the sheet readable, and it is worth
  /// saying exactly what goes wrong without it. The `pdf` package lays Arabic
  /// out by converting it to the Unicode presentation forms and REVERSING it,
  /// once, before the line breaker ever sees it. So when a word will not fit
  /// its column the breaker cuts a string it no longer understands: «المدينة»
  /// in a 44-point column came out as «دينة» on the first line and «الم» on the
  /// second — the two halves in the wrong order, and neither of them a word.
  /// Latin survives the same treatment, which is why an over-narrow column
  /// looks like a layout choice in English and like corruption in Arabic.
  ///
  /// A break at a SPACE is fine — «البعثة الإدارية» stacks in the right order —
  /// so the fix is not to stop wrapping. It is to make sure no single word ever
  /// has to be broken, which means measuring the widest word in each column and
  /// letting the page grow to hold them.
  ///
  /// Measured against the shaped text rather than the stored text: an Arabic
  /// letter is a different glyph, of a different width, joined than it is
  /// alone, and measuring «م» to lay out «ـمـ» is measuring the wrong thing.
  static List<double>? _columnWidths(ExportTable table) {
    if (_regularBytes == null || _boldBytes == null) return null;
    try {
      // A document that is never saved, existing only to give the two fonts
      // somewhere to be parsed into so their metrics can be read.
      final probe = PdfDocument();
      final regular = PdfTtfFont(probe, _regularBytes!);
      final bold = PdfTtfFont(probe, _boldBytes!);

      final sampled = math.min(table.rows.length, _rowsSampled);
      return [
        for (var c = 0; c < table.headers.length; c++)
          () {
            var need = _widestWord(bold, table.headers[c], _headerSize);
            for (var r = 0; r < sampled; r++) {
              final row = table.rows[r];
              if (c >= row.length) continue;
              final width = _widestWord(regular, row[c], _cellSize);
              if (width > need) need = width;
            }
            return (need + _cellInset).clamp(_minColumn, _maxColumn);
          }(),
      ];
    } catch (_) {
      // A sheet laid out by the package's own guess is worth having; no sheet
      // at all because a measurement threw is not.
      return null;
    }
  }

  /// The same table with its columns turned round, so that the first one lands
  /// on the right.
  ///
  /// [pw.Table] has no notion of direction at all — it lays its cells out left
  /// to right whatever the page around them is doing, and the `tableDirection`
  /// the helper offers reaches only the TEXT inside each cell. So a sheet whose
  /// every word read right to left had its COLUMNS running the other way: the
  /// employees dataset begins with «الاسم الكامل» and ends with «المعرّف», and
  /// an Arabic reader opening the sheet met the identifier first and had to
  /// travel the width of the page to reach the name.
  ///
  /// Reversed here rather than in the catalogue, because the catalogue's order
  /// is not wrong — the CSV, which is opened in a spreadsheet that handles
  /// right-to-left itself, wants exactly the order it has. This is the PDF's
  /// own business.
  ///
  /// A row shorter than the headers is padded before it is turned, never after:
  /// reversing a short row would slide every value in it one column across, and
  /// a name under the heading «المهنة» on an official sheet is worse than a
  /// blank cell by a long way.
  static ExportTable _rightToLeft(ExportTable table) {
    final columns = table.headers.length;
    return ExportTable(
      title: table.title,
      headers: table.headers.reversed.toList(),
      rows: [
        for (final row in table.rows)
          [for (var i = columns - 1; i >= 0; i--) i < row.length ? row[i] : ''],
      ],
    );
  }

  /// The width of the longest single word in [text], drawn at [size].
  static double _widestWord(PdfFont font, String text, double size) {
    var widest = 0.0;
    for (final word in text.split(_whitespace)) {
      if (word.isEmpty) continue;
      final shaped = String.fromCharCodes(bidi.logicalToVisual(word));
      final width = font.stringMetrics(shaped).width * size;
      if (width > widest) widest = width;
    }
    return widest;
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

  /// The letterhead, in both languages at once.
  ///
  /// Not in the ARB, and deliberately. Everything else on this sheet is written
  /// in the reader's language; this is not addressed to the reader at all. It is
  /// the issuing body naming itself, and an official paper names itself the same
  /// way on every copy — the Arabic side stays Arabic when the app is in
  /// English, and the English side stays English when it is in Arabic, because
  /// the sheet leaves the app and is read by people who never opened it.
  ///
  /// The first line of each side is the state, the second the ministry, the
  /// third this directorate — largest to smallest, the way a seal is read.
  static const _letterheadAr = [
    'الجمهورية العربية السورية',
    'وزارة الأوقاف',
    'إدارة الحـج والعمـرة',
  ];

  static const _letterheadEn = [
    'Syrian Arab Republic',
    'Ministry of Religious Affairs',
    'Directorate of Hajj and Umrah',
  ];

  static pw.MemoryImage? _logo;

  /// Loaded beside the fonts and forgiven if it is not there.
  ///
  /// A missing mark costs the sheet its emblem; it must not cost it the sheet.
  /// The two name blocks stand on their own and the header simply closes over
  /// the gap.
  static Future<void> _loadLogo() async {
    if (_logo != null) return;
    try {
      final data = await rootBundle.load('assets/images/sduh_logo.png');
      _logo = pw.MemoryImage(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } catch (_) {
      _logo = null;
    }
  }

  static Future<Uint8List> write(
    ExportDocument doc, {
    required String subtitle,
    required String pageLabel,
  }) async {
    await _loadFonts();
    await _loadLogo();

    final theme = pw.ThemeData.withFont(base: _regular!, bold: _bold!);
    final document = pw.Document(theme: theme);

    final sheets = [for (final section in doc.sections) _rightToLeft(section)];
    final many = sheets.length > 1;

    // Landscape, because these are wide things: a roster with a name, a trade,
    // two telephone numbers and an email does not fit a portrait page without
    // becoming unreadable, and an unreadable sheet is the same as no sheet.
    //
    // And wider than landscape when the columns ask for it. A4 was a fixed
    // ceiling before, so an eighteen-column roster divided 794 points between
    // eighteen headings and gave each of them forty-four — narrower than the
    // word «المدينة», which was then cut in half and stacked backwards. See
    // [_columnWidths]. The paper grows instead: the common export of five or
    // six columns is exactly the A4 landscape it always was, and the wide one
    // becomes a wide sheet rather than a broken one.
    const margin = 24.0;
    final widths = [for (final sheet in sheets) _columnWidths(sheet)];
    // The widest section decides the paper. Sections on different-sized pages
    // would be a document that changes shape halfway down, and the narrow ones
    // simply share out the spare width in their own ratios.
    var wanted = 0.0;
    for (final width in widths) {
      if (width == null) continue;
      final total = width.fold(0.0, (sum, w) => sum + w) + margin * 2;
      if (total > wanted) wanted = total;
    }
    final pageWidth = math.max(
      PdfPageFormat.a4.landscape.width,
      math.min(wanted, _maxPageWidth),
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat(
            pageWidth,
            PdfPageFormat.a4.landscape.height,
            marginLeft: margin,
            marginRight: margin,
            marginTop: 28,
            marginBottom: 28,
          ),
          theme: theme,
          textDirection: pw.TextDirection.rtl,
        ),
        header: (context) => _header(doc.title, subtitle, context),
        footer: (context) => _footer(context, pageLabel),
        build: (context) => [
          if (doc.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 40),
              child: pw.Text(
                subtitle,
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          for (var i = 0; i < sheets.length; i++)
            if (!sheets[i].isEmpty) ...[
              // Named only when there is more than one. A single section is
              // already named by the title at the head of the page, and
              // printing it a second time immediately under itself is the
              // sheet stuttering.
              if (many) ...[
                if (i > 0) pw.SizedBox(height: 14),
                pw.Text(
                  sheets[i].title,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF00594F),
                  ),
                ),
                if (sheets[i].note case final note? when note.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      note,
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                pw.SizedBox(height: 5),
              ],
              pw.TableHelper.fromTextArray(
                headers: sheets[i].headers,
                data: sheets[i].rows,
                // Proportional to what each column needs rather than fixed at it,
                // so the row still fills the sheet: where the page was widened to
                // the measured total every column lands on its own figure, and
                // where it was held at the A4 floor — a narrow export, three
                // columns — the spare width is shared out in the same ratio
                // instead of leaving a third of the paper blank.
                columnWidths: widths[i] == null
                    ? null
                    : {
                        for (var c = 0; c < widths[i]!.length; c++)
                          c: pw.FlexColumnWidth(widths[i]![c]),
                      },
                border: pw.TableBorder.all(color: PdfColors.grey400, width: .4),
                headerStyle: pw.TextStyle(
                  fontSize: _headerSize,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF016D5D),
                ),
                cellStyle: const pw.TextStyle(fontSize: _cellSize),
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
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _header(String title, String subtitle, pw.Context context) {
    // Only on the first page. Repeating a letterhead and a title above every
    // page of a forty-page roster wastes the lines that the columns need — and
    // the footer already carries the page number and the moment, which is what
    // a loose sheet from the middle of the file needs to be placed.
    if (context.pageNumber > 1) return pw.SizedBox();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _letterhead(),
          pw.SizedBox(height: 8),
          pw.Divider(height: 1, color: PdfColors.grey400),
          pw.SizedBox(height: 8),
          // The title and what made it, on one line: the sheet's own name at
          // the start of it and the provenance trailing off at the far end,
          // which is where an eye reading the table below is not looking.
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Expanded(
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                subtitle,
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(height: 1, color: PdfColors.grey400),
        ],
      ),
    );
  }

  /// Who issued this sheet: the state in Arabic on one side, in English on the
  /// other, and the emblem between them.
  ///
  /// The Arabic block is FIRST in the row and therefore on the right, without
  /// anybody naming a side — the page is laid out right to left, so the first
  /// child is the one the reader meets first. The English block carries a
  /// left-to-right [pw.Directionality] of its own, which is what makes it stack
  /// against the left edge and stops «Ministry of Religious Affairs» from being
  /// reordered by a paragraph direction it does not belong to.
  ///
  /// Both blocks are [pw.Expanded] and equal, so the emblem between them sits
  /// on the centre line of the page rather than wherever the longer name leaves
  /// it — which is the difference between a letterhead and a row of three
  /// things.
  static pw.Widget _letterhead() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _names(_letterheadAr, pw.TextDirection.rtl)),
        if (_logo case final logo?)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12),
            child: pw.Image(logo, height: 48),
          ),
        pw.Expanded(child: _names(_letterheadEn, pw.TextDirection.ltr)),
      ],
    );
  }

  /// One side of the letterhead: three lines, the first of them the state's own
  /// name and set heaviest, the two under it stepping down to this directorate.
  static pw.Widget _names(List<String> lines, pw.TextDirection direction) {
    return pw.Directionality(
      textDirection: direction,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) pw.SizedBox(height: 2),
            pw.Text(
              lines[i],
              style: pw.TextStyle(
                fontSize: i == 0 ? 10 : 9,
                fontWeight: i == 0 ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: i == 0 ? PdfColors.black : PdfColors.grey800,
              ),
            ),
          ],
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
