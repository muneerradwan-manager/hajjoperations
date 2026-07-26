import 'package:flutter/widgets.dart';

/// Centers content and caps its width on large screens (tablets/desktop) so
/// pages don't stretch edge-to-edge and drift to a corner.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 600});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
