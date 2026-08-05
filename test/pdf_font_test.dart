import 'dart:io';
import 'dart:typed_data';

import 'package:bidi/bidi.dart' as bidi;
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

/// The exported PDF is in the app's own typeface, and getting it there took a
/// conversion this test exists to police.
///
/// itfQomra ships as `OTTO` — OpenType with CFF outlines. Flutter renders that
/// happily; the `pdf` package cannot embed it at all, because a PDF font is
/// built from the `glyf` and `loca` tables a CFF file does not have. So a
/// second copy lives in `assets/fonts/pdf/` with its curves converted.
///
/// Two things can go wrong with that copy, and NEITHER RAISES AN ERROR. A file
/// without `glyf` is refused; a file whose Arabic is incomplete produces a
/// document full of blank boxes and saves without complaint. Somebody finds out
/// when the sheet is already with the leadership.
///
/// So the coverage is asserted here, against the same shaping the `pdf` package
/// performs at render time: it takes the Arabic, has `bidi` join and reorder it
/// into presentation forms, and looks each resulting character up in the font.
void main() {
  late TtfParser regular;
  late TtfParser bold;

  setUpAll(() {
    ByteData load(String path) {
      final file = File(path);
      expect(
        file.existsSync(),
        isTrue,
        reason: '$path is missing — the PDF export has no font to draw with',
      );
      return ByteData.sublistView(file.readAsBytesSync());
    }

    regular = TtfParser(load('assets/fonts/pdf/itfQomraArabic-Regular.ttf'));
    bold = TtfParser(load('assets/fonts/pdf/itfQomraArabic-Bold.ttf'));
  });

  /// Text as it actually appears in this app's exports.
  const samples = <String, String>{
    'a full Arabic name': 'منير عبدالله رضوان',
    'a column heading': 'البريد الإلكتروني',
    'a place': 'مخيم منى — القطاع السابع',
    'a duty note': 'الغرف ٤٠١ و٤٠٢ مغلقة',
    'a state': 'قيد التنفيذ',
    'the lam-alef ligature': 'لا إله إلا الله',
    'taa marbuta and hamza': 'المدينة المنوّرة، مسؤول الرحلة',
    'a season': 'الموسم ١٤٤٧هـ',
    'mixed with Latin and digits': 'Hotel 12 — فندق الأنصار',
    'Arabic-Indic digits': '٠١٢٣٤٥٦٧٨٩',
    'Western digits': '0123456789',
  };

  for (final entry in samples.entries) {
    test('the regular face can draw ${entry.key}', () {
      final missing = _missingFrom(regular, entry.value);

      expect(
        missing,
        isEmpty,
        reason:
            'these would be drawn as blank boxes in every exported PDF, and '
            'nothing would report an error: '
            '${missing.map((c) => '${String.fromCharCode(c)} (U+${c.toRadixString(16).toUpperCase()})').join(', ')}',
      );
    });
  }

  test('the bold face can draw the headings', () {
    // Only the headings are bold, but a heading is where the column names are
    // and they are the part of the sheet a reader must be able to read.
    final missing = <int>{
      for (final sample in samples.values) ..._missingFrom(bold, sample),
    };

    expect(missing, isEmpty);
  });

  test('both faces are TrueType — a CFF file cannot be embedded at all', () {
    // TtfParser reaching this point already proves it, since it reads `glyf`.
    // Stated anyway: this is the mistake that would be made by copying the
    // OTF back over the TTF, and it is not obvious that it is a mistake.
    expect(regular.charToGlyphIndexMap, isNotEmpty);
    expect(bold.charToGlyphIndexMap, isNotEmpty);
  });

  test('the two faces agree on what they can draw', () {
    // A bold face missing a letter the regular one has gives a sheet whose
    // headings are broken and whose body is fine, which reads as a layout bug
    // rather than as a font one.
    final regularOnly = regular.charToGlyphIndexMap.keys
        .where((c) => !bold.charToGlyphIndexMap.containsKey(c))
        .toList();

    expect(regularOnly, isEmpty);
  });
}

/// The characters of [text] that the font has no glyph for, AFTER the shaping
/// and reordering the `pdf` package applies to right-to-left text.
///
/// Shaping is the point. `م` on its own is U+0645, but joined in the middle of
/// a word it is drawn from a different glyph in the presentation-forms block,
/// and a font carrying the first without the second renders correct-looking
/// isolated letters and blanks for everything joined.
Set<int> _missingFrom(TtfParser font, String text) {
  final visual = bidi.logicalToVisual(text);
  return {
    for (final code in visual)
      if (!font.charToGlyphIndexMap.containsKey(code) && !_ignorable(code)) code,
  };
}

/// Characters no font needs a mark for.
bool _ignorable(int code) =>
    code == 0x20 || // space
    code == 0x200B || // zero-width space
    code == 0x200C || // zero-width non-joiner
    code == 0x200D || // zero-width joiner
    (code >= 0x202A && code <= 0x202E); // bidi embedding controls
