import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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

/// Who is where in this file, as of the last few hours.
///
/// The one question the operations room has never been able to ask. It shows
/// the LATEST arrival per person per place — "where is he", not "everywhere he
/// has been today", which is a different question and a longer list.
class PresenceScreen extends StatelessWidget {
  const PresenceScreen({super.key, required this.moduleId});

  final String moduleId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => PresenceCubit(CheckInRepository(), moduleId),
    child: const _PresenceView(),
  );
}

class _PresenceView extends StatelessWidget {
  const _PresenceView();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      appBar: GlassAppBar(title: Text(l.presenceTitle)),
      body: BlocBuilder<PresenceCubit, PresenceState>(
        builder: (context, state) {
          if (state.status == PresenceStatus.loading) {
            return const SkeletonList();
          }
          if (state.status == PresenceStatus.error) {
            return EmptyState(
              icon: AppIcons.warning,
              title: friendlyError(context, state.error),
            );
          }
          if (state.lines.isEmpty) {
            return EmptyState(
              icon: AppIcons.checkIn,
              title: l.presenceEmpty,
              message: l.presenceEmptyHint,
            );
          }

          final suspect = state.suspect.length;

          return ResponsivePage(
            builder: (context, size) => SinglePaneLayout(
              gutter: size.gutter,
              onRefresh: () => context.read<PresenceCubit>().load(),
              children: [
                // Said at the top, and only when there is something to say. A
                // banner that is always there is a banner nobody reads on the
                // day it finally means something.
                if (suspect > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _SuspectBanner(count: suspect),
                  ),
                for (final line in state.lines) _PresenceCard(line: line),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SuspectBanner extends StatelessWidget {
  const _SuspectBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(AppIcons.warning, size: 18, color: scheme.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.presenceSuspectCount(count),
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresenceCard extends StatelessWidget {
  const _PresenceCard({required this.line});
  final PresenceLine line;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final method = switch (line.method) {
      CheckInMethod.qr => l.checkInMethodQr,
      CheckInMethod.gps => l.checkInMethodGps,
      CheckInMethod.manual => l.checkInMethodManual,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(line.fullName, style: text.titleSmall),
                  ),
                  Text(
                    DateFormat.jm().format(line.createdAt),
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${line.nodeLabel ?? l.checkInPlaceUnknown} · $method',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  // Never "0 m" for an unknown distance — that would invent a
                  // confirmation nobody made. See PresenceLine.distanceM.
                  line.distanceM == null
                      ? l.checkInDistanceUnknown
                      : l.checkInDistance(line.distanceM!.round().toString()),
                  style: text.bodySmall?.copyWith(
                    color: line.isFarFromPlace
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (line.isFarFromPlace)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Row(
                    children: [
                      Icon(AppIcons.warning, size: 14, color: scheme.error),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          l.checkInFarFromPlace,
                          style: text.bodySmall?.copyWith(color: scheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              if (line.note case final note? when note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(note, style: text.bodySmall),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
