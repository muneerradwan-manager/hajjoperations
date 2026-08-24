import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_accents.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/glass_tokens.dart';
import '../../domain/journey.dart';
import '../../domain/journey_leg.dart';
import '../travel_labels.dart';

/// A man's season drawn as a line: where he started, where he has got to, and
/// what is still ahead.
///
/// The shape is borrowed on purpose from [SeasonRoadmapView], which draws the
/// season's WORK as a spine with numbered stops. This draws the same season in
/// space rather than in task order, and using the same visual language means a
/// reader who has seen one understands the other without being taught.
///
/// Two rules govern every colour on it, and both exist because the obvious
/// implementation gets them backwards:
///
///   * **A movement he arranged himself is drawn exactly like a booked one.**
///     Same row, same weight, a car for an icon instead of an aeroplane. It is
///     not annotated as an exception, because it is not one — «بسيارة خاصة» is
///     a complete answer to how he got to المدينة.
///   * **Absence is never red.** An unrecorded step is a dotted connector and a
///     grey sentence with a button on it. A return that has not been booked is
///     plain text. Red is kept for `missed` and `cancelled` — for movements
///     that happened and went wrong.
class JourneyTimeline extends StatelessWidget {
  const JourneyTimeline({
    super.key,
    required this.journey,
    this.busyLegId,
    this.onConfirm,
    this.onRecordGap,
    this.onOpenLeg,
  });

  final Journey journey;

  /// The leg mid-write, so its row alone shows a spinner.
  final String? busyLegId;

  /// Offered on a movement waiting for somebody's word. Null when this reader
  /// may not confirm anything — the row then simply states its status.
  final void Function(JourneyLeg leg)? onConfirm;

  /// Offered on an unrecorded step between two places.
  final VoidCallback? onRecordGap;

  final void Function(JourneyLeg leg)? onOpenLeg;

  @override
  Widget build(BuildContext context) {
    final entries = journey.line;
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < entries.length; i++)
          _Entry(
            entry: entries[i],
            isFirst: i == 0,
            isLast: i == entries.length - 1,
            busyLegId: busyLegId,
            onConfirm: onConfirm,
            onRecordGap: onRecordGap,
            onOpenLeg: onOpenLeg,
          ),
      ],
    );
  }
}

/// The width of the spine column — the node plus the air around it.
const double _spineWidth = 44;
const double _nodeSize = 22;

class _Entry extends StatelessWidget {
  const _Entry({
    required this.entry,
    required this.isFirst,
    required this.isLast,
    this.busyLegId,
    this.onConfirm,
    this.onRecordGap,
    this.onOpenLeg,
  });

  final JourneyEntry entry;
  final bool isFirst;
  final bool isLast;
  final String? busyLegId;
  final void Function(JourneyLeg leg)? onConfirm;
  final VoidCallback? onRecordGap;
  final void Function(JourneyLeg leg)? onOpenLeg;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _spineWidth,
            child: _Spine(entry: entry, isFirst: isFirst, isLast: isLast),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: switch (entry) {
                JourneyStop() => _StopCard(stop: entry as JourneyStop),
                JourneyMove() => _MoveCard(
                  leg: (entry as JourneyMove).leg,
                  busy: busyLegId == (entry as JourneyMove).leg.id,
                  onConfirm: onConfirm,
                  onOpen: onOpenLeg,
                ),
                JourneyGap() => _GapCard(
                  gap: entry as JourneyGap,
                  onRecord: onRecordGap,
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The line, and what sits on it at this row.
class _Spine extends StatelessWidget {
  const _Spine({
    required this.entry,
    required this.isFirst,
    required this.isLast,
  });

  final JourneyEntry entry;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dim = scheme.outlineVariant;

    // A stop carries the node; a movement is just the line passing through,
    // with its mode drawn small on it.
    final stop = entry is JourneyStop ? entry as JourneyStop : null;
    final move = entry is JourneyMove ? entry as JourneyMove : null;

    final reached = stop != null && stop.state != JourneyStopState.upcoming;
    final lineColor = reached ? Accent.green.of(context) : dim;

    return Column(
      children: [
        Expanded(
          child: Container(
            width: 2,
            color: isFirst ? Colors.transparent : lineColor,
          ),
        ),
        if (stop != null)
          _Node(state: stop.state)
        else if (move != null)
          _ModeDot(leg: move.leg)
        else
          // A gap: the line breaks. Dotted, and in the ordinary outline colour
          // — this is "we do not know", not "something is wrong".
          SizedBox(
            height: _nodeSize,
            child: CustomPaint(
              painter: _DottedLinePainter(color: dim),
              size: const Size(2, _nodeSize),
            ),
          ),
        Expanded(
          child: Container(
            width: 2,
            color: isLast
                ? Colors.transparent
                : (entry is JourneyStop && reached ? lineColor : dim),
          ),
        ),
      ],
    );
  }
}

/// A place on the line.
class _Node extends StatelessWidget {
  const _Node({required this.state});

  final JourneyStopState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final green = Accent.green.of(context);

    return switch (state) {
      // Been and gone: filled, with a tick.
      JourneyStopState.done => Container(
        width: _nodeSize,
        height: _nodeSize,
        decoration: BoxDecoration(color: green, shape: BoxShape.circle),
        child: Icon(Icons.check, size: 14, color: scheme.surface),
      ),
      // Where he is now: a ring, heavier than the rest, so the eye finds it
      // before it reads anything.
      JourneyStopState.current => Container(
        width: _nodeSize + 6,
        height: _nodeSize + 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: green.withValues(alpha: 0.16),
          border: Border.all(color: green, width: 2.5),
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: green, shape: BoxShape.circle),
          ),
        ),
      ),
      // Ahead of him: an empty outline.
      JourneyStopState.upcoming => Container(
        width: _nodeSize,
        height: _nodeSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.surface,
          border: Border.all(color: scheme.outlineVariant, width: 2),
        ),
      ),
    };
  }
}

/// The way he travelled, drawn on the line itself.
class _ModeDot extends StatelessWidget {
  const _ModeDot({required this.leg});

  final JourneyLeg leg;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = leg.status.isDone;
    final colour = leg.status.isFailure
        ? scheme.error
        : done
        ? Accent.green.of(context)
        : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.surface),
      // The car and the aeroplane are drawn identically. That is the point.
      child: Icon(travelModeIcon(leg.mode), size: 16, color: colour),
    );
  }
}

class _StopCard extends StatelessWidget {
  const _StopCard({required this.stop});

  final JourneyStop stop;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isHere = stop.state == JourneyStopState.current;

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Flexible(
            child: Text(
              stop.place?.of(context) ?? '—',
              style: text.titleSmall?.copyWith(
                fontWeight: isHere ? FontWeight.w700 : FontWeight.w600,
                color: stop.state == JourneyStopState.upcoming
                    ? scheme.onSurfaceVariant
                    : scheme.onSurface,
              ),
            ),
          ),
          if (isHere) ...[
            const SizedBox(width: AppSpacing.sm),
            _Pill(label: l.travelHereNow, color: Accent.green.of(context)),
          ],
          const Spacer(),
          if (stop.at != null)
            Text(
              travelWhen(context, stop.at, withTime: false),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

/// One movement: what carried him, when, and — when nothing else can say —
/// the button that closes it out.
class _MoveCard extends StatelessWidget {
  const _MoveCard({
    required this.leg,
    required this.busy,
    this.onConfirm,
    this.onOpen,
  });

  final JourneyLeg leg;
  final bool busy;
  final void Function(JourneyLeg leg)? onConfirm;
  final void Function(JourneyLeg leg)? onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    // What this movement WAS: a flight number when it had one, the plain name
    // of the way he travelled when it did not. A private car gets «برّاً ·
    // ترتيب ذاتي» and no empty carrier row.
    final title =
        leg.carrierLabel ??
        (leg.selfArranged
            ? '${travelModeLabel(context, leg.mode)} · ${l.travelSelfArranged}'
            : travelModeLabel(context, leg.mode));

    final when = leg.actualDepartureAt ?? leg.plannedDepartureAt;

    return InkWell(
      onTap: onOpen == null ? null : () => onOpen!(leg),
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _Pill(
                  label: legStatusLabel(context, leg.status),
                  color: legStatusColor(context, leg.status),
                ),
                if (leg.attachmentCount > 0) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    AppIcons.travelTicket,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  travelWhen(context, when),
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                // The plan, struck through, but only when it actually differs.
                // Showing it beside every punctual departure would be noise.
                if (leg.departedLate) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    travelWhen(context, leg.plannedDepartureAt),
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.sm),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (leg.needsManualConfirmation && onConfirm != null) ...[
              const SizedBox(height: AppSpacing.xs),
              // Said in words, because it is not obvious: for a private car
              // there IS no airline feed and no gate. If he does not say he
              // arrived, nothing ever will.
              Text(
                l.travelNeedsYourWord,
                style: text.bodySmall?.copyWith(
                  color: travelPendingColor(context),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.tonalIcon(
                  onPressed: () => onConfirm!(leg),
                  icon: const Icon(AppIcons.approve, size: 18),
                  label: Text(l.travelConfirmArrival),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ] else if (leg.isOverdue && onConfirm != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => onConfirm!(leg),
                  icon: const Icon(AppIcons.approve, size: 18),
                  label: Text(l.travelConfirmArrival),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A step nobody recorded.
///
/// Grey, dotted, and phrased as a statement of fact. The commonest cause by far
/// is the coach from جدة airport to مكة, which the mission does not track and
/// has no reason to — so this must never look like a fault, and it offers
/// rather than demands.
class _GapCard extends StatelessWidget {
  const _GapCard({required this.gap, this.onRecord});

  final JourneyGap gap;
  final VoidCallback? onRecord;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final from = gap.from?.of(context);
    final to = gap.to?.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Which move, in words. Without this the line reads as a complaint
          // about nothing in particular: the reader sees مطار جدة above and
          // محطة مكة below and is left to infer what is being asked.
          if (from != null && to != null)
            Text(
              l.travelBetween(from, to),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          Row(
            children: [
              Flexible(
                child: Text(
                  // Says «اختياري» in the same breath. The commonest cause of
                  // this line by far is the coach from the airport, which the
                  // mission does not track and has no reason to — so it must
                  // not read as a form somebody failed to fill in.
                  l.travelUntrackedTransferOptional,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ),
              if (onRecord != null) ...[
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: onRecord,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(l.travelRecordTransferShort),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// The small status chip used across the line.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  const _DottedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 3.0;
    const gap = 4.0;
    var y = 0.0;
    final x = size.width / 2;
    while (y < size.height) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, (y + dash).clamp(0, size.height)),
        paint,
      );
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DottedLinePainter old) => old.color != color;
}
