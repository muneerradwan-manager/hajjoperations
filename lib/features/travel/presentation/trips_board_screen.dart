import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/constants/permission_codes.dart';
import '../../../core/l10n/error_text.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/creator_page.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/states.dart';
import '../../auth/application/session_cubit.dart';
import '../application/trips_cubit.dart';
import '../data/travel_repository.dart';
import '../domain/trip.dart';
import 'travel_gaps_screen.dart';
import 'travel_labels.dart';
import 'trip_detail_screen.dart';
import 'widgets/trip_editor_sheet.dart';

/// Every trip of the season, grouped by what part of it they are.
///
/// The counter on each row is the number the room lives by: a flight is
/// interesting when it is full and alarming when it is empty two days out. It
/// counts LIVE legs only — people moved off a flight are kept in the table
/// precisely so that nobody has to delete them to make this figure right.
class TripsBoardScreen extends StatelessWidget {
  const TripsBoardScreen({super.key, this.seasonId});

  final String? seasonId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TripsCubit(TravelRepository(), seasonId: seasonId),
    child: const _View(),
  );
}

class _View extends StatelessWidget {
  const _View();

  Future<void> _create(BuildContext context) async {
    final cubit = context.read<TripsCubit>();
    final draft = await showTripEditorSheet(
      context,
      points: cubit.state.points,
    );
    if (draft == null) return;
    final id = await cubit.create(draft);
    if (id == null || !context.mounted) return;
    // Straight into the new trip, because entering a flight and then putting
    // people on it is one errand, not two.
    await Navigator.of(
      context,
    ).push(fadeThroughRoute((_) => TripDetailScreen(tripId: id)));
    if (context.mounted) await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = context.watch<SessionCubit>().state;
    final canEdit = session.can(PermissionCodes.travelEdit);

    return Scaffold(
      appBar: GlassAppBar(
        title: Text(l.travelTripsTitle),
        actions: [
          IconButton(
            tooltip: l.travelGapsTitle,
            icon: const Icon(AppIcons.warning),
            onPressed: () => Navigator.of(
              context,
            ).push(fadeThroughRoute((_) => const TravelGapsScreen())),
          ),
        ],
      ),
      floatingActionButton: canEdit
          ? CreateFab(label: l.travelNewTrip, onPressed: () => _create(context))
          : null,
      body: SafeArea(
        child: BlocConsumer<TripsCubit, TripsState>(
          listenWhen: (p, c) => c.error != null && p.error != c.error,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(friendlyError(context, state.error))),
              );
          },
          builder: (context, state) {
            final cubit = context.read<TripsCubit>();

            return ResponsivePage(
              builder: (context, size) => Column(
                children: [
                  SearchFilterBar(
                    hint: l.commonSearch,
                    onChanged: cubit.search,
                    filters: _Filters(state: state, cubit: cubit),
                  ),
                  Expanded(
                    child: switch (state.status) {
                      TripsStatus.loading => const SkeletonList(height: 84),
                      TripsStatus.error => EmptyState(
                        icon: AppIcons.warning,
                        title: friendlyError(context, state.error),
                      ),
                      TripsStatus.ready when state.trips.isEmpty => EmptyState(
                        icon: AppIcons.travel,
                        title: l.travelNoTrips,
                        message: l.travelNoTripsHint,
                      ),
                      TripsStatus.ready when state.filtered.isEmpty =>
                        EmptyState(
                          icon: AppIcons.travel,
                          title: l.travelNoTripsMatch,
                        ),
                      TripsStatus.ready => _Board(
                        grouped: state.grouped,
                        gutter: size.gutter,
                      ),
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.state, required this.cubit});

  final TripsState state;
  final TripsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final role in LegRole.values)
          FilterChip(
            selected: state.role == role,
            onSelected: (_) => cubit.filterRole(role),
            label: Text(legRoleLabel(context, role)),
            visualDensity: VisualDensity.compact,
          ),
        if (state.isNarrowed)
          TextButton.icon(
            onPressed: cubit.clearFilters,
            icon: const Icon(AppIcons.reject, size: 16),
            label: Text(l.moduleRosterClear),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
      ],
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.grouped, required this.gutter});

  final Map<LegRole, List<Trip>> grouped;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    final entries = grouped.entries.toList();

    // The same sectioned grid the rest of the app lists things with: one column
    // on a phone, three or four on the operations-room desktop, and the columns
    // counted once for the whole board so a heading never re-flows the cards
    // under it.
    return AdaptiveGridView.sectioned(
      padding: EdgeInsets.fromLTRB(
        gutter,
        AppSpacing.sm,
        gutter,
        AppSpacing.xxl * 2 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      spacing: AppSpacing.sm,
      sections: [
        for (final entry in entries)
          GridSection(
            header: SectionHeader(
              legRoleLabel(context, entry.key),
              icon: legRoleIcon(entry.key),
            ),
            itemCount: entry.value.length,
            itemBuilder: (context, i) => _TripCard(trip: entry.value[i]),
          ),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final accent = legRoleAccent(trip.role).of(context);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => Navigator.of(
        context,
      ).push(fadeThroughRoute((_) => TripDetailScreen(tripId: trip.id))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Icon(travelModeIcon(trip.mode), size: 20, color: accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${trip.fromPoint.of(context)} ← '
                        '${trip.toPoint.of(context)}',
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trip.status != TripStatus.scheduled) ...[
                      const SizedBox(width: AppSpacing.sm),
                      GlassBadge(
                        label: tripStatusLabel(context, trip.status),
                        color: tripStatusColor(context, trip.status),
                        dense: true,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    travelWhen(context, trip.plannedDepartureAt),
                    if (trip.label != null) trip.label!,
                  ].join(' · '),
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l.travelAssignedCount(trip.assignedCount),
                style: text.labelMedium?.copyWith(
                  color: trip.assignedCount == 0
                      ? scheme.onSurfaceVariant
                      : accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (trip.assignedCount > 0)
                Text(
                  l.travelConfirmedOf(trip.completedCount, trip.assignedCount),
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const NavChevron(),
        ],
      ),
    );
  }
}
