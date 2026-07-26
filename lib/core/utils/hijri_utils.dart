import 'package:hijri/hijri_calendar.dart';

/// Helpers for deriving the current Hijri (Umm al-Qura) year.
class HijriUtils {
  const HijriUtils._();

  /// Current Hijri year, e.g. 1447.
  static int currentYear() => HijriCalendar.now().hYear;

  /// A short label combining the Hijri year with the Gregorian span it falls
  /// in, e.g. "1447 (2025/2026)".
  static String currentGregorianLabel() {
    final now = DateTime.now();
    return '${now.year}/${now.year + 1}';
  }
}
