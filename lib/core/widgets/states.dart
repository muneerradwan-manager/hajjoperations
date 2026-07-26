import 'package:flutter/material.dart';

import '../theme/glass_tokens.dart';
import 'glass.dart';

/// Illustrated empty state: an orbiting glass medallion, a headline that says
/// what happened, and an optional next step. Replaces bare centred text so a
/// "nothing here" screen never looks like a failure.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        // No app-bar inset here: an EmptyState is often nested inside a list
        // that has already applied one, and the extra padding strands it far
        // down the page.
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HaloIcon(icon: icon, color: scheme.primary),
              const SizedBox(height: AppSpacing.xl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppSpacing.xl),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A glass medallion with a slowly breathing halo behind it.
class _HaloIcon extends StatefulWidget {
  const _HaloIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  State<_HaloIcon> createState() => _HaloIconState();
}

class _HaloIconState extends State<_HaloIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Container(
          width: 116,
          height: 116,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color.withValues(alpha: 0.22 + 0.10 * t),
                widget.color.withValues(alpha: 0),
              ],
            ),
          ),
          child: child,
        );
      },
      child: Center(
        child: GlassSurface(
          radius: AppRadius.pill,
          width: 76,
          height: 76,
          child: Icon(widget.icon, size: 32, color: widget.color),
        ),
      ),
    );
  }
}

/// Shimmering placeholder rows shown while a list loads. Communicates the shape
/// of what is coming, which reads far faster than a lone spinner.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.count = 5,
    this.height = 76,
    this.padding,
  });

  final int count;
  final double height;

  /// Defaults to [GlassThemeX.scrollPadding] so the skeleton clears a glass
  /// app bar exactly the way the real list will.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding ?? context.scrollPadding(),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) => Shimmer(
        delay: Duration(milliseconds: i * 90),
        child: GlassSurface(
          height: height,
          blur: false,
          shadow: false,
          subtle: true,
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Sweeps a soft highlight across its child, on a loop.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.repeat();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlight = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.white.withValues(alpha: 0.55);

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) {
          final dx = rect.width * (_c.value * 2 - 0.5);
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.transparent, highlight, Colors.transparent],
            stops: const [0.35, 0.5, 0.65],
            transform: _SlideGradient(dx),
          ).createShader(rect);
        },
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.dx);

  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(dx, 0, 0);
}

/// Centred branded spinner for full-screen loads that have no list shape.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: GlassSurface(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                strokeCap: StrokeCap.round,
                color: scheme.primary,
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                label!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Section heading used to chunk long screens into scannable groups.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.icon});

  final String title;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: scheme.primary),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
