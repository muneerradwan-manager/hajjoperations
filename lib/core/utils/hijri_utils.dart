import 'package:hijri/hijri_calendar.dart';

/// Helpers for deriving the current Hijri (Umm al-Qura) year.
class HijriUtils {
  const HijriUtils._();

  /// Current Hijri year, e.g. 1447.
  static int currentYear() => HijriCalendar.now().hYear;

  /// The Gregorian span the *current Hijri year* falls in, e.g. "2025/2026".
  ///
  /// Derived from the Hijri year's own first and last day, not from today's
  /// Gregorian year: between 1 January and the Hijri new year the running Hijri
  /// year began in the *previous* Gregorian year, so `now.year/now.year + 1`
  /// was off by one for roughly half of every year — and the wrong label was
  /// being written onto season rows.
  static String currentGregorianLabel() =>
      gregorianLabelFor(HijriCalendar.now().hYear);

  /// The Gregorian span of any Hijri year, e.g. 1447 → "2025/2026".
  static String gregorianLabelFor(int hijriYear) {
    final calendar = HijriCalendar();
    final start = calendar.hijriToGregorian(hijriYear, 1, 1);
    // Length varies (29/30 Dhu al-Hijjah); the year of day 1 of the *next*
    // Hijri year minus a day is exact without knowing the month's length.
    final end = calendar
        .hijriToGregorian(hijriYear + 1, 1, 1)
        .subtract(const Duration(days: 1));
    return start.year == end.year
        ? '${start.year}'
        : '${start.year}/${end.year}';
  }
}
