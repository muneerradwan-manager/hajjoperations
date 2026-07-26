import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../theme/glass_tokens.dart';
import 'glass.dart';

/// A titled glass pane grouping a set of [InfoRow]s, with hairline separators
/// between rows so long detail screens stay scannable.
class InfoSection extends StatelessWidget {
  const InfoSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
  });

  final String title;
  final List<Widget> children;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A labelled value row with a leading icon; shows "not provided" when empty.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isEmpty = value == null || value!.isEmpty;
    final shown = isEmpty ? context.l10n.profileFieldNotProvided : value!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  shown,
                  style: text.bodyLarge?.copyWith(
                    // Placeholder text recedes so real values read first.
                    color: isEmpty
                        ? scheme.onSurfaceVariant.withValues(alpha: 0.7)
                        : scheme.onSurface,
                    fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String formatDate(DateTime? d) => d == null
    ? ''
    : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
