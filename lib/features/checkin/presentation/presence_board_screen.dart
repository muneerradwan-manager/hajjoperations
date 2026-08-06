import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/error_text.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/states.dart';
import '../application/check_in_cubit.dart';
import '../data/check_in_repository.dart';
import '../domain/check_in.dart';

/// Who is present, across the whole season.
///
/// One board rather than one per file, and that is the point of it. Presence
/// used to be read inside an operational file, which meant a supervisor
/// answering "is anybody at the camps tonight" opened a file, read a list,
/// went back, opened another. Since 0098 an arrival is a fact about a PLACE,
/// so the natural screen is the season's places — and a hotel in المدينة, which
/// belongs to no file at all, finally appears on it.
///
/// Grouped by PLACE, not by person. The room's question is "who is in this
/// hotel"; a flat list of names sorted by time answers a question nobody asked.
class PresenceBoardScreen extends StatelessWidget {
  const PresenceBoardScreen({super.key, this.itemId, this.placeName});

  /// Set when the board was opened from one place — a pin on the map, a hotel's
  /// page — rather than from the shelf.
  final String? itemId;
  final String? placeName;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => PresenceCubit(CheckInRepository(), itemId: itemId),
    child: _View(title: placeName),
  );
}

class _View extends StatelessWidget {
  const _View({this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      appBar: GlassAppBar(title: Text(title ?? l.presenceTitle)),
      body: BlocBuilder<PresenceCubit, PresenceState>(
        builder: (context, state) {
          final cubit = context.read<PresenceCubit>();

          if (state.status == PresenceStatus.loading) {
            return const SkeletonList(minTileWidth: 360);
          }
          if (state.status == PresenceStatus.error) {
            return EmptyState(
              icon: AppIcons.warning,
              title: friendlyError(context, state.error),
            );
          }

          final places = state.byPlace;

          return ResponsivePage(
            builder: (context, size) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    size.gutter,
                    AppSpacing.sm,
                    size.gutter,
                    0,
                  ),
                  child: _Filters(state: state, cubit: cubit),
                ),
                Expanded(
                  child: places.isEmpty
                      ? EmptyState(
                          icon: AppIcons.checkIn,
                          title: l.presenceEmpty,
                          message: l.presenceEmptyHint,
                        )
                      : RefreshIndicator(
                          onRefresh: cubit.load,
                          child: ListView.builder(
                            padding: EdgeInsets.fromLTRB(
                              size.gutter,
                              AppSpacing.md,
                              size.gutter,
                              AppSpacing.xxl +
                                  MediaQuery.viewPaddingOf(context).bottom,
                            ),
                            itemCount: places.length,
                            itemBuilder: (context, i) => FadeSlideIn(
                              delay: Duration(
                                milliseconds: 30 * (i < 8 ? i : 8),
                              ),
                              child: _PlaceCard(group: places[i]),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.state, required this.cubit});

  final PresenceState state;
  final PresenceCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final groups = state.groups;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: TextField(
            decoration: InputDecoration(
              hintText: l.commonSearch,
              prefixIcon: const Icon(AppIcons.search),
            ),
            onChanged: cubit.setQuery,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // How far back "now" reaches. A shift is what the word means to the
        // room, and which shift is the reader's to choose — an evening
        // inspection wants today, a night in منى wants the last few hours.
        SegmentedButton<Duration>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: const Duration(hours: 4),
              label: Text(l.presenceWindow4h),
            ),
            ButtonSegment(
              value: const Duration(hours: 12),
              label: Text(l.presenceWindow12h),
            ),
            ButtonSegment(
              value: const Duration(hours: 24),
              label: Text(l.presenceWindow24h),
            ),
          ],
          selected: {state.window},
          onSelectionChanged: (s) => cubit.setWindow(s.first),
        ),
        if (groups.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          // The same four the map shows — فنادق مكة, فنادق المدينة, مخيمات منى,
          // مخيمات عرفات — and for the same reason nothing here names them:
          // they fall out of each entry's own dividing reference, so a fifth
          // appears the day a fifth exists.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final group in groups)
                FilterChip(
                  selected: !state.hiddenGroups.contains(group),
                  label: Text(group),
                  onSelected: (_) => cubit.toggleGroup(group),
                ),
              if (state.hiddenGroups.isNotEmpty)
                TextButton(
                  onPressed: cubit.showAllGroups,
                  child: Text(l.seasonMapShowAll),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          l.presenceCounts(state.showing, state.byPlace.length),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.group});

  final PresenceGroup group;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.location, size: 18, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.placeName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (group.groupName != null)
                        Text(
                          group.groupName!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${group.lines.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            for (final line in group.lines) _Line(line: line),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.line});

  final PresenceLine line;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.fullName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  // Distance is shown plainly and without a warning beside it.
                  // Every row on this board was measured against the place's
                  // own radius and passed, by construction — the flag that used
                  // to live here could not fire any more, and a warning that
                  // never fires teaches a room to stop reading warnings.
                  l.checkInDistance(line.distanceM.round().toString()),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if ((line.note ?? '').isNotEmpty)
                  Text(
                    line.note!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          Text(
            DateFormat.jm().format(line.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
