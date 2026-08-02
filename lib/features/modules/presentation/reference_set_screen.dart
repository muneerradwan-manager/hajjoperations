import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/constants/permission_codes.dart';
import '../../../core/l10n/error_text.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/blocking_progress.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/overflow_menu.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/states.dart';
import '../../auth/application/session_cubit.dart';
import '../application/reference_data_cubit.dart';
import '../domain/module_type.dart';
import '../domain/reference_item.dart';
import 'reference_item_detail_screen.dart';
import 'widgets/reference_item_actions.dart';
import 'widgets/reference_item_form.dart';

/// Every entry in one master-data list — hotels, or clusters, or cities. The
/// summary line under each name is built from that list's own schema, so this
/// screen never needs to know what a hotel is.
class ReferenceSetScreen extends StatefulWidget {
  const ReferenceSetScreen({super.key, required this.setId});

  final String setId;

  @override
  State<ReferenceSetScreen> createState() => _ReferenceSetScreenState();
}

class _ReferenceSetScreenState extends State<ReferenceSetScreen> {
  String _query = '';

  bool _matches(BuildContext context, ReferenceItem item) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return item.name.of(context).toLowerCase().contains(q) ||
        item.data.values.any((v) => '$v'.toLowerCase().contains(q));
  }

  /// Copies another season's entries into this one. They arrive as copies and
  /// stay unrelated: deleting one here leaves the season it came from alone.
  Future<void> _import(BuildContext context, ReferenceSet set) async {
    final l = context.l10n;
    final cubit = context.read<ReferenceDataCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final seasons = await cubit.otherSeasons();
    if (!context.mounted) return;

    if (seasons.isEmpty) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.referenceImportNoSeasons)));
      return;
    }

    final from = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Text(
                l.referenceImportPick,
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
            ),
            for (final season in seasons)
              ListTile(
                leading: const Icon(AppIcons.seasons),
                title: Text(l.seasonHijriYear(season.hijriYear)),
                onTap: () => Navigator.of(sheetContext).pop(season.id),
              ),
          ],
        ),
      ),
    );
    if (from == null) return;

    final copied = await cubit.importFromSeason(
      setId: set.id,
      fromSeasonId: from,
    );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            copied == null
                ? l.referenceImportFailed
                : l.referenceImported(copied),
          ),
        ),
      );
  }

  /// Empties the list of everything currently listed — which, when a search is
  /// narrowing it, is what the reader is looking at rather than the whole set.
  /// Deleting 200 hotels because one was searched for would be the worse
  /// surprise of the two.
  Future<void> _deleteAll(
    BuildContext context,
    ReferenceSet set,
    List<ReferenceItem> items,
  ) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<ReferenceDataCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.referenceDeleteAll),
        content: Text(
          l.referenceDeleteAllConfirm(items.length, set.name.of(dialogContext)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // One round trip per entry, so the screen is sealed for the duration: the
    // list underneath is being emptied and a tap into it lands on rows that are
    // already gone.
    final result = await runBlocking(
      context,
      () => cubit.deleteItems(items.map((i) => i.id)),
      message: l.referenceDeletingAll,
    );

    final message = switch (result) {
      BulkDeleteResult(deleted: 0, message: final failure?) => friendlyErrorL(
        l,
        failure,
      ),
      BulkDeleteResult(kept: 0) => l.referenceDeleteAllDone(result.deleted),
      BulkDeleteResult(deleted: 0) => l.referenceDeleteAllNone,
      _ => l.referenceDeleteAllPartial(result.deleted, result.kept),
    };
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = context.watch<SessionCubit>().state;
    final canEdit = session.can(PermissionCodes.referenceEdit);
    final canDelete = session.can(PermissionCodes.referenceDelete);
    final canImport = session.can(PermissionCodes.referenceImport);

    return BlocBuilder<ReferenceDataCubit, ReferenceDataState>(
      builder: (context, state) {
        final set = state.setById(widget.setId);
        if (set == null) {
          return Scaffold(
            appBar: GlassAppBar(title: Text(l.referenceDataTitle)),
            body: const SkeletonList(minTileWidth: 320),
          );
        }

        // This season's entries, for a set that is scoped to one. The hotels of
        // 1447 are not the hotels of 1448.
        final items = state
            .visibleItems(set.id)
            .where((i) => _matches(context, i))
            .toList();

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: GlassAppBar(
            title: Text(set.name.of(context)),
            actions: [
              // Importing a season and emptying the list are not two glyphs to
              // tell apart on a title bar when one of them destroys the list.
              // Behind one overflow icon they are words, and the dangerous one
              // sits under a divider.
              OverflowMenu(
                actions: [
                  // Only a season-scoped list has anything to import: the
                  // cities do not start over each year.
                  if (canImport && set.isSeasonScoped && state.season != null)
                    MenuAction(
                      icon: AppIcons.download,
                      label: l.referenceImport,
                      onSelected: () => _import(context, set),
                    ),
                  if (canDelete && items.isNotEmpty)
                    MenuAction(
                      icon: AppIcons.delete,
                      label: l.referenceDeleteAll,
                      isDestructive: true,
                      onSelected: () => _deleteAll(context, set, items),
                    ),
                ],
              ),
            ],
          ),
          floatingActionButton: canEdit
              ? FloatingActionButton.extended(
                  onPressed: () => showReferenceItemForm(context, set: set),
                  icon: const Icon(AppIcons.add),
                  label: Text(l.referenceAddItem),
                )
              : null,
          body: ResponsivePage(
            builder: (context, size) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    size.gutter,
                    MediaQuery.paddingOf(context).top + kToolbarHeight,
                    size.gutter,
                    AppSpacing.sm,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: l.commonSearch,
                        prefixIcon: const Icon(AppIcons.search),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? EmptyState(
                          icon: AppIcons.referenceData,
                          title: l.referenceEmpty,
                        )
                      // A set is every hotel, every cluster — long enough to
                      // page in as it is reached.
                      : AdaptiveGridView(
                          onRefresh: () =>
                              context.read<ReferenceDataCubit>().load(),
                          padding: EdgeInsets.fromLTRB(
                            size.gutter,
                            0,
                            size.gutter,
                            AppSpacing.xxl * 2 +
                                MediaQuery.viewPaddingOf(context).bottom,
                          ),
                          minTileWidth: 320,
                          itemCount: items.length,
                          itemBuilder: (context, i) => FadeSlideIn(
                            delay: Duration(milliseconds: 30 * (i < 8 ? i : 8)),
                            child: _ItemCard(set: set, item: items[i]),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.set, required this.item});

  final ReferenceSet set;
  final ReferenceItem item;

  /// A one-line précis built from the set's own fields, so a hotel row reads
  /// "Makkah" and a cluster row reads its head — without this screen knowing
  /// what either of those is.
  String _summary(BuildContext context, ReferenceDataState state) {
    final parts = <String>[];
    for (final field in set.fields) {
      // Links and numbers are for acting on, not for scanning — the summary
      // stays the couple of words that tell two entries apart.
      if (field.kind == ModuleFieldKind.url ||
          field.kind == ModuleFieldKind.location ||
          field.kind == ModuleFieldKind.phone) {
        continue;
      }
      final value = item.data[field.key];
      if (value == null || '$value'.isEmpty) continue;
      if (field.kind == ModuleFieldKind.reference) {
        final target = state
            .setById(field.referenceSetId ?? '')
            ?.items
            .where((i) => i.id == value)
            .firstOrNull;
        if (target != null) parts.add(target.name.of(context));
      } else {
        parts.add('$value');
      }
    }
    return parts.join('  •  ');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final state = context.watch<ReferenceDataCubit>().state;
    final session = context.watch<SessionCubit>().state;
    final summary = _summary(context, state);
    final canEdit = session.can(PermissionCodes.referenceEdit);
    final canDelete = session.can(PermissionCodes.referenceDelete);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () {
        final cubit = context.read<ReferenceDataCubit>();
        Navigator.of(context).push(
          fadeThroughRoute(
            (_) => BlocProvider.value(
              value: cubit,
              child: ReferenceItemDetailScreen(setId: set.id, itemId: item.id),
            ),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              AppIcons.referenceData,
              size: 18,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.of(context),
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    summary,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Correcting a name and removing an entry are the two things done to
          // master data, and both were a screen away behind the row. They are
          // put where the list already is — the same three dots the operational
          // files and the reports carry.
          if (canEdit || canDelete)
            OverflowMenu(
              actions: [
                if (canEdit)
                  MenuAction(
                    icon: AppIcons.edit,
                    label: l.commonEdit,
                    onSelected: () =>
                        showReferenceItemForm(context, set: set, item: item),
                  ),
                if (canDelete)
                  MenuAction(
                    icon: AppIcons.delete,
                    label: l.commonDelete,
                    isDestructive: true,
                    onSelected: () => confirmDeleteReferenceItem(context, item),
                  ),
              ],
            )
          else
            const NavChevron(),
        ],
      ),
    );
  }
}
