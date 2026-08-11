import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/error_text.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../application/incidents_cubit.dart';
import '../data/incidents_repository.dart';
import '../domain/incident.dart';

/// The operations room's register.
///
/// Ordered OLDEST FIRST among the open ones, which is the opposite of every
/// other list in this app and is the whole point: an emergency that has been
/// sitting for forty minutes matters more than one raised a moment ago, and
/// putting the newest on top is exactly how the old one is never looked at
/// again.
class IncidentsScreen extends StatelessWidget {
  const IncidentsScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => IncidentsCubit(IncidentsRepository()),
    child: const _IncidentsView(),
  );
}

class _IncidentsView extends StatelessWidget {
  const _IncidentsView();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      appBar: GlassAppBar(title: Text(l.incidentsTitle)),
      body: BlocBuilder<IncidentsCubit, IncidentsState>(
        builder: (context, state) {
          if (state.status == IncidentsStatus.loading) {
            return const SkeletonList(height: 168);
          }
          if (state.status == IncidentsStatus.error) {
            return EmptyState(
              icon: AppIcons.warning,
              title: friendlyError(context, state.error),
            );
          }

          // ResponsivePage caps the column on a monitor, and SinglePaneLayout's
          // padding comes from `context.scrollPadding` — which adds the
          // window's own bottom viewPadding. That is what keeps the last card
          // clear of the Android 15 gesture bar, where edge-to-edge is no
          // longer opt-in and a hard-coded padding puts content underneath it.
          return ResponsivePage(
            builder: (context, size) => SinglePaneLayout(
              gutter: size.gutter,
              onRefresh: () => context.read<IncidentsCubit>().load(),
              children: [
                // Held to a width a switch row can actually be read at. A
                // ListTile puts its label at one end and its control at the
                // other, which is right on a phone and absurd at 1680 — the
                // word and the thing it governs end up a hand's width apart
                // with nothing between them.
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.incidentsShowClosed),
                      value: state.includeClosed,
                      onChanged: context
                          .read<IncidentsCubit>()
                          .setIncludeClosed,
                    ),
                  ),
                ),
                if (state.incidents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxl),
                    child: EmptyState(
                      icon: AppIcons.warning,
                      title: l.incidentsEmpty,
                      message: l.incidentsEmptyHint,
                    ),
                  ),
                // Columned like every other list in this app, and this is the
                // screen that gains most by it. An incident card is a state
                // chip, two short lines and a row of buttons; one to a row on a
                // monitor stretched each of them across a metre of glass and
                // fitted four emergencies on a screen that had room for a
                // dozen. In an operations room, how many of these are visible
                // at once IS the feature.
                //
                // Row-major, so the oldest is still first: the register is
                // ordered oldest-first on purpose — an emergency that has been
                // sitting forty minutes outranks one raised a moment ago — and
                // reading order carries that across the columns unchanged.
                AdaptiveGrid(
                  children: [
                    for (final incident in state.incidents)
                      _IncidentCard(incident: incident),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// "40 د" / "3 س". Short because it sits beside a name on a crowded card, and
/// what matters is the order of magnitude, not the seconds.
String waitedLabel(AppLocalizations l, Duration waited) {
  final minutes = waited.inMinutes;
  if (minutes < 60) return l.durationMinutes(minutes < 0 ? 0 : minutes);
  return l.durationHours(waited.inHours);
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident});
  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final cubit = context.read<IncidentsCubit>();

    final stateLabel = switch (incident.state) {
      IncidentState.open => l.incidentStateOpen,
      IncidentState.inProgress => l.incidentStateInProgress,
      IncidentState.closed => l.incidentStateClosed,
    };

    // Colour carries the state at a glance. An open emergency is the only thing
    // in this app drawn in the error colour without being an error.
    final accent = switch (incident.state) {
      IncidentState.open => scheme.error,
      IncidentState.inProgress => scheme.tertiary,
      IncidentState.closed => scheme.onSurfaceVariant,
    };

    // No bottom padding of its own any more: the grid above spaces its rows,
    // and a card carrying its own margin inside a grid cell puts a gap under
    // every card in a row except the tallest one.
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    stateLabel,
                    style: text.labelSmall?.copyWith(color: accent),
                  ),
                ),
                const Spacer(),
                if (!incident.state.isClosed)
                  Text(
                    l.incidentWaited(waitedLabel(l, incident.waited)),
                    style: text.bodySmall?.copyWith(color: accent),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(incident.body, style: text.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              [
                incident.reporterName,
                // The most specific place it knows: the tower if there is
                // one, otherwise the file, otherwise nothing at all.
                ?(incident.nodeLabel ?? incident.moduleName),
              ].join(' · '),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (incident.handledByName case final name?
                when name.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  l.incidentHandledBy(name),
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                // The telephone first. Everything else on this card is
                // context; this is the action.
                if (incident.reporterPhone case final phone?
                    when phone.trim().isNotEmpty)
                  TextButton.icon(
                    onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                    icon: const Icon(AppIcons.phoneSy, size: 16),
                    label: Text(l.incidentCall),
                  ),
                if (incident.mapUrl case final url?)
                  TextButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(AppIcons.checkIn, size: 16),
                    label: Text(l.incidentOpenMap),
                  ),
                if (incident.state.isOpen)
                  FilledButton.tonal(
                    onPressed: () =>
                        cubit.setState(incident, IncidentState.inProgress),
                    child: Text(l.incidentTake),
                  ),
                if (incident.state == IncidentState.inProgress)
                  FilledButton.tonal(
                    onPressed: () =>
                        cubit.setState(incident, IncidentState.closed),
                    child: Text(l.incidentClose),
                  ),
                if (incident.state.isClosed)
                  TextButton(
                    onPressed: () =>
                        cubit.setState(incident, IncidentState.open),
                    child: Text(l.incidentReopen),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
