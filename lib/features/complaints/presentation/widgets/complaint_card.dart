import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/glass_tokens.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/info_section.dart';
import '../../domain/complaint.dart';
import 'complaint_labels.dart';

/// One complaint as a row in either register.
class ComplaintCard extends StatelessWidget {
  const ComplaintCard({super.key, required this.complaint, this.onOpen});

  final Complaint complaint;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    // A dismissed complaint is not deleted and not hidden — it is greyed, the
    // way a struck line stays legible.
    final muted = complaint.isDismissed;
    final title = (complaint.targetLabel ?? '').trim().isEmpty
        ? complaintTargetLabel(l, complaint.target)
        : complaint.targetLabel!;

    return GlassCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            complaintTargetIcon(complaint.target),
            color: muted ? scheme.onSurfaceVariant : scheme.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.titleMedium?.copyWith(
                    color: muted ? scheme.onSurfaceVariant : null,
                    decoration: muted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  complaint.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    GlassBadge(
                      label: complaintTargetLabel(l, complaint.target),
                      icon: complaintTargetIcon(complaint.target),
                      dense: true,
                    ),
                    GlassBadge(
                      label: l.complaintFiledOn(formatDate(complaint.createdAt)),
                      icon: AppIcons.pending,
                      dense: true,
                    ),
                    if (complaint.replyCount > 0)
                      GlassBadge(
                        label: l.complaintReplyCount(complaint.replyCount),
                        icon: AppIcons.complaints,
                        dense: true,
                      ),
                    if (complaint.attachmentCount > 0)
                      GlassBadge(
                        label: '${complaint.attachmentCount}',
                        icon: AppIcons.attach,
                        dense: true,
                      ),
                    if (complaint.isLocked)
                      GlassBadge(
                        label: l.complaintLocked,
                        icon: AppIcons.complaintLocked,
                        color: scheme.onSurfaceVariant,
                        dense: true,
                      ),
                    if (complaint.isDismissed)
                      GlassBadge(
                        label: l.complaintDismissed,
                        icon: AppIcons.complaintDismissed,
                        color: scheme.error,
                        dense: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const NavChevron(),
        ],
      ),
    );
  }
}
