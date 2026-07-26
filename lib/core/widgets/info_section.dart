import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n_extension.dart';
import '../theme/app_icons.dart';
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

/// What a row's value can be acted on with. A phone number is there to be
/// called and an address to be written to — reading either off the screen and
/// retyping it is the failure this avoids.
enum InfoAction {
  call('tel', AppIcons.phoneSy),
  email('mailto', AppIcons.email);

  const InfoAction(this.scheme, this.icon);

  final String scheme;
  final IconData icon;

  Uri uriFor(String value) => Uri(
    scheme: scheme,
    // A number written "+963 11 222" dials only once the spacing is gone.
    path: this == InfoAction.call
        ? value.replaceAll(RegExp(r'[^0-9+]'), '')
        : value.trim(),
  );
}

/// A labelled value row with a leading icon; shows "not provided" when empty.
///
/// Give it an [action] and the value becomes a link: tap to dial or to open a
/// mail composer, long-press to copy.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.action,
  });

  final IconData icon;
  final String label;
  final String? value;
  final InfoAction? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isEmpty = value == null || value!.isEmpty;
    final shown = isEmpty ? context.l10n.profileFieldNotProvided : value!;
    final live = action != null && !isEmpty;

    final row = Padding(
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
                    // Placeholder text recedes so real values read first; a
                    // live value is coloured the way a link is expected to be.
                    color: isEmpty
                        ? scheme.onSurfaceVariant.withValues(alpha: 0.7)
                        : (live ? scheme.primary : scheme.onSurface),
                    fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                  // An address is longer than the row and must not be clipped
                  // to something that reads like a different address.
                  softWrap: true,
                ),
              ],
            ),
          ),
          if (live) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(action!.icon, size: 18, color: scheme.primary),
          ],
        ],
      ),
    );

    if (!live) return row;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () => launchUrl(action!.uriFor(value!)),
      onLongPress: () => copyToClipboard(context, value!),
      child: row,
    );
  }
}

/// Copies [value] and says so. Used where a value is worth having in another
/// app but the link may not resolve — a device with no mail client set up.
Future<void> copyToClipboard(BuildContext context, String value) async {
  final message = context.l10n.commonCopied;
  final messenger = ScaffoldMessenger.of(context);
  await Clipboard.setData(ClipboardData(text: value));
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String formatDate(DateTime? d) => d == null
    ? ''
    : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
