import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/glass_tokens.dart';

/// Five stars — to read, or to set.
///
/// Given [onRated] it is a control: tapping the third star says three, and
/// tapping the star already at the end of the run takes the rating back
/// altogether. That last part matters, because with five stars and no undo the
/// mildest thing anybody can say is one star, and a rating given by accident
/// would have to be turned into an insult or left standing.
///
/// Without [onRated] it is a picture: [value] may be fractional, and a half is
/// drawn as a half.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.value,
    this.onRated,
    this.size = 22,
  });

  final double value;

  /// Null for a read-only row. Called with null when the rating is withdrawn.
  final void Function(int? stars)? onRated;

  final double size;

  static const _count = 5;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filled = scheme.secondary;
    final empty = scheme.onSurfaceVariant.withValues(alpha: 0.35);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= _count; i++)
          _star(context, i, filled: filled, empty: empty),
      ],
    );
  }

  Widget _star(
    BuildContext context,
    int position, {
    required Color filled,
    required Color empty,
  }) {
    // How much of THIS star is filled: all of it, none, or the remainder for
    // the one the average lands inside.
    final fill = (value - (position - 1)).clamp(0.0, 1.0);

    final star = SizedBox(
      width: size + 2,
      height: size + 2,
      child: Center(
        child: Stack(
          children: [
            Icon(Icons.star_rounded, size: size, color: empty),
            if (fill > 0)
              ClipRect(
                clipper: _FractionClipper(
                  fill,
                  Directionality.of(context) == TextDirection.rtl,
                ),
                child: Icon(Icons.star_rounded, size: size, color: filled),
              ),
          ],
        ),
      ),
    );

    if (onRated == null) return star;

    return InkResponse(
      radius: size,
      onTap: () {
        HapticFeedback.selectionClick();
        // Tapping the star the rating already ends on withdraws it.
        onRated!(value.round() == position ? null : position);
      },
      child: star,
    );
  }
}

/// Shows [fraction] of a star, from whichever side the language starts on.
class _FractionClipper extends CustomClipper<Rect> {
  const _FractionClipper(this.fraction, this.rtl);

  final double fraction;
  final bool rtl;

  @override
  Rect getClip(Size size) => rtl
      ? Rect.fromLTRB(size.width * (1 - fraction), 0, size.width, size.height)
      : Rect.fromLTRB(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_FractionClipper old) =>
      old.fraction != fraction || old.rtl != rtl;
}

/// A person's own result in a finished file: the stars, the number, and how
/// many people said it. Never who.
class RatingSummaryLine extends StatelessWidget {
  const RatingSummaryLine({
    super.key,
    required this.average,
    required this.ratings,
    required this.label,
  });

  final double average;
  final int ratings;

  /// "4.2 من 5 · 5 تقييمات", already worded by the caller.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StarRating(value: average, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
