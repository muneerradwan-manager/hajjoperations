import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/states.dart';
import '../application/reference_data_cubit.dart';
import '../domain/module_type.dart';
import '../domain/reference_item.dart';
import 'reference_item_detail_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return BlocBuilder<ReferenceDataCubit, ReferenceDataState>(
      builder: (context, state) {
        final set = state.setById(widget.setId);
        if (set == null) {
          return Scaffold(
            appBar: GlassAppBar(title: Text(l.referenceDataTitle)),
            body: const SkeletonList(),
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
          appBar: GlassAppBar(title: Text(set.name.of(context))),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showReferenceItemForm(context, set: set),
            icon: const Icon(AppIcons.add),
            label: Text(l.referenceAddItem),
          ),
          body: ResponsiveCenter(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    MediaQuery.paddingOf(context).top + kToolbarHeight,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: l.commonSearch,
                      prefixIcon: const Icon(AppIcons.search),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? EmptyState(
                          icon: AppIcons.referenceData,
                          title: l.referenceEmpty,
                        )
                      : RefreshIndicator(
                          onRefresh: () =>
                              context.read<ReferenceDataCubit>().load(),
                          child: ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              0,
                              AppSpacing.lg,
                              AppSpacing.xxl * 2 +
                                  MediaQuery.viewPaddingOf(context).bottom,
                            ),
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, i) => FadeSlideIn(
                              delay: Duration(
                                milliseconds: 30 * (i < 8 ? i : 8),
                              ),
                              child: _ItemCard(set: set, item: items[i]),
                            ),
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
    final scheme = Theme.of(context).colorScheme;
    final state = context.watch<ReferenceDataCubit>().state;
    final summary = _summary(context, state);

    return GlassCard(
      blur: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () {
        final cubit = context.read<ReferenceDataCubit>();
        Navigator.of(context).push(
          fadeThroughRoute(
            (_) => BlocProvider.value(
              value: cubit,
              child: ReferenceItemDetailScreen(
                setId: set.id,
                itemId: item.id,
              ),
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
          const NavChevron(),
        ],
      ),
    );
  }
}
