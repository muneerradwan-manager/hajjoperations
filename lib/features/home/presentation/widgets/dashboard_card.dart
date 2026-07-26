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
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback? onTap;

  /// Optional count shown as a pill — e.g. pending approvals waiting.
  final String? badge;

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
          const NavChevron(),
        ],
      ),
    );
  }
}

/// Rounded-square icon holder with an outward glow in the card's accent.
class _IconMedallion extends StatelessWidget {
  const _IconMedallion({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
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
