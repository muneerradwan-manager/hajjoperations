/// The chart marks this dashboard is built from.
///
/// Five shapes, and each is here because a different question needed answering:
/// a headline number ([StatTile]), a ranked list too long for colour
/// ([RankedBars]), a whole split into two or three parts ([SplitBar]), a
/// quantity over time ([TrendChart]), and a distribution across a fixed scale
/// ([StarBars]). Anything the season can be asked is one of those five.
///
/// Shared rules, applied in every one of them:
///
///   * **Text wears text colours.** A number is never painted in its series
///     colour — the mark beside it carries the identity, and a coloured numeral
///     is a numeral somebody has to squint at.
///   * **Data ends are rounded 4px and anchored to the baseline.** A bar grows
///     from the axis; the axis end stays square so the row still reads as
///     measured from a line.
///   * **Fills that touch are separated by 2px of surface.** Two segments of
///     similar value with no gap read as one segment.
///   * **Never colour alone.** Every segment that carries a colour also carries
///     its name and its number, within reach of the mark.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/chart_palette.dart';
import '../../../../core/theme/glass_tokens.dart';
import '../../../../core/widgets/glass.dart';

/// A headline number: the answer, before any chart.
///
/// Most of what a dashboard is asked has a single number for an answer, and
/// drawing that number as a one-bar chart is worse than printing it. The mark
/// here is the medallion — identity — and the number is text.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.caption,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  /// The second line, for what the number does not say on its own — "of 240",
  /// "since Sunday".
  final String? caption;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      onTap: onTap,
      tint: color,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: text.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: text.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              // Ink, not the accent: the medallion above already said which
              // thing this is.
              color: scheme.onSurface,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// One slice of a whole, for [SplitBar] and the legends that go with it.
class ChartSlice {
  const ChartSlice({required this.label, required this.value});

  final String label;
  final num value;
}

/// A whole, divided into two or three named parts.
///
/// One bar rather than a pie, because the question a split answers is "how much
/// of it" and a length is read far more accurately than an angle. Three parts
/// is the ceiling: past that the segments get too short to label, and the right
/// chart is [RankedBars].
///
/// The legend is always drawn and always carries the number, so the chart
/// survives being printed, photocopied, or read by somebody who cannot separate
/// the hues at all.
class SplitBar extends StatelessWidget {
  const SplitBar({super.key, required this.slices, this.height = 14});

  final List<ChartSlice> slices;
  final double height;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final shown = slices.where((s) => s.value > 0).toList();
    final total = shown.fold<num>(0, (sum, s) => sum + s.value);

    if (total == 0) {
      return _EmptyTrack(height: height);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                for (var i = 0; i < shown.length; i++) ...[
                  // 2px of surface between fills. Without it two segments of
                  // similar value read as one.
                  if (i > 0)
                    SizedBox(
                      width: 2,
                      child: ColoredBox(color: scheme.surface),
                    ),
                  Expanded(
                    flex: math.max(1, (shown[i].value * 1000 ~/ total)),
                    child: ColoredBox(
                      color: _colorFor(context, slices.indexOf(shown[i])),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            for (final slice in shown)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _colorFor(context, slices.indexOf(slice)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    slice.label,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${slice.value}',
                    style: text.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  /// Fixed order: slot 0 is the first slice NAMED, not the first one drawn. A
  /// category that falls to zero must not repaint the ones that remain.
  Color _colorFor(BuildContext context, int index) =>
      ChartPalette.series[index % ChartPalette.series.length].of(context);
}

/// A list ranked by magnitude — the eight biggest trades, the file types of a
/// season.
///
/// One hue for every row, because the identity is already written at the start
/// of each bar and the number at the end. Colouring nine rows nine ways would
/// add a legend nobody needs and a palette nobody could tell apart.
class RankedBars extends StatelessWidget {
  const RankedBars({
    super.key,
    required this.slices,
    this.color,
    this.maxRows = 8,
  });

  final List<ChartSlice> slices;
  final Color? color;
  final int maxRows;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final fill = color ?? ChartPalette.sequential.of(context);

    final rows = [...slices]..sort((a, b) => b.value.compareTo(a.value));
    final shown = rows.take(maxRows).toList();
    // The scale is the biggest bar, not the total: this compares rows with each
    // other, and a share-of-whole reading is what [SplitBar] is for.
    final peak = shown.isEmpty ? 0 : shown.map((s) => s.value).reduce(math.max);

    if (shown.isEmpty || peak == 0) return _EmptyTrack(height: 14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  shown[i].label,
                  style: text.bodySmall?.copyWith(color: scheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${shown[i].value}',
                style: text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          _Bar(fraction: shown[i].value / peak, color: fill),
        ],
      ],
    );
  }
}

/// One horizontal measure: a recessive track with the value drawn over it.
class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  static const height = 8.0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: ChartPalette.track(context)),
            FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              // Never nothing: a row that exists but rounds to zero width reads
              // as a row that is missing.
              widthFactor: fraction.clamp(0.02, 1).toDouble(),
              child: ColoredBox(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTrack extends StatelessWidget {
  const _EmptyTrack({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height / 2),
    child: SizedBox(
      height: height,
      child: ColoredBox(color: ChartPalette.track(context)),
    ),
  );
}

/// One point of a [TrendChart].
class TrendPoint {
  const TrendPoint({required this.day, required this.value});

  final DateTime day;
  final num value;
}

/// A quantity over time — the reports a season files, day by day.
///
/// One series, so no legend: the card's own title names it. A 2px line with a
/// soft fill beneath, which is what makes a run of days read as a shape rather
/// than as a row of numbers. Tapping anywhere on it puts a crosshair on the
/// nearest day and says what that day was, because a sparkline that cannot be
/// interrogated is decoration.
class TrendChart extends StatefulWidget {
  const TrendChart({
    super.key,
    required this.points,
    required this.emptyLabel,
    this.height = 132,
    this.labelForDay,
  });

  final List<TrendPoint> points;
  final String emptyLabel;
  final double height;

  /// How to write a day in the readout. Left to the caller, which is the only
  /// place that knows the locale and the calendar the reader is on.
  final String Function(DateTime day)? labelForDay;

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final line = ChartPalette.sequential.of(context);
    final points = widget.points;

    if (points.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            widget.emptyLabel,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final peak = points.map((p) => p.value).reduce(math.max);
    final touched = _touched == null
        ? null
        : points[_touched!.clamp(0, points.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The readout sits ABOVE the plot rather than floating over it: a
        // tooltip that covers the line hides the thing being asked about, and
        // on a touch screen it is under the finger as well.
        SizedBox(
          height: 20,
          child: touched == null
              ? const SizedBox.shrink()
              : Row(
                  children: [
                    Text(
                      '${touched.value}',
                      style: text.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      widget.labelForDay?.call(touched.day) ?? '',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _touch(d.localPosition.dx, constraints.maxWidth),
            onHorizontalDragUpdate: (d) =>
                _touch(d.localPosition.dx, constraints.maxWidth),
            onHorizontalDragEnd: (_) => setState(() => _touched = null),
            onTapUp: (_) => setState(() => _touched = null),
            onTapCancel: () => setState(() => _touched = null),
            child: CustomPaint(
              size: Size(constraints.maxWidth, widget.height),
              painter: _TrendPainter(
                points: points,
                peak: peak.toDouble(),
                line: line,
                grid: ChartPalette.track(context),
                touched: _touched,
                textDirection: Directionality.of(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _touch(double dx, double width) {
    if (widget.points.length < 2 || width <= 0) return;
    // Measured from the START edge, whichever side that is: the series runs
    // left-to-right in English and right-to-left in Arabic, and the finger is
    // pointing at a day, not at a pixel.
    final fromStart = Directionality.of(context) == TextDirection.rtl
        ? width - dx
        : dx;
    final step = width / (widget.points.length - 1);
    final index = (fromStart / step).round().clamp(0, widget.points.length - 1);
    if (index != _touched) setState(() => _touched = index);
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.points,
    required this.peak,
    required this.line,
    required this.grid,
    required this.touched,
    required this.textDirection,
  });

  final List<TrendPoint> points;
  final double peak;
  final Color line;
  final Color grid;
  final int? touched;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || peak <= 0) return;

    // A baseline and one line at the peak. Two rules, because a third is a grid
    // and a grid on a shape this small competes with the shape.
    final rule = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      rule,
    );
    canvas.drawLine(const Offset(0, 0.5), Offset(size.width, 0.5), rule);

    Offset at(int i) {
      final t = points.length == 1 ? 0.5 : i / (points.length - 1);
      final x = textDirection == TextDirection.rtl
          ? size.width * (1 - t)
          : size.width * t;
      final y = size.height - (points[i].value / peak) * (size.height - 6);
      return Offset(x, y);
    }

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }

    // The fill closes down to the baseline, which is what turns a line into a
    // quantity: the area under it is the reports filed.
    final fill = Path.from(path)
      ..lineTo(at(points.length - 1).dx, size.height)
      ..lineTo(at(0).dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [line.withValues(alpha: 0.28), line.withValues(alpha: 0.02)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    if (touched != null && touched! >= 0 && touched! < points.length) {
      final p = at(touched!);
      canvas.drawLine(
        Offset(p.dx, 0),
        Offset(p.dx, size.height),
        Paint()
          ..color = line.withValues(alpha: 0.35)
          ..strokeWidth = 1,
      );
      // A ring of surface around the dot so it reads on top of the fill rather
      // than in it.
      canvas.drawCircle(p, 6, Paint()..color = grid);
      canvas.drawCircle(p, 4, Paint()..color = line);
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.touched != touched ||
      old.points != points ||
      old.peak != peak ||
      old.line != line;
}

/// A distribution across a fixed scale: how many ones, how many fives.
///
/// Vertical, because the scale is ordered and reads left to right the way it is
/// spoken. One hue — the position on the axis IS the category, and colouring
/// five bars five ways would say the fives and the ones are unrelated things.
class StarBars extends StatelessWidget {
  const StarBars({super.key, required this.counts, this.height = 96});

  /// Five entries, ones first.
  final List<int> counts;

  final double height;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final fill = ChartPalette.sequential.of(context);
    final peak = counts.isEmpty ? 0 : counts.reduce(math.max);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < counts.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${counts[i]}',
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    // Rounded at the top, square at the baseline: the bar grows
                    // from the axis and should still look measured from it.
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                    child: SizedBox(
                      height: peak == 0
                          ? 3
                          : math.max(3, (counts[i] / peak) * (height - 40)),
                      child: ColoredBox(
                        color: counts[i] == 0
                            ? ChartPalette.track(context)
                            : fill,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${i + 1}',
                        style: text.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.star_rounded,
                        size: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
