import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_accents.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/glass_tokens.dart';
import '../../../../core/widgets/info_section.dart';
import '../../application/prayer_alerts_cubit.dart';
import '../../data/prayer_notifications.dart';
import '../../data/prayer_widget_bridge.dart';
import '../../domain/prayer_alerts.dart';
import '../../domain/prayer_day.dart';
import '../../domain/prayer_text.dart';

/// Puts one [PrayerAlertsCubit] over everything below it.
///
/// The two panes below are separate widgets rather than a fixed column, so the
/// page laying them out is free to stand them side by side on a wide window
/// instead of queueing them down one. But they are two views of ONE state — the
/// switch, the chosen prayers, how many widgets are placed — so they cannot
/// each carry their own cubit. This is what lets them be placed independently
/// and still agree.
class PrayerAlertsScope extends StatelessWidget {
  const PrayerAlertsScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => PrayerAlertsCubit(), child: child);
}

/// What the phone announces: the switch, which prayers, and how long before.
///
/// One of the settings page's two prayer panes — [PrayerWidgetSection] is the
/// other. Two panes rather than one because they are two different promises:
/// the alerts need a permission, a position and the reader's leave; the widget
/// needs none of the three — it is astronomy on a launcher and it works whether
/// or not anything is switched on above it.
///
/// Must sit under a [PrayerAlertsScope], and only where [available].
class PrayerAlertsSection extends StatelessWidget {
  const PrayerAlertsSection({super.key});

  /// Whether this platform can announce a prayer at all.
  ///
  /// Dropped rather than shown-and-explained, the same as
  /// [PrayerWidgetSection.available]: a pane whose every control is dead is not
  /// made honest by a line of text under it, it is just a dead pane with a
  /// caption. A reader on Windows is better served by a settings page that
  /// offers only what Windows can do.
  ///
  /// Pure, and asked before the pane is built — see
  /// [PrayerNotifications.supported].
  static bool get available => PrayerNotifications.supported;

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
      // And no rules between them, for the same reason. At one column every
      // child below is its own row, so the pane came out with a hairline
      // between the master switch and the notice under it, between each label
      // and the chips it labels, and on both sides of the two spacers — seven
      // lines through what is one continuous setting.
      separated: false,
      children: [
        SwitchListTile(
          value: alerts.enabled,
          contentPadding: EdgeInsets.zero,
          title: Text(l.prayerAlertsEnable),
          subtitle: _hint(context, l.prayerAlertsHint),
          onChanged:
              state.loaded &&
                  state.readiness != PrayerAlertReadiness.unsupported
              ? cubit.setEnabled
              : null,
        ),

        // Said whether or not the switch is on, and the only notice that is.
        //
        // Where the system cannot announce anything the switch can never BE on
        // — [PrayerAlertsCubit.setEnabled] forces it back off — so a line shown
        // only underneath a live switch is one nobody in that state can ever
        // read. A platform that cannot do this at all does not reach here now
        // ([available] keeps the whole pane off the page); what is left for
        // this line is the device that says it is Android and then resolves no
        // plugin, which would otherwise be a switch that bounces in silence.
        if (state.readiness == PrayerAlertReadiness.unsupported)
          _Notice(
            message: l.prayerAlertsUnsupported,
            tone: Theme.of(context).colorScheme.onSurfaceVariant,
          ),

        // Everything below only exists while the switch is on. It is removed
        // rather than greyed out: a disabled row of five prayers invites the
        // reader to press it and learn nothing.
        if (alerts.enabled) ...[
          ?_notice(context, state),
          const SizedBox(height: AppSpacing.sm),
          _Label(l.prayerAlertsWhich), //
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
      // Shown above the switch instead of under it, because it is the one
      // notice that has to survive the switch being off. See the note there.
      PrayerAlertReadiness.unsupported => null,
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
///
/// The settings page's other prayer pane — see [PrayerAlertsSection]. Must sit
/// under a [PrayerAlertsScope], and only where [available].
class PrayerWidgetSection extends StatelessWidget {
  const PrayerWidgetSection({super.key});

  /// Whether this pane has anything to say on this platform.
  ///
  /// It is dropped rather than explained, which is the opposite of what the
  /// alerts pane beside it does — and the difference is what the pane IS. That
  /// one is a setting a reader may come looking for, so on Windows it stays and
  /// says why it is off. This one is not a setting at all: it is an instruction
  /// to go and place a widget on a launcher, and a desktop has no launcher to
  /// place it on. There is no question here to answer, only a button that could
  /// not work.
  ///
  /// Asked by the PAGE rather than answered with an empty widget from [build]:
  /// an empty cell still claims a column of the settings grid, so a pane that
  /// hid itself would leave a hole in the row instead of closing it.
  static bool get available => PrayerWidgetBridge.supported;

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
              // Once there is a widget on the home screen the offer to add one
              // is withdrawn, and what is left is a plain statement that it is
              // there. The button used to stay regardless, which asked the
              // reader to decide whether pressing it again would add a second
              // copy or was simply the thing they had already done.
              //
              // Nothing at all until the count is known. It is one frame off
              // disk, and drawing the button in it would show the offer to
              // somebody who has a widget already and then snatch it away.
              if (!state.loaded)
                const SizedBox.shrink()
              else if (state.widgets > 0)
                _AddedNote(count: state.widgets)
              else
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

/// What stands where the button was, once there is a widget to speak of.
///
/// A statement and not a control: there is nothing left to press here, and the
/// count is carried in the sentence itself rather than beside it — the string
/// already says "مُضافة" for one and "مُضافة، ٣ نسخ" for more, so a reader who
/// has two on two home screens is told so without a number floating on its own.
class _AddedNote extends StatelessWidget {
  const _AddedNote({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final tone = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.selected, size: 17, color: tone),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            context.l10n.prayerWidgetInstalled(count),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: tone,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
