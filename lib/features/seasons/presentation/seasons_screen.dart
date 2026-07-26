import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/states.dart';
import '../../auth/application/session_cubit.dart';
import '../application/seasons_cubit.dart';
import '../data/seasons_repository.dart';
import '../domain/season.dart';
import 'season_detail_screen.dart';

class SeasonsScreen extends StatelessWidget {
  const SeasonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<SessionCubit>().state.isAdmin;
    return BlocProvider(
      create: (_) => SeasonsCubit(SeasonsRepository(), isAdmin: isAdmin),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      // Extended behind the bar so the list frosts as it scrolls under it.
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(title: Text(l.seasonsTitle)),
      body: ResponsiveCenter(
        child: BlocConsumer<SeasonsCubit, SeasonsState>(
          listenWhen: (p, c) => c.error != null && p.error != c.error,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.error!)));
          },
          builder: (context, state) {
            if (state.status == SeasonsStatus.loading) {
              return const SkeletonList(count: 4, height: 88);
            }
            return RefreshIndicator(
              onRefresh: () => context.read<SeasonsCubit>().load(),
              child: ListView(
                padding: context.scrollPadding(),
                children: staggered([
                  if (state.current != null) ...[
                    SectionHeader(l.seasonCurrentLabel, icon: AppIcons.current),
                    _CurrentSeasonCard(
                      season: state.current!,
                      onTap: () => _open(context, state.current!),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  // Only shown when it has rows: a season later than the
                  // current one exists whenever an earlier one is pinned.
                  if (state.upcoming.isNotEmpty) ...[
                    SectionHeader(
                      l.seasonUpcomingLabel,
                      icon: AppIcons.seasons,
                    ),
                    ...state.upcoming.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _SeasonTile(
                          season: s,
                          onTap: () => _open(context, s),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  SectionHeader(l.seasonArchiveLabel, icon: AppIcons.seasons),
                  if (state.archive.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xl),
                      child: EmptyState(
                        icon: AppIcons.seasons,
                        title: l.seasonArchiveEmpty,
                      ),
                    )
                  else
                    ...state.archive.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _SeasonTile(
                          season: s,
                          onTap: () => _open(context, s),
                        ),
                      ),
                    ),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }

  void _open(BuildContext context, Season season) {
    final cubit = context.read<SeasonsCubit>();
    Navigator.of(context).push(
      fadeThroughRoute(
        (_) => BlocProvider.value(
          value: cubit,
          child: SeasonDetailScreen(season: season),
        ),
      ),
    );
  }
}

/// The hero of the screen: the season currently under way. Rendered as a
/// gold-washed pane with a luminous medallion so it clearly outranks the
/// archive rows below it.
class _CurrentSeasonCard extends StatelessWidget {
  const _CurrentSeasonCard({required this.season, required this.onTap});

  final Season season;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = context.l10n;

    return GlassCard(
      onTap: onTap,
      radius: AppRadius.xl,
      tint: scheme.secondary,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.goldSphere,
              boxShadow: [
                BoxShadow(
                  color: scheme.secondary.withValues(alpha: 0.4),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            // Dark ink, not white: the gold sphere is a light surface.
            child: const Icon(AppIcons.current, color: AppColors.ink, size: 28),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassBadge(
                  label: l.seasonCurrentLabel,
                  color: scheme.secondary,
                  dense: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l.seasonHijriYear(season.hijriYear),
                  style: text.headlineSmall,
                ),
                if (season.gregorianLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    season.gregorianLabel!,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
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

/// A season row in either list below the hero — upcoming or previous.
class _SeasonTile extends StatelessWidget {
  const _SeasonTile({required this.season, required this.onTap});

  final Season season;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = context.l10n;

    return GlassCard(
      onTap: onTap,
      // Repeated list item: skip the backdrop blur to keep scrolling smooth.
      blur: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          GlassSurface(
            radius: AppRadius.sm,
            width: 44,
            height: 44,
            blur: false,
            shadow: false,
            subtle: true,
            child: Icon(AppIcons.seasons, size: 20, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.seasonHijriYear(season.hijriYear),
                  style: text.titleMedium,
                ),
                if (season.gregorianLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    season.gregorianLabel!,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
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
