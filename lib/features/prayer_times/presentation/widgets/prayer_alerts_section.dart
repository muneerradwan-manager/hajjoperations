import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_accents.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/glass_tokens.dart';
import '../../../../core/widgets/info_section.dart';
import '../../application/prayer_alerts_cubit.dart';
import '../../data/prayer_notifications.dart';
import '../../domain/prayer_alerts.dart';
import '../../domain/prayer_day.dart';
import '../../domain/prayer_text.dart';

/// The settings page's prayer panes: what the phone announces, and what it
/// draws on the home screen.
///
/// Two panes rather than one because they are two different promises. The
/// alerts need a permission, a position and the reader's leave; the widget
/// needs none of the three — it is astronomy on a launcher and it works whether
/// or not anything is switched on above it.
class PrayerAlertsSections extends StatelessWidget {
  const PrayerAlertsSections({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PrayerAlertsCubit(),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AlertsSection(),
          SizedBox(height: AppSpacing.lg),
          _WidgetSection(),
        ],
      ),
    );
  }
}

class _AlertsSection extends StatelessWidget {
  const _AlertsSection();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cubit = context.read<PrayerAlertsCubit>();
    final state = context.watch<PrayerAlertsCubit>().state;
    final alerts = state.alerts;

    return InfoSection(
      title: l.prayerAlertsTitle,
      icon: AppIcons.prayerTimes,
      // One column: this pane is a switch followed by things that only make
      // sense underneath it, and a grid would set the answers beside the
      // question they belong to.
      maxColumns: 1,
      children: [
        SwitchListTile(
          value: alerts.enabled,
          contentPadding: EdgeInsets.zero,
          title: Text(l.prayerAlertsEnable),
          subtitle: _hint(context, l.prayerAlertsHint),
          onChanged: state.loaded &&
                  state.readiness != PrayerAlertReadiness.unsupported
              ? cubit.setEnabled
              : null,
        ),

        // Everything below only exists while the switch is on. It is removed
        // rather than greyed out: a disabled row of five prayers invites the
        // reader to press it and learn nothing.
        if (alerts.enabled) ...[
          ?_notice(context, state),
          const SizedBox(height: AppSpacing.sm),
          _Label(l.prayerAlertsWhich),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final slot in PrayerSlot.values)
                if (slot.isPrayer)
                  FilterChip(
                    label: Text(slotName(l, slot)),
                    selected: alerts.announcing(slot),
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => cubit.toggleSlot(slot),
                  ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Label(l.prayerAlertsBefore),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final minutes in PrayerAlerts.reminderChoices)
                ChoiceChip(
                  label: Text(
                    minutes == 0
                        ? l.prayerAlertsBeforeOff
                        : l.prayerAlertsMinutes(minutes),
                  ),
                  selected: alerts.reminderMinutes == minutes,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => cubit.setReminderMinutes(minutes),
                ),
            ],
          ),
          SwitchListTile(
            value: alerts.silent,
            contentPadding: EdgeInsets.zero,
            title: Text(l.prayerAlertsSilent),
            subtitle: _hint(context, l.prayerAlertsSilentHint),
            onChanged: cubit.setSilent,
          ),
        ],
      ],
    );
  }

  /// The one thing standing between this switch and a phone that actually goes
  /// off, when there is one. At most one is ever shown, worst first.
  Widget? _notice(BuildContext context, PrayerAlertsState state) {
    final l = context.l10n;
    return switch (state.readiness) {
      PrayerAlertReadiness.blocked => _Notice(
        message: l.prayerAlertsBlocked,
        tone: Accent.red.of(context),
      ),
      PrayerAlertReadiness.unsupported => _Notice(
        message: l.prayerAlertsUnsupported,
        tone: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      // A position is worth more than an exact alarm: without one nothing is
      // announced at all, where an inexact alarm is only late.
      _ when !state.locatable => _Notice(
        message: l.prayerAlertsNeedLocation,
        tone: Accent.gold.of(context),
      ),
      PrayerAlertReadiness.inexact => _Notice(
        message: l.prayerAlertsInexact,
        tone: Accent.gold.of(context),
        action: l.prayerAlertsGrantExact,
        onAction: context.read<PrayerAlertsCubit>().grantExactAlarms,
      ),
      PrayerAlertReadiness.ready => null,
    };
  }
}

/// The home-screen widget: what it is, and the way to put one there.
class _WidgetSection extends StatelessWidget {
  const _WidgetSection();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = context.watch<PrayerAlertsCubit>().state;

    return InfoSection(
      title: l.prayerWidgetTitle,
      icon: AppIcons.prayerSunrise,
      maxColumns: 1,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.prayerWidgetHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.prayerWidgetInstalled(state.widgets),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: state.widgets > 0
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const _AddWidgetButton(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Asks the launcher to run its own pin dialog, and falls back to telling the
/// reader how to do it by hand — which is the only answer on a launcher that
/// has no such dialog, and there are many.
class _AddWidgetButton extends StatelessWidget {
  const _AddWidgetButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final l = context.l10n;
        final messenger = ScaffoldMessenger.of(context);
        final pinned = await context.read<PrayerAlertsCubit>().addWidget();
        if (pinned) return;
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l.prayerWidgetAddManually)));
      },
      icon: const Icon(AppIcons.add),
      label: Text(context.l10n.prayerWidgetAdd),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// A line saying what will not work, and — where there is one — the button that
/// fixes it.
class _Notice extends StatelessWidget {
  const _Notice({
    required this.message,
    required this.tone,
    this.action,
    this.onAction,
  });

  final String message;
  final Color tone;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: tone.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.warning, size: 16, color: tone),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ),
            ],
          ),
          if (action != null)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: tone),
                child: Text(action!),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _hint(BuildContext context, String text) => Text(
  text,
  style: Theme.of(context).textTheme.bodySmall?.copyWith(
    color: Theme.of(context).colorScheme.onSurfaceVariant,
    height: 1.35,
  ),
);
