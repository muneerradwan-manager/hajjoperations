import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// A character the PDF font cannot draw does not fail. It is silently not
/// there.
///
/// The export joined a posting's place with an arrow — «القطاع الخامس ← بركة
/// اليقين» — and itfQomraArabic, which the sheets are set in, maps three
/// hundred codepoints and has no U+2190 among them. So the separator rendered
/// as nothing, and the two names arrived run together with no sign that one
/// contained the other. Nothing threw, nothing logged, and the file looked
/// finished.
///
/// This is the only kind of check that catches that class of fault before a
/// person is holding the paper: the font is an asset in this repository, its
/// coverage can be read, and every symbol the exporter puts between words is
/// known here.
const _font = 'assets/fonts/pdf/itfQomraArabic-Regular.ttf';

/// Every codepoint the font's `cmap` maps.
Set<int> _mapped(String path) {
  final d = ByteData.sublistView(
    Uint8List.fromList(File(path).readAsBytesSync()),
  );

  int? cmapAt;
  final tables = d.getUint16(4);
  for (var i = 0; i < tables; i++) {
    final rec = 12 + 16 * i;
    final tag = String.fromCharCodes([
      for (var b = 0; b < 4; b++) d.getUint8(rec + b),
    ]);
    if (tag == 'cmap') cmapAt = d.getUint32(rec + 8);
  }
  expect(cmapAt, isNotNull, reason: 'the font has no cmap table');

  int? sub;
  final encodings = d.getUint16(cmapAt! + 2);
  for (var i = 0; i < encodings; i++) {
    final p = cmapAt + 4 + 8 * i;
    final platform = d.getUint16(p);
    final encoding = d.getUint16(p + 2);
    final unicode =
        (platform == 3 && (encoding == 1 || encoding == 10)) || (platform == 0);
    if (unicode) sub = cmapAt + d.getUint32(p + 4);
  }
  expect(sub, isNotNull, reason: 'the font has no Unicode cmap subtable');
  expect(d.getUint16(sub!), 4, reason: 'only format 4 is read here');

  final segX2 = d.getUint16(sub + 6);
  final segments = segX2 ~/ 2;
  final out = <int>{};
  for (var i = 0; i < segments; i++) {
    final end = d.getUint16(sub + 14 + 2 * i);
    final start = d.getUint16(sub + 16 + segX2 + 2 * i);
    if (start == 0xFFFF) continue;
    for (var c = start; c <= end && c < 0xFFFF; c++) {
      out.add(c);
    }
  }
  return out;
}

void main() {
  late Set<int> covered;

  setUpAll(() => covered = _mapped(_font));

  /// Every non-ASCII character the export catalogue writes BETWEEN values —
  /// separators, joins and placeholders. Add to this list whenever one is
  /// introduced; the point is that the list and the font are checked against
  /// each other rather than against nobody.
  const separators = <String, String>{
    '—':
        'the place separator: القطاع — البرج, and the fallback for a file '
        'whose name was not stored',
    '،': 'the join between two posts one person holds',
  };

  test('the font can draw every separator the export puts on a page', () {
    for (final entry in separators.entries) {
      final rune = entry.key.runes.single;
      expect(
        covered,
        contains(rune),
        reason:
            'U+${rune.toRadixString(16).toUpperCase().padLeft(4, '0')} '
            '"${entry.key}" — ${entry.value} — is not in $_font, so it will '
            'be drawn as nothing and the values either side of it will run '
            'together',
      );
    }
  });

  test('and the arrow it must never go back to is confirmed absent', () {
    // Kept as a test rather than as a comment: if a later version of this font
    // gains the arrow, this fails and whoever is reading knows the ban can be
    // lifted. Until then it is the evidence for why the em dash is there.
    expect(
      covered,
      isNot(contains(0x2190)),
      reason: 'if the font now has U+2190 this ban can be reconsidered',
    );
  });

  test('the Arabic the sheets are actually made of is covered', () {
    // A guard on the guard: a font file swapped for one with no Arabic at all
    // would pass the checks above, since both separators are punctuation.
    for (final letter in 'أبتثجحخدذرزسشصضطظعغفقكلمنهوي'.runes) {
      expect(covered, contains(letter));
    }
  });
}
