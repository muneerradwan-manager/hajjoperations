/// Folding Arabic text so that searching finds what the reader meant.
///
/// The same name is written several ways and all of them are correct. The
/// mission's own decisions do it constantly — أحمد and احمد, نقاوة and نقاوه,
/// مصطفى and مصطفي — and a directory that answers "no results" to a hamza is
/// wrong about a name that is sitting in the list.
///
/// So a search compares FOLDED text on both sides:
///
///   أ إ آ ٱ ا  ->  ا      hamza on a seat, or none, is the same letter
///   ة          ->  ه      final taa marbuta is heard as ha
///   ى          ->  ي      alif maqsura is written both ways
///   ؤ ئ        ->  و ي    the seat is spelling, not sound
///   tashkeel   ->  dropped
///   ـ (tatweel)->  dropped
///   ٠١٢…       ->  0 1 2  Arabic-Indic digits match ASCII ones
///
/// Latin text is lowercased by the same call, so one function serves a list
/// that holds both.
library;

const _fold = <int, String>{
  0x0623: 'ا', 0x0625: 'ا', 0x0622: 'ا', 0x0671: 'ا', // أ إ آ ٱ
  0x0629: 'ه', // ة
  0x0649: 'ي', // ى
  0x0624: 'و', // ؤ
  0x0626: 'ي', // ئ
};

/// Harakat, tanween, shadda, sukun and the superscript alef — never typed in a
/// search box, and never worth failing a match over.
bool _isMark(int c) =>
    (c >= 0x064B && c <= 0x065F) || c == 0x0670 || (c >= 0x06D6 && c <= 0x06ED);

/// Tatweel: a stretching glyph with no sound at all.
const _tatweel = 0x0640;

/// Arabic-Indic (٠-٩) and Eastern Arabic-Indic (۰-۹) digits.
String? _digit(int c) {
  if (c >= 0x0660 && c <= 0x0669) return String.fromCharCode(c - 0x0660 + 0x30);
  if (c >= 0x06F0 && c <= 0x06F9) return String.fromCharCode(c - 0x06F0 + 0x30);
  return null;
}

/// The comparable form of [input] — fold it on both sides of a search.
String foldArabic(String? input) {
  if (input == null || input.isEmpty) return '';
  final out = StringBuffer();
  for (final rune in input.runes) {
    if (_isMark(rune) || rune == _tatweel) continue;
    final folded = _fold[rune];
    if (folded != null) {
      out.write(folded);
      continue;
    }
    final digit = _digit(rune);
    if (digit != null) {
      out.write(digit);
      continue;
    }
    out.writeCharCode(rune);
  }
  return out.toString().toLowerCase();
}

/// Whether [haystack] contains [needle], both folded.
bool arabicContains(String? haystack, String foldedNeedle) =>
    foldedNeedle.isEmpty || foldArabic(haystack).contains(foldedNeedle);

/// Whether every word of the query appears somewhere in [fields].
///
/// Word by word rather than as one string, so "أحمد الحداد" finds the man whose
/// record reads "أحمد فتحي الحداد" — a searcher types the parts of a name they
/// remember, not the full form as filed. Each word must land somewhere, which
/// keeps the match from widening to everyone who shares one of them.
bool arabicMatchesAll(Iterable<String?> fields, String query) {
  final words = foldArabic(query).split(RegExp(r'\s+'))
    ..removeWhere((w) => w.isEmpty);
  if (words.isEmpty) return true;
  final folded = fields.map(foldArabic).where((f) => f.isNotEmpty).toList();
  return words.every((w) => folded.any((f) => f.contains(w)));
}
