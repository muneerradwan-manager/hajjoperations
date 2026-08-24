import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_accents.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/glass_tokens.dart';
import '../../domain/journey.dart';
import '../../domain/journey_leg.dart';
import '../../domain/journey_stay.dart';
import '../travel_labels.dart';

/// A man's season drawn as a line of PLACES HE LIVED, connected by the
/// movements that carried him between them.
///
/// The proportions are the point. A season is thirty-five days — about thirty
/// in مكة and five in المدينة — and a few hours of aeroplane and train. So a
/// stay is a card carrying its city, its مسكن and its length, and a movement is
/// a thin line between two cards with its terminals in small type.
///
/// The first version of this widget had it the other way round and drew a spine
/// of airports. That put the hours on the page and left the month off it, and
/// it invented a "gap" between مطار جدة and محطة مكة that had never been a gap:
/// جدة is where the aeroplane touched down on the way to مكة.
///
/// Two rules still govern every colour, both from 0129:
///
///   * **A movement he arranged himself is drawn exactly like a booked one** —
///     same weight, a car for an icon. «بسيارة خاصة» is a complete answer.
///   * **Absence is never red.** A stay whose مسكن the files have not resolved
///     simply omits the line; a return not yet booked is plain text. Red
///     belongs to `missed` and `cancelled` — movements that happened and went
///     wrong.
class JourneyTimeline extends StatelessWidget {
  const JourneyTimeline({
    super.key,
    required this.journey,
    this.busyLegId,
    this.onConfirm,
    this.onOpenLeg,
  });

  final Journey journey;

  /// The leg mid-write, so its row alone shows a spinner.
  final String? busyLegId;

  /// Offered on a movement waiting for somebody's word. Null when this reader
  /// may not confirm anything — the row then simply states its status.
  final void Function(JourneyLeg leg)? onConfirm;

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
            onOpenLeg: onOpenLeg,
          ),
      ],
    );
  }
}

/// The width of the spine column — the node plus the air around it.
const double _spineWidth = 44;
const double _nodeSize = 26;

class _Entry extends StatelessWidget {
  const _Entry({
    required this.entry,
    required this.isFirst,
    required this.isLast,
    this.busyLegId,
    this.onConfirm,
    this.onOpenLeg,
  });

  final JourneyEntry entry;
  final bool isFirst;
  final bool isLast;
  final String? busyLegId;
  final void Function(JourneyLeg leg)? onConfirm;
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
                JourneyStop() => _StayCard(stay: (entry as JourneyStop).stay),
                JourneyMove() => _MoveCard(
                  leg: (entry as JourneyMove).leg,
                  busy: busyLegId == (entry as JourneyMove).leg.id,
                  onConfirm: onConfirm,
                  onOpen: onOpenLeg,
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

    final stop = entry is JourneyStop ? entry as JourneyStop : null;
    final move = entry is JourneyMove ? entry as JourneyMove : null;

    final reached = stop != null && !stop.stay.isFuture;
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
          _StayNode(stay: stop.stay)
        else if (move != null)
          _ModeDot(leg: move.leg),
        Expanded(
          child: Container(
            width: 2,
            color: isLast ? Colors.transparent : (reached ? lineColor : dim),
          ),
        ),
      ],
    );
  }
}

/// A place he stayed. Larger than the mode dot, because it is the larger fact.
class _StayNode extends StatelessWidget {
  const _StayNode({required this.stay});

  final JourneyStay stay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final green = Accent.green.of(context);
    final icon = switch (stay.kind) {
      StayKind.home => AppIcons.myProfile,
      StayKind.rites => AppIcons.checkIn,
      StayKind.residence => AppIcons.organization,
    };

    if (stay.isCurrent) {
      // Where he is now: a heavier ring, so the eye finds it before it reads
      // anything else on the page.
      return Container(
        width: _nodeSize + 6,
        height: _nodeSize + 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: green.withValues(alpha: 0.16),
          border: Border.all(color: green, width: 2.5),
        ),
        child: Icon(icon, size: 14, color: green),
      );
    }

    if (stay.isPast) {
      return Container(
        width: _nodeSize,
        height: _nodeSize,
        decoration: BoxDecoration(color: green, shape: BoxShape.circle),
        child: Icon(icon, size: 13, color: scheme.surface),
      );
    }

    return Container(
      width: _nodeSize,
      height: _nodeSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant, width: 2),
      ),
      child: Icon(icon, size: 13, color: scheme.onSurfaceVariant),
    );
  }
}

/// The way he travelled, drawn small on the line itself.
class _ModeDot extends StatelessWidget {
  const _ModeDot({required this.leg});

  final JourneyLeg leg;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colour = leg.status.isFailure
        ? scheme.error
        : leg.status.isDone
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

/// Where he was based: the city, the مسكن, and how long — the substantial card.
class _StayCard extends StatelessWidget {
  const _StayCard({required this.stay});

  final JourneyStay stay;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final nights = stay.nights;

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  stay.city?.of(context) ?? '—',
                  style: text.titleSmall?.copyWith(
                    fontWeight: stay.isCurrent
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: stay.isFuture
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                  ),
                ),
              ),
              if (stay.isCurrent) ...[
                const SizedBox(width: AppSpacing.sm),
                _Pill(label: l.travelHereNow, color: Accent.green.of(context)),
              ],
              const Spacer(),
              // How long he was there — the number this whole arrangement
              // exists to put on the page.
              if (nights != null && (nights > 0 || stay.isCurrent))
                Text(
                  stay.isCurrent
                      ? l.travelDaysSoFar(nights)
                      : l.travelDays(nights),
                  style: text.labelMedium?.copyWith(
                    color: stay.isCurrent
                        ? Accent.green.of(context)
                        : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          // The مسكن, when the operational files post him to one (0136). It is
          // never asked for here: nobody types a hotel, and a stay with none
          // resolved simply does not draw the line — that is a fact about the
          // paperwork, not a blank the traveller should be handed.
          if (stay.place != null)
            Row(
              children: [
                Icon(
                  AppIcons.organization,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    stay.place!.of(context),
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if (stay.arrivedAt != null)
            Text(
              stay.departedAt == null
                  ? l.travelSince(
                      travelWhen(context, stay.arrivedAt, withTime: false),
                    )
                  : '${travelWhen(context, stay.arrivedAt, withTime: false)}'
                        ' — '
                        '${travelWhen(context, stay.departedAt, withTime: false)}',
              style: text.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
        ],
      ),
    );
  }
}

/// One movement: what carried him, when, and — where nothing else can say —
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
    final from = leg.fromPoint?.of(context);
    final to = leg.toPoint?.of(context);

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
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  travelWhen(context, when, withTime: false),
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (leg.status.isFailure) ...[
                  const SizedBox(width: AppSpacing.xs),
                  _Pill(
                    label: legStatusLabel(context, leg.status),
                    color: legStatusColor(context, leg.status),
                  ),
                ],
              ],
            ),
            // The terminals, small and underneath — a detail of the vehicle,
            // not somewhere he went. Drawing these as destinations is exactly
            // what 0135 was written to undo.
            if (from != null && to != null)
              Text(
                '$from ← $to',
                style: text.bodySmall?.copyWith(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
            ] else if (leg.isOverdue && onConfirm != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => onConfirm!(leg),
                  icon: const Icon(AppIcons.approve, size: 18),
                  label: Text(l.travelConfirmArrival),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
          ],
        ),
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
