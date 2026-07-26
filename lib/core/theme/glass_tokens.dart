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
  });

  /// Standard translucent fill for cards and panels.
  final Color fill;

  /// Fill for surfaces that must stay readable over busy backdrops
  /// (app bars, bottom sheets, dialogs).
  final Color fillStrong;

  /// Fill for nested surfaces inside another glass panel.
  final Color fillSubtle;

  /// Top-left specular highlight that gives the pane its "edge of glass" look.
  final Color sheen;

  /// Hairline border colour.
  final Color stroke;

  /// Hairline border for emphasised / selected surfaces.
  final Color strokeStrong;

  /// Ambient drop shadow beneath a floating pane.
  final Color shadow;

  final double blur;
  final double blurStrong;

  /// Glass is white-on-brand: the panes themselves are colourless, and the
  /// palette shows through them from the [AuroraBackground] behind.
  static final light = GlassTokens(
    fill: AppColors.white.withValues(alpha: 0.60),
    fillStrong: AppColors.white.withValues(alpha: 0.80),
    fillSubtle: AppColors.white.withValues(alpha: 0.40),
    sheen: AppColors.white.withValues(alpha: 0.50),
    stroke: AppColors.white.withValues(alpha: 0.20),
    strokeStrong: AppColors.white.withValues(alpha: 0.40),
    shadow: AppColors.darkGreen.withValues(alpha: 0.10),
    blur: 18,
    blurStrong: 28,
  );

  static final dark = GlassTokens(
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

  /// Vertical fill gradient — slightly brighter at the top edge, which is what
  /// sells the illusion of a pane catching light from above.
  LinearGradient fillGradient({bool strong = false, bool subtle = false}) {
    final base = subtle ? fillSubtle : (strong ? fillStrong : fill);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(sheen.withValues(alpha: sheen.a * 0.5), base),
        base,
      ],
    );
  }

  /// Hairline gradient: bright where the light hits, fading around the pane.
  LinearGradient strokeGradient({bool strong = false}) {
    final base = strong ? strokeStrong : stroke;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        base,
        base.withValues(alpha: base.a * 0.35),
        base.withValues(alpha: base.a * 0.8),
      ],
      stops: const [0, 0.55, 1],
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
  }) {
    return GlassTokens(
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
