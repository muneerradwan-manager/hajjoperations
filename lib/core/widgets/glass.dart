import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/glass_tokens.dart';

/// The primitive every frosted pane in the app is built from.
///
/// Blurs whatever the [AuroraBackground] is painting behind it, lays a
/// translucent gradient fill on top, and finishes the edge with a gradient
/// hairline so the pane reads as a physical sheet of glass.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = AppRadius.lg,
    this.blur = true,
    this.strong = false,
    this.subtle = false,
    this.bordered = true,
    this.emphasised = false,
    this.shadow = true,
    this.tint,
    this.width,
    this.height,
    this.alignment,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;

  /// Real backdrop blur. Disable for items repeated in long scrolling lists —
  /// the aurora behind them is low-frequency enough that the translucent fill
  /// alone still reads as glass, at a fraction of the cost.
  final bool blur;

  /// Denser fill, for surfaces that must stay legible over anything (app bars,
  /// sheets, dialogs).
  final bool strong;

  /// Lighter fill, for panes nested inside another pane.
  final bool subtle;

  final bool bordered;

  /// Brighter hairline — used for selected / focused states.
  final bool emphasised;

  final bool shadow;

  /// Optional colour wash mixed into the fill, e.g. a status accent.
  final Color? tint;

  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final borderRadius = BorderRadius.circular(radius);

    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        gradient: glass.fillGradient(strong: strong, subtle: subtle),
        borderRadius: borderRadius,
      ),
      child: tint == null
          ? _body(context)
          : DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tint!.withValues(alpha: 0.20),
                    tint!.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: borderRadius,
              ),
              child: _body(context),
            ),
    );

    if (blur) {
      content = BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: strong ? glass.blurStrong : glass.blur,
          sigmaY: strong ? glass.blurStrong : glass.blur,
        ),
        child: content,
      );
    }

    content = ClipRRect(borderRadius: borderRadius, child: content);

    if (bordered) {
      content = CustomPaint(
        foregroundPainter: _HairlinePainter(
          gradient: glass.strokeGradient(strong: emphasised),
          radius: radius,
        ),
        child: content,
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      alignment: alignment,
      decoration: shadow
          ? BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: glass.shadow,
                  blurRadius: 28,
                  spreadRadius: -6,
                  offset: const Offset(0, 12),
                ),
              ],
            )
          : null,
      child: content,
    );
  }

  Widget _body(BuildContext context) {
    // Transparent Material so InkWell ripples from callers still render and
    // clip to the pane.
    return Material(
      type: MaterialType.transparency,
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
  }
}

/// Drop-in replacement for [Card] in the glass language.
///
/// Adds an optional press interaction with a subtle scale — tapping a pane of
/// glass should feel like pressing something physical.
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.radius = AppRadius.lg,
    this.blur = true,
    this.subtle = false,
    this.emphasised = false,
    this.shadow = true,
    this.tint,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final bool blur;
  final bool subtle;
  final bool emphasised;
  final bool shadow;
  final Color? tint;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _pressed = false;

  bool get _interactive => widget.onTap != null || widget.onLongPress != null;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final surface = GlassSurface(
      padding: widget.padding,
      margin: widget.margin,
      radius: widget.radius,
      blur: widget.blur,
      subtle: widget.subtle,
      emphasised: widget.emphasised || _pressed,
      shadow: widget.shadow,
      tint: widget.tint,
      child: _interactive
          ? InkWell(
              onTap: widget.onTap == null
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      widget.onTap!();
                    },
              onLongPress: widget.onLongPress,
              onTapDown: (_) => _setPressed(true),
              onTapUp: (_) => _setPressed(false),
              onTapCancel: () => _setPressed(false),
              borderRadius: BorderRadius.circular(widget.radius),
              child: widget.child,
            )
          : widget.child,
    );

    if (!_interactive) return surface;

    return AnimatedScale(
      scale: _pressed ? 0.975 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: surface,
    );
  }
}

/// App bar that lets content scroll beneath it through a blurred pane instead
/// of hiding behind an opaque bar.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.centerTitle,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final bool? centerTitle;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      bottom: bottom,
      centerTitle: centerTitle,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: glass.blurStrong,
            sigmaY: glass.blurStrong,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: glass.fillGradient(strong: true),
              border: Border(bottom: BorderSide(color: glass.stroke)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small translucent label — status chips, role badges, counters.
class GlassBadge extends StatelessWidget {
  const GlassBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.dense = false,
  });

  final String label;
  final Color? color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 11,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tone.withValues(alpha: 0.26), tone.withValues(alpha: 0.12)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: tone.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 13, color: tone),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: tone,
              fontWeight: FontWeight.w700,
              fontSize: dense ? 10.5 : 12,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular glass icon button, for app-bar and floating actions.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.size = 20,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = GlassSurface(
      radius: AppRadius.pill,
      blur: false,
      shadow: false,
      width: 42,
      height: 42,
      child: InkWell(
        onTap: onPressed == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onPressed!();
              },
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Icon(
          icon,
          size: size,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Paints the gradient hairline that defines a pane's edge.
class _HairlinePainter extends CustomPainter {
  const _HairlinePainter({required this.gradient, required this.radius});

  final Gradient gradient;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.5),
      Radius.circular(radius),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = gradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _HairlinePainter old) =>
      old.gradient != gradient || old.radius != radius;
}
