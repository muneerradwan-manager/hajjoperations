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
      body: Builder(
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
                    ],
                  ),
                  InfoSection(
                    title: l.navNotifications,
                    icon: AppIcons.notifications,
                    children: [
                      _NotificationsSwitch(
                        value: state.notificationsEnabled,
                        onChanged: settings.setNotificationsEnabled,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // The prayer panes, in the same first column as the accounts
              // below them. They are a column of their own rather than two more
              // cells of the grid above because the second one only makes sense
              // under the first, and a grid is free to put them on separate
              // rows a screen apart.
              const AdaptiveGrid(
                minTileWidth: 320,
                maxColumns: 3,
                children: [PrayerAlertsSections()],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Alone on its row, but measured by the same grid as the panes
              // above so it lands in the first column rather than across the
              // whole monitor. An account row is a face, a name and one icon;
              // at 1600 wide the name and the icon end up in different
              // postcodes with a metre of glass between them.
              const AdaptiveGrid(
                minTileWidth: 320,
                maxColumns: 3,
                children: [_AccountsSection()],
              ),
              const SizedBox(height: AppSpacing.lg),
              // A button is as wide as the words on it plus room to hit it.
              // The cap only bites on a wide window — a phone is narrower than
              // this, so there it still spans the column the way it always has.
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: SizedBox(
                    width: double.infinity,
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
/// The notifications switch, written as a plain row rather than as a
/// [SwitchListTile].
///
/// A ListTile measures its title and subtitle at the tile's FULL width and then
/// lays them out at the width the trailing switch leaves over — so the hint
/// wraps to one more line than the measurement allowed for. Inside the settings
/// grid, where the three panes are given a shared height taken from exactly that
/// measurement, the pane then overflows by those few pixels. Here the switch is
/// an inflexible child of the row, so both passes see the same text width.
class _NotificationsSwitch extends StatelessWidget {
  const _NotificationsSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
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
                  Text(l.settingsNotifications, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 3),
                  // Said plainly, because the switch does less than it looks
                  // like it does: the message still arrives, the phone just
                  // stays quiet about it.
                  Text(
                    l.settingsNotificationsHint,
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
