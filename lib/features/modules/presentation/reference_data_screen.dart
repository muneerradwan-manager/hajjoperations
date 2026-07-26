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
import '../data/modules_repository.dart';
import '../domain/reference_item.dart';
import 'reference_set_screen.dart';

/// The admin-managed lists that back every dropdown in a module — hotels,
/// clusters, cities, and whatever a future module type needs. Each list carries
/// its own item shape, so one screen manages all of them.
class ReferenceDataScreen extends StatelessWidget {
  const ReferenceDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReferenceDataCubit(ModulesRepository()),
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
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(title: Text(l.referenceDataTitle)),
      body: BlocBuilder<ReferenceDataCubit, ReferenceDataState>(
        builder: (context, state) {
          if (state.status == ReferenceDataStatus.loading) {
            return const SkeletonList();
          }
          if (state.status == ReferenceDataStatus.error) {
            return EmptyState(
              icon: AppIcons.referenceData,
              title: state.error ?? '',
              action: FilledButton(
                onPressed: () => context.read<ReferenceDataCubit>().load(),
                child: Text(l.commonRetry),
              ),
            );
          }
          if (state.sets.isEmpty) {
            return EmptyState(
              icon: AppIcons.referenceData,
              title: l.referenceEmpty,
            );
          }

          return ResponsiveCenter(
            child: RefreshIndicator(
              onRefresh: () => context.read<ReferenceDataCubit>().load(),
              child: ListView(
                padding: context.scrollPadding(),
                children: staggered([
                  for (final set in state.sets) ...[
                    _SetCard(set: set),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SetCard extends StatelessWidget {
  const _SetCard({required this.set});

  final ReferenceSet set;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      blur: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: () {
        final cubit = context.read<ReferenceDataCubit>();
        Navigator.of(context).push(
          fadeThroughRoute(
            (_) => BlocProvider.value(
              value: cubit,
              child: ReferenceSetScreen(setId: set.id),
            ),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              AppIcons.referenceData,
              size: 20,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  set.name.of(context),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l.referenceItemsCount(set.items.length),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
