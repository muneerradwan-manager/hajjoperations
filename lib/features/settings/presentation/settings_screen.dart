import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/settings/settings_cubit.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/blocking_progress.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/info_section.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/selection_indicator.dart';
import '../../auth/data/auth_repository.dart';

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
        builder: (context) => ResponsiveCenter(
          child: ListView(
            padding: context.scrollPadding(),
            children: staggered([
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
              const SizedBox(height: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.md),
              InfoSection(
                title: l.navNotifications,
                icon: AppIcons.notifications,
                children: [
                  SwitchListTile(
                    value: state.notificationsEnabled,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.settingsNotifications),
                    // Said plainly, because the switch does less than it looks
                    // like it does: the message still arrives, the phone just
                    // stays quiet about it.
                    subtitle: Text(
                      l.settingsNotificationsHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onChanged: settings.setNotificationsEnabled,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(AppIcons.logout),
                label: Text(l.commonLogout),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// One option in a group. Language and theme each take a single answer, so the
/// indicator is round and only one of them is ever filled.
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
