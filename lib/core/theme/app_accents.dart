import 'package:flutter/material.dart';

import 'app_colors.dart';

/// A brand colour made legible on the surface it is drawn on.
///
/// The nine colours in [AppColors] are a print palette, and they do not divide
/// evenly across a screen that has both a night and a paper mode. Measured
/// against the two backdrops this app actually uses:
///
/// ```
///                 on night   on paper
///   darkGreen        2.26      7.47
///   mediumGreen      2.98      5.68
///   lightGreen       5.69      2.97
///   darkRed          1.12     15.13
///   mediumRed        1.67     10.09
///   lightRed         1.91      8.84
///   darkGold         7.02      2.41
///   mediumGold      11.30      1.50
///   lightGold       13.86      1.22
/// ```
///
/// Every RED is unusable on the dark backdrop and every GOLD is unusable on the
/// light one. Only the greens half-work on both — which is why the app drifted
/// into using green for nearly everything, and why the two screens that were
/// not green had a card nobody could read.
///
/// So an accent is a PAIR: the brand colour on the backdrop it already suits,
/// and the same hue mixed toward white or black for the one it does not. Each
/// pair below clears 4.5:1 on its own backdrop, and the mix is the least that
/// gets there. No new hue is introduced — which is the one rule [AppColors]
/// sets, and the same licence its own surface and ink tones are built on.
class Accent {
  const Accent._(this.onLight, this.onDark, {required this.brand});

  /// For a surface of paper.
  final Color onLight;

  /// For a surface of night.
  final Color onDark;

  /// The brand colour this pair is made of, for anything that wants the print
  /// value rather than the legible one.
  final Color brand;

  Color of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? onDark : onLight;

  // ── The mission's own work and people: green ────────────────────────────
  /// [AppColors.lightGreen], darkened 22% on paper.
  static const green = Accent._(
    Color(0xFF1F7B72),
    AppColors.lightGreen,
    brand: AppColors.lightGreen,
  );

  /// [AppColors.mediumGreen], lightened 20% on night.
  static const greenDeep = Accent._(
    AppColors.mediumGreen,
    Color(0xFF348A7D),
    brand: AppColors.mediumGreen,
  );

  /// [AppColors.darkGreen], lightened 29% on night.
  static const greenDark = Accent._(
    AppColors.darkGreen,
    Color(0xFF4A8982),
    brand: AppColors.darkGreen,
  );

  // ── The calendar and the reference material: gold ───────────────────────
  /// [AppColors.darkGold], darkened 30% on paper.
  static const gold = Accent._(
    Color(0xFF796F4D),
    AppColors.darkGold,
    brand: AppColors.darkGold,
  );

  /// [AppColors.mediumGold], darkened 45% on paper — the palest brand colour
  /// there is, and the one that needs the most help on a white page.
  static const goldSoft = Accent._(
    Color(0xFF776E57),
    AppColors.mediumGold,
    brand: AppColors.mediumGold,
  );

  // ── The decisions made about people: red ────────────────────────────────
  /// [AppColors.lightRed], lightened 33% on night.
  static const red = Accent._(
    AppColors.lightRed,
    Color(0xFFA66E75),
    brand: AppColors.lightRed,
  );

  /// [AppColors.mediumRed], lightened 36% on night.
  static const redDeep = Accent._(
    AppColors.mediumRed,
    Color(0xFF9E7189),
    brand: AppColors.mediumRed,
  );
}
