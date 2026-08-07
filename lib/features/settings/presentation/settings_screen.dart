import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/app_router.dart';
import '../../../core/settings/settings_cubit.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/blocking_progress.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/info_section.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/selection_indicator.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/saved_account.dart';
import '../../auth/presentation/widgets/saved_accounts_list.dart';
import '../../prayer_times/presentation/widgets/prayer_alerts_section.dart';

/// Everything about this device rather than about the mission: which language
/// it speaks, how it looks, whether it makes a noise, and the way out.
///
/// A page and not a menu — a dropdown could hold two of these, and it has four
/// with a switch and a destructive action among them.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final l = context.l10n;
    final auth = context.read<AuthRepository>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.commonLogout),
        content: Text(l.settingsLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.commonLogout),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await runBlocking(context, auth.signOut, message: l.commonLoggingOut);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = context.watch<SettingsCubit>();
    final state = settings.state;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(title: Text(l.commonSettings)),
      // Over the whole page rather than around the grid: the two prayer panes
      // are now separate cells of it, and they are two views of one state.
      body: PrayerAlertsScope(
        child: Builder(
          builder: (context) => ResponsivePage(
            builder: (context, size) => SinglePaneLayout(
              gutter: size.gutter,
              children: staggered([
                // Three independent settings, none of which needs to be read
                // before another — so on a wide window they stand side by side
                // rather than in a queue the length of the screen.
                AdaptiveGrid(
                  minTileWidth: 320,
                  maxColumns: 3,
                  children: [
                    InfoSection(
                      title: l.settingsLanguage,
                      icon: AppIcons.language,
                      children: [
                        _Choice(
                          label: l.languageArabic,
                          selected: state.locale?.languageCode == 'ar',
                          onTap: () => settings.setLocale(const Locale('ar')),
                        ),
                        _Choice(
                          label: l.languageEnglish,
                          selected: state.locale?.languageCode == 'en',
                          onTap: () => settings.setLocale(const Locale('en')),
                        ),
                        _Choice(
                          label: l.settingsLanguageSystem,
                          selected: state.locale == null,
                          onTap: () => settings.setLocale(null),
                        ),
                      ],
                    ),
                    InfoSection(
                      title: l.settingsTheme,
                      icon: AppIcons.theme,
                      children: [
                        for (final (mode, label) in <(ThemeMode, String)>[
                          (ThemeMode.system, l.themeSystem),
                          (ThemeMode.light, l.themeLight),
                          (ThemeMode.dark, l.themeDark),
                        ])
                          _Choice(
                            label: label,
                            selected: state.themeMode == mode,
                            onTap: () => settings.setThemeMode(mode),
                          ),
                        // Under the three, not beside them: it is not a fourth
                        // theme. It applies to whichever of the three is
                        // chosen — a man on a night shift under floodlights
                        // wants the glass gone as much as one at noon does,
                        // and a slow handset wants it gone at every hour.
                        _SettingSwitch(
                          title: l.settingsSolidSurfaces,
                          hint: l.settingsSolidSurfacesHint,
                          value: state.solidSurfaces,
                          onChanged: settings.setSolidSurfaces,
                        ),
                      ],
                    ),
                    InfoSection(
                      title: l.navNotifications,
                      icon: AppIcons.notifications,
                      children: [
                        _SettingSwitch(
                          title: l.settingsNotifications,
                          hint: l.settingsNotificationsHint,
                          value: state.notificationsEnabled,
                          onChanged: settings.setNotificationsEnabled,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // The second row, measured by the same grid as the first so the
                // two line up in the same columns.
                //
                // These were three panes in three separate one-child grids,
                // stacked. A one-child grid still counts its columns: each pane
                // took the FIRST of them and left the other two empty, so the
                // whole lower half of the page came out as a narrow ribbon down
                // one edge — the RIGHT edge in Arabic, where the first column is
                // — with two thirds of a monitor blank beside it. Handed to one
                // grid they fill the row instead.
                //
                // Still capped at three columns and 320 wide, which is the reason
                // they were kept out of the full width in the first place: an
                // account row is a face, a name and one icon, and at 1600 wide
                // the name and the icon end up in different postcodes.
                //
                // The order matters and survives every width: the widget pane
                // reads as a footnote to the alerts pane, and three cells in a
                // three-column grid can never fall far enough apart to break
                // that — at two columns they share a row, at one they are
                // adjacent.
                AdaptiveGrid(
                  minTileWidth: 320,
                  maxColumns: 3,
                  children: [
                    // Both prayer panes are dropped from the LIST on a platform
                    // that cannot run them, rather than hidden inside
                    // themselves: a pane that returned an empty box would still
                    // hold its column and put a hole in the row. On Windows
                    // this row is the accounts pane alone, which is the honest
                    // answer — the whole of what a desktop can be told here.
                    if (PrayerAlertsSection.available)
                      const PrayerAlertsSection(),
                    if (PrayerWidgetSection.available)
                      const PrayerWidgetSection(),
                    const _AccountsSection(),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // A button is as wide as the words on it plus room to hit it.
                //
                // Which takes saying twice, because the app's buttons claim
                // their parent's whole width by theme — `minimumSize` is a
                // `Size.fromHeight`, and that is an infinite minimum WIDTH. A
                // maximum alone could not answer it: capping the box at 360
                // only moved the far edge, and the button still ran out to meet
                // it, coming out the width of the panes above rather than the
                // width of "تسجيل الخروج". So the label is measured
                // ([IntrinsicWidth]) and given a floor, which is what
                // [EmptyState] does with its action for the same reason.
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 200),
                    child: IntrinsicWidth(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmLogout(context),
                        icon: const Icon(AppIcons.logout),
                        label: Text(l.commonLogout),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// The accounts this device holds, and the way to add another.
///
/// Switching is not signing out and back in: no session is ended, which is the
/// whole point — Supabase revokes a session the moment it is signed out, and a
/// revoked session cannot be reopened. The account being left keeps its own,
/// and comes back with a tap.
class _AccountsSection extends StatefulWidget {
  const _AccountsSection();

  @override
  State<_AccountsSection> createState() => _AccountsSectionState();
}

class _AccountsSectionState extends State<_AccountsSection> {
  String? _switching;

  Future<void> _switchTo(SavedAccount account) async {
    final l = context.l10n;
    final auth = context.read<AuthRepository>();

    setState(() => _switching = account.userId);
    try {
      await auth.switchTo(account);
      // Home, and explicitly. This page was pushed onto the session that has
      // just been left, and go_router does not re-decide a pushed route when
      // the session changes beneath it — without this, an account that is
      // pending approval would land on the settings page of an app it is not
      // yet allowed into. From `/` the ordinary redirect takes over and puts
      // them wherever their account belongs.
      if (mounted) context.go(Routes.home);
    } on AuthFailure {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.accountsExpired)));
    } finally {
      if (mounted) setState(() => _switching = null);
    }
  }

  Future<void> _confirmForget(SavedAccount account) async {
    final l = context.l10n;
    final auth = context.read<AuthRepository>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.accountsRemove),
        content: Text(l.accountsRemoveConfirm(account.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await auth.forgetAccount(account.userId);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final auth = context.read<AuthRepository>();
    final currentUserId = auth.currentUser?.id;
    if (currentUserId == null) return const SizedBox.shrink();

    return ValueListenableBuilder<List<SavedAccount>>(
      valueListenable: auth.accounts,
      builder: (context, accounts, _) => InfoSection(
        title: l.accountsTitle,
        icon: AppIcons.accounts,
        // One per line. These are rows and not fields — a card carries a face,
        // a name and an address, and three of them side by side is a contact
        // list nobody asked for.
        maxColumns: 1,
        // No rules. There are three children here — the list, a spacer, and
        // the button — so both of the hairlines this pane drew landed on either
        // side of the spacer: two lines eight pixels apart, fencing off a gap.
        // The list is one block and the button is an action on it; neither
        // wants to be ruled off from the other.
        separated: false,
        children: [
          SavedAccountsList(
            accounts: accounts,
            currentUserId: currentUserId,
            busyUserId: _switching,
            onSelect: _switchTo,
            onForget: _confirmForget,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            // The current session is deliberately left running: the sign-in
            // screen replaces it when the second account arrives, and until
            // then backing out costs nothing.
            onPressed: _switching != null
                ? null
                : () => context.push('${Routes.login}?add=$currentUserId'),
            icon: const Icon(AppIcons.addUser),
            label: Text(l.accountsAdd),
          ),
        ],
      ),
    );
  }
}

/// One option in a group. Language and theme each take a single answer, so the
/// indicator is round and only one of them is ever filled.
/// A titled switch with a line of explanation, written as a plain row rather
/// than as a [SwitchListTile].
///
/// A ListTile measures its title and subtitle at the tile's FULL width and then
/// lays them out at the width the trailing switch leaves over — so the hint
/// wraps to one more line than the measurement allowed for. Inside the settings
/// grid, where the three panes are given a shared height taken from exactly that
/// measurement, the pane then overflows by those few pixels. Here the switch is
/// an inflexible child of the row, so both passes see the same text width.
///
/// Both switches on this screen need the same thing said about them: what they
/// do is not obvious from the title alone. Push still ARRIVES when it is off —
/// the phone simply stays quiet — and solid surfaces is not a taste, it is what
/// to press when the screen is unreadable in the sun.
class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.title,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 3),
                  Text(
                    hint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SelectionRow(label: label, selected: selected, onTap: onTap);
  }
}
