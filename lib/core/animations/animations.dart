import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A widget that fades + slides its child in when first built.
/// Used to stagger form fields and list items on entry.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 450),
    this.offset = const Offset(0, 0.08),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: widget.offset,
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Wraps [children] with an incrementally increasing entry delay.
///
/// The delay stops growing after [maxSteps]: on a long list the ramp stops
/// reading as a cascade and starts reading as the screen being slow.
List<Widget> staggered(
  List<Widget> children, {
  Duration step = const Duration(milliseconds: 70),
  Duration start = Duration.zero,
  int maxSteps = 8,
}) {
  return [
    for (var i = 0; i < children.length; i++)
      FadeSlideIn(
        delay: start + step * (i < maxSteps ? i : maxSteps),
        child: children[i],
      ),
  ];
}

const _transitionDuration = Duration(milliseconds: 400);
const _reverseTransitionDuration = Duration(milliseconds: 300);

/// Material fade-through: the outgoing page finishes fading out *before* the
/// incoming one starts fading in.
///
/// The sequencing matters here — every scaffold in this app is transparent so
/// the aurora shows through, and an overlapping cross-fade would briefly show
/// both pages' content stacked on top of each other.
Widget _fadeThroughTransition(
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final fadeIn = CurvedAnimation(
    parent: animation,
    curve: const Interval(0.35, 1, curve: Curves.easeOut),
  );
  final fadeOut = CurvedAnimation(
    parent: secondaryAnimation,
    curve: const Interval(0, 0.35, curve: Curves.easeIn),
  );
  final scale = Tween<double>(begin: 0.97, end: 1).animate(fadeIn);

  return AnimatedBuilder(
    animation: Listenable.merge([fadeIn, fadeOut]),
    builder: (context, child) => Opacity(
      opacity: (fadeIn.value * (1 - fadeOut.value)).clamp(0.0, 1.0),
      child: Transform.scale(scale: scale.value, child: child),
    ),
    child: child,
  );
}

/// Shared fade-through page transition for go_router routes.
CustomTransitionPage<T> fadeThroughPage<T>({
  required Widget child,
  required LocalKey key,
}) {
  return CustomTransitionPage<T>(
    key: key,
    transitionDuration: _transitionDuration,
    reverseTransitionDuration: _reverseTransitionDuration,
    opaque: false,
    child: child,
    transitionsBuilder: (context, animation, secondary, child) =>
        _fadeThroughTransition(animation, secondary, child),
  );
}

/// The imperative counterpart, for `Navigator.push` inside a feature.
///
/// Use this instead of [MaterialPageRoute]: the default Material route slides
/// the incoming page across while the outgoing one stays put, which reveals
/// both through the transparent scaffolds.
///
/// [opaque] is what to reach for when the route underneath is not one of these.
/// A page pushed over another page is fine left transparent — the one below
/// fades itself out on its secondary animation, and staying transparent lets
/// the aurora through unbroken. A page pushed over a MODAL BOTTOM SHEET is not:
/// the sheet has no such animation, so it simply stays there, showing through
/// the new page along with its barrier. Marking the route opaque stops the
/// navigator painting anything below it once it settles; the aurora is mounted
/// outside the navigator and still shows through the transparent scaffold.
Route<T> fadeThroughRoute<T>(WidgetBuilder builder, {bool opaque = false}) {
  return PageRouteBuilder<T>(
    transitionDuration: _transitionDuration,
    reverseTransitionDuration: _reverseTransitionDuration,
    opaque: opaque,
    pageBuilder: (context, animation, secondary) => builder(context),
    transitionsBuilder: (context, animation, secondary, child) =>
        _fadeThroughTransition(animation, secondary, child),
  );
}
