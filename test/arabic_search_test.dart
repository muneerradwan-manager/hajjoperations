import 'package:flutter_test/flutter_test.dart';
import 'package:hajjoperations/core/utils/arabic_search.dart';

/// The directory has to find a name however it was spelled.
///
/// The mission's own decisions spell the same man both ways in the same week —
/// 'أحمد' and 'احمد', 'نقاوة' and 'نقاوه' — so a search that treats those as
/// different words hides records that are sitting in the list.
void main() {
  group('foldArabic', () {
    test('hamza on a seat folds to bare alif', () {
      expect(foldArabic('أحمد'), foldArabic('احمد'));
      expect(foldArabic('إبراهيم'), foldArabic('ابراهيم'));
      expect(foldArabic('آمنة'), foldArabic('امنه'));
    });

    test('taa marbuta folds to haa', () {
      expect(foldArabic('نقاوة'), foldArabic('نقاوه'));
      expect(foldArabic('حليمة'), foldArabic('حليمه'));
    });

    test('alif maqsura folds to yaa', () {
      expect(foldArabic('مصطفى'), foldArabic('مصطفي'));
      expect(foldArabic('ذكرى'), foldArabic('ذكري'));
    });

    test('harakat and tatweel are ignored', () {
      expect(foldArabic('مُحَمَّد'), foldArabic('محمد'));
      expect(foldArabic('محـــمد'), foldArabic('محمد'));
    });

    test('hamza seats on waw and yaa fold to their letters', () {
      expect(foldArabic('مؤتمن'), foldArabic('موتمن'));
      expect(foldArabic('سائر'), foldArabic('ساير'));
    });

    test('Arabic-Indic digits match ASCII ones', () {
      expect(foldArabic('مخيم ١٦'), foldArabic('مخيم 16'));
    });

    test('latin is lowercased, so one call serves a mixed list', () {
      expect(foldArabic('Ahmad'), foldArabic('ahmad'));
    });
  });

  group('arabicMatchesAll', () {
    const fields = ['أحمد', 'فتحي', 'الحدّاد', 'أحمد فتحي الحدّاد'];

    test('finds a man by his first name alone', () {
      expect(arabicMatchesAll(fields, 'احمد'), isTrue);
    });

    test('finds him by his FATHER name alone', () {
      expect(arabicMatchesAll(fields, 'فتحي'), isTrue);
    });

    test('finds him by his surname alone', () {
      expect(arabicMatchesAll(fields, 'الحداد'), isTrue);
    });

    test('finds him by first + surname, skipping the father name', () {
      expect(arabicMatchesAll(fields, 'أحمد الحداد'), isTrue);
    });

    test('word order does not matter', () {
      expect(arabicMatchesAll(fields, 'الحداد احمد'), isTrue);
    });

    test('every word must land somewhere', () {
      expect(arabicMatchesAll(fields, 'احمد سرميني'), isFalse);
    });

    test('an empty query matches everyone', () {
      expect(arabicMatchesAll(fields, '   '), isTrue);
    });

    test('null fields are skipped rather than matched', () {
      expect(arabicMatchesAll([null, 'أحمد'], 'احمد'), isTrue);
      expect(arabicMatchesAll([null, null], 'احمد'), isFalse);
    });

    test('spelling differences on BOTH sides fold together', () {
      // The record is filed one way and searched the other.
      expect(arabicMatchesAll(['حسن نقاوه'], 'نقاوة'), isTrue);
      expect(arabicMatchesAll(['حسن نقاوة'], 'نقاوه'), isTrue);
    });
  });
}
