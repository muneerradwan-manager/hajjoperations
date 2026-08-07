import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/glass_tokens.dart';
import '../../../../core/widgets/glass.dart';

/// A navigation pane on the dashboard: a colour-washed glass card with a
/// glowing icon medallion, a title and a one-line explanation of what lives
/// behind it.
class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    this.onTap,
    this.badge,
    this.action,
    this.actionTooltip,
    this.actionIcon,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback? onTap;

  /// Optional count shown as a pill — e.g. pending approvals waiting.
  final String? badge;

  /// A second thing this card can do, raised as a small floating button where
  /// the chevron would be.
  ///
  /// One card, two verbs, and they are not equals: the card OPENS something and
  /// the button DOES something. That is why the button is raised rather than
  /// drawn flat beside the title — a lifted control reads as an act, and a card
  /// reads as a door.
  ///
  /// It replaces the chevron rather than joining it. A chevron promises that
  /// pressing here goes somewhere, which is already what the whole card
  /// promises; leaving both would put two conflicting invitations a thumb's
  /// width apart, and the smaller one is the one that would be pressed by
  /// accident.
  final VoidCallback? action;
  final String? actionTooltip;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      onTap: onTap,
      tint: color,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          _IconMedallion(icon: icon, color: color),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: text.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      GlassBadge(label: badge!, color: color, dense: true),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (action case final act?)
            // `heroTag: null` because this is not the screen's floating action
            // button and there may be several on the page — Flutter throws on
            // duplicate hero tags, and two of these cards would be two.
            FloatingActionButton.small(
              heroTag: null,
              onPressed: act,
              tooltip: actionTooltip,
              backgroundColor: color,
              foregroundColor: scheme.onPrimary,
              elevation: 2,
              child: Icon(actionIcon ?? AppIcons.add),
            )
          else
            const NavChevron(),
        ],
      ),
    );
  }
}

/// The same door, drawn small enough that four of them fit where one
/// [DashboardCard] stood: medallion above, name under it, nothing else.
///
/// For الإدارة, where a reader with every permission is handed twelve of these.
/// Twelve full-width rows is four screens of scrolling, and a manager looking
/// for الصلاحيات was reading twelve explanations to find one word — so in that
/// section the explanation comes OFF the tile and goes onto the group heading
/// above it, and the tiles pack two and three to a row. The subtitle is not
/// thrown away: it is the tooltip, which is what a pointer asks for and what a
/// screen reader is handed.
///
/// Not for العام, which is three or four tiles and can afford to explain
/// itself.
class CompactDashboardCard extends StatelessWidget {
  const CompactDashboardCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;

  /// Not drawn. Carried for the tooltip and for anything reading the tree
  /// aloud — see the class comment.
  final String? subtitle;

  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final card = GlassCard(
      onTap: onTap,
      tint: color,
      // Tighter than [DashboardCard]'s, and the medallion below is smaller for
      // the same reason: stacking the icon ABOVE the name instead of beside it
      // buys the second column but spends height doing it, and twelve tiles two
      // to a row have to come out shorter than twelve rows of one or the whole
      // exchange was for nothing.
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.md,
      ),
      child: Column(
        // The tile is as tall as the longest name in its row — two lines for
        // "إدارة الملفات التشغيلية", one for "المواسم" — and the medallions
        // have to land on the same line across that row regardless. So the
        // column takes the height it is given and pins the icon to the top.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _IconMedallion(icon: icon, color: color, size: 44),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: text.labelLarge,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    return subtitle == null ? card : Tooltip(message: subtitle!, child: card);
  }
}

/// Rounded-square icon holder with an outward glow in the card's accent.
class _IconMedallion extends StatelessWidget {
  const _IconMedallion({
    required this.icon,
    required this.color,
    this.size = 50,
  });

  final IconData icon;
  final Color color;

  /// Smaller on the compact tile, where the medallion is stacked above the name
  /// rather than set beside it and every pixel of it is height.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.42),
            color.withValues(alpha: 0.16),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
