import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Design tokens for the frosted-glass surface language.
///
/// Every glass surface in the app derives its fill, hairline stroke, sheen and
/// shadow from here so that light/dark stay coherent and a single edit
/// re-tunes the whole system.
@immutable
class GlassTokens extends ThemeExtension<GlassTokens> {
  const GlassTokens({
    required this.fill,
    required this.fillStrong,
    required this.fillSubtle,
    required this.sheen,
    required this.stroke,
    required this.strokeStrong,
    required this.shadow,
    required this.blur,
    required this.blurStrong,
    required this.onPaper,
  });

  /// Which backdrop this set was derived against.
  ///
  /// Not a convenience for reading the brightness — the two backdrops want
  /// their light coming from opposite directions, and [fillGradient] and
  /// [strokeGradient] below are where that is spent.
  final bool onPaper;

  /// Standard translucent fill for cards and panels.
  final Color fill;

  /// Fill for surfaces that must stay readable over busy backdrops
  /// (app bars, bottom sheets, dialogs).
  final Color fillStrong;

  /// Fill for nested surfaces inside another glass panel.
  final Color fillSubtle;

  /// The tone that makes the fill read as a solid rather than a flat swatch.
  ///
  /// On night it is the light the pane catches at its near corner. On paper
  /// there is no such thing — a white highlight on a white card is nothing —
  /// so it is ink instead, gathering at the far corner the way a sheet shades
  /// away from the window. Same field, opposite end; see [fillGradient].
  final Color sheen;

  /// Hairline border colour.
  final Color stroke;

  /// Hairline border for emphasised / selected surfaces.
  final Color strokeStrong;

  /// Ambient drop shadow beneath a floating pane.
  final Color shadow;

  final double blur;
  final double blurStrong;

  /// Glass on paper.
  ///
  /// These were once the dark set with the same numbers — white fills, a white
  /// hairline, white on white — which is why light mode had no edges at all.
  /// Measured, a pane's hairline came out at 1.008 against the pane it was
  /// supposed to be bounding; the dark set's came out at 1.452. A ratio of one
  /// is not a faint line, it is no line, and a card with no line is a card the
  /// eye has to infer from a shadow twelve pixels deep. That inference holds on
  /// a phone, where the pane spans the screen and the bezel finishes the job,
  /// and collapses on a monitor, where three of them stand side by side in the
  /// middle of the field with nothing between.
  ///
  /// So they are re-derived here rather than mirrored. The pane is white, the
  /// field beneath it is not, and the edge between them is drawn in shadow.
  ///
  /// In SHADOW, and not in the brand green, which is the second half of the
  /// same lesson. A pane may carry a [GlassSurface.tint] — the dashboard's
  /// cards are washed red and gold, and eight other places besides — and an
  /// edge with a hue of its own fights every one of them: a red card ringed in
  /// green is two colours arguing across one millimetre. Night never had this
  /// problem because its hairline is WHITE, which belongs to no family and sits
  /// under any wash. Paper's neutral is black. So everything structural here —
  /// the edge, the well, the seat under the pane — is a neutral at low alpha,
  /// and colour is left to the things that are about colour.
  static final light = GlassTokens(
    onPaper: true,
    fill: AppColors.white.withValues(alpha: 0.80),
    // Chrome, with content scrolling underneath it rather than behind it, so
    // it has to be denser than a pane — but short of opaque, or there is no
    // glass left. What shows through at a tenth, over a 28-sigma blur, is the
    // tone of the page below and none of its words.
    fillStrong: AppColors.white.withValues(alpha: 0.90),
    // A well inside a pane, and on paper a well is DARKER: a lighter fill
    // inside an already-white card is the white-on-white mistake again, one
    // level down.
    fillSubtle: AppColors.black.withValues(alpha: 0.05),
    sheen: AppColors.black.withValues(alpha: 0.04),
    // 1.39 and 1.80 against the pane. The first is a hairline you can see, the
    // second is the weight an outlined control's border wants.
    stroke: AppColors.black.withValues(alpha: 0.145),
    strokeStrong: AppColors.black.withValues(alpha: 0.245),
    // The geometry cannot grow — see [GlassSurface.shadowBlur] — so the seat
    // under a pane gets its depth from the alpha instead.
    shadow: AppColors.black.withValues(alpha: 0.13),
    blur: 18,
    blurStrong: 28,
  );

  /// Glass on night, where the panes are colourless and the palette shows
  /// through them from the [AuroraBackground] behind.
  static final dark = GlassTokens(
    onPaper: false,
    fill: AppColors.white.withValues(alpha: 0.08),
    fillStrong: AppColors.darkGreen.withValues(alpha: 0.13),
    fillSubtle: AppColors.white.withValues(alpha: 0.05),
    sheen: AppColors.white.withValues(alpha: 0.12),
    stroke: AppColors.white.withValues(alpha: 0.12),
    strokeStrong: AppColors.white.withValues(alpha: 0.24),
    shadow: AppColors.black.withValues(alpha: 0.40),
    blur: 18,
    blurStrong: 28,
  );

  /// Fill gradient, lit from the top-left in both modes — but by opposite
  /// means. On night the near corner is brightened; on paper it is the FAR
  /// corner that is shaded, because the near one is already white and has
  /// nowhere brighter to go.
  LinearGradient fillGradient({bool strong = false, bool subtle = false}) {
    final base = subtle ? fillSubtle : (strong ? fillStrong : fill);
    // The end of the pane the sheen collects at — the near one on night, the
    // far one on paper.
    final toned = Color.alphaBlend(sheen.withValues(alpha: sheen.a * 0.5), base);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: onPaper ? [base, toned] : [toned, base],
    );
  }

  /// Hairline gradient, and the same inversion.
  ///
  /// On night the edge is light catching glass: strongest where the light hits
  /// and falling away around the pane. On paper it is the opposite thing
  /// entirely — the edge of a sheet is its own shadow, faintest under the
  /// window and gathering at the corner furthest from it. Run the night
  /// profile on paper and every card is darkest exactly where it should be
  /// brightest.
  ///
  /// Neither profile lets the line vanish: the pane is closed all the way
  /// round, and only its weight travels.
  LinearGradient strokeGradient({bool strong = false}) {
    final base = strong ? strokeStrong : stroke;
    Color at(double f) => base.withValues(alpha: base.a * f);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: onPaper
          ? [at(0.5), at(0.75), base]
          : [base, at(0.35), at(0.8)],
      stops: onPaper ? const [0, 0.45, 1] : const [0, 0.55, 1],
    );
  }

  @override
  GlassTokens copyWith({
    Color? fill,
    Color? fillStrong,
    Color? fillSubtle,
    Color? sheen,
    Color? stroke,
    Color? strokeStrong,
    Color? shadow,
    double? blur,
    double? blurStrong,
    bool? onPaper,
  }) {
    return GlassTokens(
      onPaper: onPaper ?? this.onPaper,
      fill: fill ?? this.fill,
      fillStrong: fillStrong ?? this.fillStrong,
      fillSubtle: fillSubtle ?? this.fillSubtle,
      sheen: sheen ?? this.sheen,
      stroke: stroke ?? this.stroke,
      strokeStrong: strokeStrong ?? this.strokeStrong,
      shadow: shadow ?? this.shadow,
      blur: blur ?? this.blur,
      blurStrong: blurStrong ?? this.blurStrong,
    );
  }

  @override
  GlassTokens lerp(ThemeExtension<GlassTokens>? other, double t) {
    if (other is! GlassTokens) return this;
    return GlassTokens(
      // A gradient runs one way or the other; there is no halfway. It flips at
      // the midpoint of the theme crossfade, under two fills that are by then
      // nearly the same colour, so nothing on screen shows the seam.
      onPaper: t < 0.5 ? onPaper : other.onPaper,
      fill: Color.lerp(fill, other.fill, t)!,
      fillStrong: Color.lerp(fillStrong, other.fillStrong, t)!,
      fillSubtle: Color.lerp(fillSubtle, other.fillSubtle, t)!,
      sheen: Color.lerp(sheen, other.sheen, t)!,
      stroke: Color.lerp(stroke, other.stroke, t)!,
      strokeStrong: Color.lerp(strokeStrong, other.strokeStrong, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      blur: lerpDouble(blur, other.blur, t),
      blurStrong: lerpDouble(blurStrong, other.blurStrong, t),
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

/// Gradients for the brand marks.
///
/// Deliberately single-family: running green straight into gold takes the
/// midtones through a muddy olive, which is very visible on a large disc. Each
/// sphere stays inside one family and shades light → dark.
class AppGradients {
  const AppGradients._();

  /// The crescent medallion: a green sphere lit from the top-left.
  static const greenSphere = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.lightGreen, AppColors.darkGreen],
  );

  /// Gold counterpart, for "current season" style emphasis.
  static const goldSphere = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.mediumGold, AppColors.darkGold],
  );

  /// Red counterpart, for destructive or rejected states.
  static const redSphere = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.lightRed, AppColors.darkRed],
  );
}

/// Radii used across the app. Larger, softer corners read as "2026".
class AppRadius {
  const AppRadius._();

  static const xs = 12.0;
  static const sm = 16.0;
  static const md = 20.0;
  static const lg = 26.0;
  static const xl = 32.0;
  static const pill = 999.0;
}

/// Consistent spacing scale — every gap in the app is one of these.
class AppSpacing {
  const AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

extension GlassThemeX on BuildContext {
  GlassTokens get glass =>
      Theme.of(this).extension<GlassTokens>() ?? GlassTokens.dark;

  /// Padding for a scrollable that sits under a [GlassAppBar].
  ///
  /// Screens using `extendBodyBehindAppBar` get a body whose `MediaQuery`
  /// top padding is the app bar's bottom edge — so content clears the bar at
  /// rest while still scrolling underneath it and frosting as it goes.
  EdgeInsets scrollPadding({
    double top = AppSpacing.md,
    double bottom = AppSpacing.xl,
    double horizontal = AppSpacing.lg,
  }) {
    return EdgeInsets.fromLTRB(
      horizontal,
      MediaQuery.paddingOf(this).top + top,
      horizontal,
      MediaQuery.viewPaddingOf(this).bottom + bottom,
    );
  }
}
