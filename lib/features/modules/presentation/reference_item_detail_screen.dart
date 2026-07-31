import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/info_section.dart';
import '../../../core/widgets/overflow_menu.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/states.dart';
import '../application/reference_data_cubit.dart';
import '../domain/map_location.dart';
import '../domain/module_type.dart';
import '../domain/reference_item.dart';
import 'widgets/reference_item_form.dart';

/// One master-data entry in full: every field its set defines, plus edit and
/// delete. A link field is rendered as something you can actually open.
class ReferenceItemDetailScreen extends StatelessWidget {
  const ReferenceItemDetailScreen({
    super.key,
    required this.setId,
    required this.itemId,
  });

  final String setId;
  final String itemId;

  Future<void> _delete(BuildContext context, ReferenceItem item) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final cubit = context.read<ReferenceDataCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.commonDelete),
        content: Text(l.referenceDeleteConfirm(item.name.of(dialogContext))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await cubit.deleteItem(item.id);
    final message = switch (result.outcome) {
      ReferenceOutcome.ok => l.referenceItemDeleted,
      ReferenceOutcome.inUse => l.referenceInUse,
      ReferenceOutcome.duplicate => l.referenceDuplicate,
      ReferenceOutcome.failed => result.message ?? '',
    };
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    if (result.isOk) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return BlocBuilder<ReferenceDataCubit, ReferenceDataState>(
      builder: (context, state) {
        final set = state.setById(setId);
        final item = state.itemById(setId, itemId);

        if (set == null || item == null) {
          return Scaffold(
            appBar: GlassAppBar(title: Text(l.referenceDataTitle)),
            body: const SkeletonList(maxColumns: 1, height: 220, count: 2),
          );
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: GlassAppBar(
            title: Text(item.name.of(context)),
            actions: [
              OverflowMenu(
                actions: [
                  MenuAction(
                    icon: AppIcons.edit,
                    label: l.commonEdit,
                    onSelected: () =>
                        showReferenceItemForm(context, set: set, item: item),
                  ),
                  MenuAction(
                    icon: AppIcons.delete,
                    label: l.commonDelete,
                    isDestructive: true,
                    onSelected: () => _delete(context, item),
                  ),
                ],
              ),
            ],
          ),
          // Builder, and it matters: `scrollPadding` reads the MediaQuery that
          // Scaffold rewrites for its BODY, where the top inset includes the
          // app bar. The BlocBuilder context above returns only the status bar,
          // and the list slid under the bar — which is what test/
          // scroll_padding_test.dart was written to guard and this screen
          // slipped past by reading the wrong context.
          body: Builder(
            builder: (context) => ResponsivePage(
              builder: (context, size) => SinglePaneLayout(
                gutter: size.gutter,
                children: staggered([
                  InfoSection(
                    title: l.referenceDetailsTitle,
                    icon: AppIcons.referenceData,
                    children: [
                      InfoRow(
                        icon: AppIcons.referenceData,
                        label: l.referenceItemName,
                        value: item.name.ar,
                      ),
                      if (item.name.en != null && item.name.en!.isNotEmpty)
                        InfoRow(
                          icon: AppIcons.referenceData,
                          label: l.referenceItemNameEn,
                          value: item.name.en,
                        ),
                      for (final field in set.fields)
                        if (!_isActionable(field.kind))
                          InfoRow(
                            icon: _iconFor(field.kind),
                            label: field.label.of(context),
                            value: _display(context, state, field, item),
                          ),
                    ],
                  ),
                  // What has been put INSIDE this entry, where something can be.
                  // A تكتل holds مجموعات and they add up to a number of their
                  // own; nothing else in the master data nests yet.
                  ..._dependentCards(context, state, set, item),
                  // These get their own card rather than a row: a location is
                  // there to be opened and a number to be dialled, not read.
                  for (final field in set.fields)
                    if (_isActionable(field.kind)) ...[
                      const SizedBox(height: AppSpacing.md),
                      _ActionCard(
                        label: field.label.of(context),
                        value: item.data[field.key]?.toString(),
                        kind: field.kind,
                      ),
                    ],
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// What other master data points AT this entry, and what it adds up to.
///
/// A تكتل is the case this was written for. It carries العدد الكلي — the most it
/// can take — and the مجموعات assigned to it carry numbers of their own. The
/// second figure is deliberately NOT a column: it is the sum of its groups, and
/// storing it would create a second place for it to be wrong the moment a group
/// is edited.
///
/// Written against the schema rather than against the word "cluster": any set
/// whose entries reference this one gets the same card. The convention it rests
/// on is stated rather than clever — the FIRST number field of a set is the
/// figure that set counts in, so a parent's is its ceiling and a child's is its
/// share.
List<Widget> _dependentCards(
  BuildContext context,
  ReferenceDataState state,
  ReferenceSet set,
  ReferenceItem item,
) {
  final l = context.l10n;
  final cards = <Widget>[];

  for (final child in state.sets) {
    if (child.id == set.id) continue;
    final link = child.fields
        .where(
          (f) =>
              f.kind == ModuleFieldKind.reference &&
              f.referenceSetId == set.id,
        )
        .firstOrNull;
    if (link == null) continue;

    final mine = state
        .visibleItems(child.id)
        .where((i) => i.data[link.key] == item.id)
        .toList();
    if (mine.isEmpty) continue;

    final childNumber = child.fields
        .where((f) => f.kind == ModuleFieldKind.number)
        .firstOrNull;
    final total = childNumber == null
        ? null
        : mine.fold<int>(
            0,
            (sum, i) =>
                sum + (int.tryParse('${i.data[childNumber.key] ?? ''}') ?? 0),
          );

    final ownNumber = set.fields
        .where((f) => f.kind == ModuleFieldKind.number)
        .firstOrNull;
    final capacity = ownNumber == null
        ? null
        : int.tryParse('${item.data[ownNumber.key] ?? ''}');

    // A ceiling that has been passed is the whole reason the two numbers are
    // shown together, so it is said rather than left to be worked out.
    final over = capacity != null && total != null && total > capacity;

    cards
      ..add(const SizedBox(height: AppSpacing.md))
      ..add(
        InfoSection(
          title: child.name.of(context),
          icon: AppIcons.referenceData,
          children: [
            InfoRow(
              icon: AppIcons.referenceData,
              label: l.referenceChildCount(child.name.of(context)),
              value: '${mine.length}',
            ),
            if (total != null)
              InfoRow(
                icon: AppIcons.document,
                label: childNumber!.label.of(context),
                value: capacity == null
                    ? '$total'
                    : l.referenceOfCapacity(total, capacity),
              ),
            if (over)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  l.referenceOverCapacity(total - capacity),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            for (final i in mine)
              InfoRow(
                icon: AppIcons.selected,
                label: i.name.of(context),
                value: childNumber == null
                    ? null
                    : '${i.data[childNumber.key] ?? ''}',
              ),
          ],
        ),
      );
  }
  return cards;
}

/// Kinds whose value is something to act on rather than something to read.
bool _isActionable(ModuleFieldKind kind) =>
    kind == ModuleFieldKind.url ||
    kind == ModuleFieldKind.location ||
    kind == ModuleFieldKind.phone;

IconData _iconFor(ModuleFieldKind kind) => switch (kind) {
  ModuleFieldKind.reference => AppIcons.organization,
  ModuleFieldKind.date => AppIcons.seasons,
  ModuleFieldKind.pdf => AppIcons.pdf,
  ModuleFieldKind.phone => AppIcons.phoneSy,
  _ => AppIcons.document,
};

String _display(
  BuildContext context,
  ReferenceDataState state,
  ModuleField field,
  ReferenceItem item,
) {
  final value = item.data[field.key];
  if (value == null) return '';
  if (field.kind == ModuleFieldKind.reference) {
    final target = state
        .setById(field.referenceSetId ?? '')
        ?.items
        .where((i) => i.id == value)
        .firstOrNull;
    return target?.name.of(context) ?? '';
  }
  if (field.kind == ModuleFieldKind.date) {
    return formatDate(value is String ? DateTime.tryParse(value) : null);
  }
  return '$value';
}

/// A field whose value is meant to be acted on: a map to open, a page to visit,
/// a number to ring. Shown as a tappable card rather than a row of text.
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.label,
    required this.value,
    required this.kind,
  });

  final String label;
  final String? value;
  final ModuleFieldKind kind;

  Uri? get _target => switch (kind) {
    // A location stores a map URL; a phone dials — once the spacing a human
    // typed into it is gone, which some dialers refuse to handle themselves.
    ModuleFieldKind.phone => InfoAction.call.uriFor(value!),
    _ => Uri.tryParse(value!),
  };

  IconData get _icon => switch (kind) {
    ModuleFieldKind.location => AppIcons.location,
    ModuleFieldKind.phone => AppIcons.phoneSy,
    _ => AppIcons.view,
  };

  String _action(BuildContext context) => switch (kind) {
    ModuleFieldKind.location => context.l10n.locationOpenMap,
    ModuleFieldKind.phone => context.l10n.referenceCall,
    _ => context.l10n.referenceOpenLink,
  };

  /// A location reads as coordinates rather than as a long URL nobody parses.
  String _shown() {
    if (kind != ModuleFieldKind.location) return value!;
    final coordinates = MapLocation.parse(value);
    if (coordinates == null) return value!;
    return '${coordinates.latitude.toStringAsFixed(5)}, '
        '${coordinates.longitude.toStringAsFixed(5)}';
  }

  Future<void> _open(BuildContext context) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final uri = _target;
    final launched =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.referenceLinkFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final filled = value != null && value!.isNotEmpty;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: filled ? () => _open(context) : null,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(_icon, size: 18, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(
                  filled ? _shown() : l.profileFieldNotProvided,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // Keeps a leading '+' or '-' — both neutral to bidi, so both
                  // liable to jump to the far end of an Arabic line — attached
                  // to the number it belongs to.
                  textDirection:
                      kind == ModuleFieldKind.phone ||
                          kind == ModuleFieldKind.location
                      ? TextDirection.ltr
                      : null,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: filled ? scheme.primary : scheme.onSurfaceVariant,
                    fontStyle: filled ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          if (filled)
            Text(
              _action(context),
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: scheme.primary),
            ),
        ],
      ),
    );
  }
}
