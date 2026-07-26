import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/states.dart';
import '../../profile/domain/profile.dart';
import '../application/approval_cubit.dart';
import '../data/approval_repository.dart';
import 'approval_detail_screen.dart';

class ApprovalQueueScreen extends StatelessWidget {
  const ApprovalQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ApprovalCubit(ApprovalRepository()),
      child: const _ApprovalQueueView(),
    );
  }
}

class _ApprovalQueueView extends StatelessWidget {
  const _ApprovalQueueView();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text(l.approvalQueueTitle),
        actions: [
          // Surfaces the size of the queue without opening a card.
          BlocBuilder<ApprovalCubit, ApprovalState>(
            buildWhen: (p, c) => p.pending.length != c.pending.length,
            builder: (context, state) => state.pending.isEmpty
                ? const SizedBox(width: AppSpacing.sm)
                : Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: Center(
                      child: GlassBadge(
                        label: '${state.pending.length}',
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: BlocConsumer<ApprovalCubit, ApprovalState>(
        listenWhen: (p, c) => c.error != null && p.error != c.error,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.error!)));
        },
        builder: (context, state) {
          if (state.status == ApprovalStatus.loading) {
            return const SkeletonList(count: 5, height: 84);
          }
          if (state.pending.isEmpty) {
            return EmptyState(
              icon: AppIcons.emptyInbox,
              title: l.approvalEmpty,
            );
          }
          return RefreshIndicator(
            onRefresh: () => context.read<ApprovalCubit>().load(),
            child: ResponsiveCenter(
              child: ListView.separated(
                padding: context.scrollPadding(),
                itemCount: state.pending.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, i) {
                  final p = state.pending[i];
                  return FadeSlideIn(
                    delay: Duration(milliseconds: 40 * (i < 8 ? i : 8)),
                    child: _PendingCard(
                      profile: p,
                      processing: state.processingIds.contains(p.id),
                      onTap: () => _openDetail(context, p),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _openDetail(BuildContext context, Profile profile) {
    final cubit = context.read<ApprovalCubit>();
    Navigator.of(context).push(
      fadeThroughRoute(
        (_) => BlocProvider.value(
          value: cubit,
          child: ApprovalDetailScreen(profile: profile),
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.profile,
    required this.processing,
    required this.onTap,
  });

  final Profile profile;
  final bool processing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Opacity(
      // A row being decided dims so it reads as temporarily locked.
      opacity: processing ? 0.55 : 1,
      child: GlassCard(
        onTap: processing ? null : onTap,
        blur: false,
        tint: scheme.secondary,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            ProfileAvatar(
              photoUrl: profile.photoUrl,
              name: profile.fullName,
              radius: 26,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName.isEmpty ? '—' : profile.fullName,
                    style: text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (profile.jobTitleName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      profile.jobTitleName!,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  GlassBadge(
                    label: context.l10n.approvalQueueTitle,
                    color: scheme.secondary,
                    icon: AppIcons.pending,
                    dense: true,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (processing)
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  strokeCap: StrokeCap.round,
                  color: scheme.primary,
                ),
              )
            else
              const NavChevron(),
          ],
        ),
      ),
    );
  }
}
