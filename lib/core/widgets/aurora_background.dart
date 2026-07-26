import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The living backdrop the whole app sits on: a slow mesh of drifting colour
/// orbs over a deep gradient, finished with a fine grain so the glass panes
/// above it have something with texture to refract.
///
/// Mounted once in [MaterialApp.builder], so every route inherits it and route
/// transitions never flash a flat background.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 32),
  );

  bool _motionEnabled = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honour the OS "reduce motion" switch: hold the field on a still frame
    // rather than animating it.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final enabled = !reduceMotion;
    if (enabled != _motionEnabled || (!_c.isAnimating && enabled)) {
      _motionEnabled = enabled;
      if (enabled) {
        _c.repeat();
      } else {
        _c.stop();
        _c.value = 0.18;
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: _baseGradient(isDark)),
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => CustomPaint(
                  painter: _AuroraPainter(t: _c.value, isDark: isDark),
                  isComplex: true,
                  willChange: true,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _GrainPainter(isDark: isDark)),
          ),
        ),
        Positioned.fill(child: widget.child),
      ],
    );
  }

  LinearGradient _baseGradient(bool isDark) {
    return isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.nightTop,
              AppColors.nightMid,
              AppColors.nightEnd,
            ],
            stops: [0, 0.55, 1],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.paperTop,
              AppColors.paperMid,
              AppColors.paperEnd,
            ],
            stops: [0, 0.6, 1],
          );
  }
}

/// One drifting light source in the mesh.
class _Orb {
  const _Orb({
    required this.color,
    required this.center,
    required this.radius,
    required this.drift,
    required this.speed,
    required this.phase,
  });

  final Color color;

  /// Rest position in Alignment space (-1..1).
  final Alignment center;

  /// Radius as a fraction of the viewport's longest side.
  final double radius;

  /// Travel distance in Alignment space.
  final Offset drift;

  final double speed;
  final double phase;
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.t, required this.isDark});

  final double t;
  final bool isDark;

  static const _darkOrbs = <_Orb>[
    _Orb(
      color: AppColors.lightGreen,
      center: Alignment(-0.8, -0.85),
      radius: 0.62,
      drift: Offset(0.35, 0.22),
      speed: 1,
      phase: 0,
    ),
    _Orb(
      color: AppColors.mediumGreen,
      center: Alignment(0.95, -0.45),
      radius: 0.55,
      drift: Offset(-0.3, 0.3),
      speed: 0.75,
      phase: 1.7,
    ),
    _Orb(
      color: AppColors.darkGold,
      center: Alignment(0.6, 0.9),
      radius: 0.5,
      drift: Offset(-0.35, -0.2),
      speed: 0.6,
      phase: 3.1,
    ),
    _Orb(
      color: AppColors.mediumRed, // depth in the shadows
      center: Alignment(-0.85, 0.75),
      radius: 0.46,
      drift: Offset(0.28, -0.26),
      speed: 0.9,
      phase: 4.6,
    ),
  ];

  // Tighter than the dark set: over a bright base, a wide orb flattens into a
  // uniform wash instead of reading as a pool of colour.
  static const _lightOrbs = <_Orb>[
    _Orb(
      color: AppColors.lightGreen,
      center: Alignment(-0.75, -0.75),
      radius: 0.55,
      drift: Offset(0.32, 0.2),
      speed: 1,
      phase: 0,
    ),
    _Orb(
      color: AppColors.mediumGreen,
      center: Alignment(0.95, -0.5),
      radius: 0.48,
      drift: Offset(-0.28, 0.28),
      speed: 0.75,
      phase: 1.7,
    ),
    _Orb(
      color: AppColors.mediumGold,
      center: Alignment(0.6, 0.85),
      radius: 0.5,
      drift: Offset(-0.32, -0.18),
      speed: 0.6,
      phase: 3.1,
    ),
    _Orb(
      color: AppColors.mediumRed,
      center: Alignment(-0.85, 0.7),
      radius: 0.44,
      drift: Offset(0.26, -0.24),
      speed: 0.9,
      phase: 4.6,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final orbs = isDark ? _darkOrbs : _lightOrbs;
    final longest = math.max(size.width, size.height);
    final tau = math.pi * 2;
    // Peak alpha at the orb core. Kept low in light mode — the colour should
    // read as a tint in the paper, not as a wash over the whole screen. The
    // brand hues are deep, so light mode needs less of them than a pastel
    // would have taken.
    final peak = isDark ? 0.26 : 0.14;

    for (final orb in orbs) {
      final angle = tau * t * orb.speed + orb.phase;
      final dx = orb.center.x + math.sin(angle) * orb.drift.dx;
      final dy = orb.center.y + math.cos(angle * 0.8) * orb.drift.dy;
      final center = Alignment(dx, dy).withinRect(Offset.zero & size);
      final radius = longest * orb.radius * (0.92 + 0.08 * math.sin(angle));

      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..blendMode = isDark ? BlendMode.plus : BlendMode.srcOver
        ..shader = RadialGradient(
          colors: [
            orb.color.withValues(alpha: peak),
            orb.color.withValues(alpha: peak * 0.45),
            orb.color.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(rect);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) =>
      old.t != t || old.isDark != isDark;
}

/// Fixed-seed film grain. Static, so it paints once and is cached by the
/// enclosing [RepaintBoundary].
class _GrainPainter extends CustomPainter {
  const _GrainPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(2026);
    final paint = Paint();
    final color = isDark ? AppColors.white : AppColors.black;
    final count = (size.width * size.height / 900).clamp(200, 2600).toInt();

    for (var i = 0; i < count; i++) {
      paint.color = color.withValues(
        alpha: (isDark ? 0.020 : 0.014) * random.nextDouble(),
      );
      canvas.drawRect(
        Rect.fromLTWH(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
          1.4,
          1.4,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GrainPainter old) => old.isDark != isDark;
}
