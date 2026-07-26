import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/enum_labels.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/info_section.dart';
import '../../../core/widgets/profile_hero.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/states.dart';
import '../../auth/application/session_cubit.dart';
import '../domain/profile.dart';
import 'profile_completion_screen.dart';
import 'widgets/change_password_sheet.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final profile = context.watch<SessionCubit>().state.profile;

    if (profile == null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(title: Text(l.navMyProfile)),
        body: const AppLoader(),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(title: Text(l.navMyProfile)),
      body: Builder(
        // See HomeScreen: the padding must come from a context inside the body.
        builder: (context) => ResponsiveCenter(
          child: RefreshIndicator(
            onRefresh: () => context.read<SessionCubit>().reload(),
            child: ListView(
              padding: context.scrollPadding(),
              children: staggered([
                ProfileHero(
                  name: profile.fullName,
                  photoUrl: profile.photoUrl,
                  roleLabel: profile.jobTitleName,
                ),
                const SizedBox(height: AppSpacing.lg),
                _ActionsCard(profile: profile),
                const SizedBox(height: AppSpacing.lg),
                InfoSection(
                  title: l.profileSectionPersonal,
                  icon: AppIcons.firstName,
                  children: [
                    InfoRow(
                      icon: AppIcons.firstName,
                      label: l.profileFirstName,
                      value: profile.firstName,
                    ),
                    InfoRow(
                      icon: AppIcons.fatherName,
                      label: l.profileFatherName,
                      value: profile.fatherName,
                    ),
                    InfoRow(
                      icon: AppIcons.surname,
                      label: l.profileSurname,
                      value: profile.surname,
                    ),
                    InfoRow(
                      icon: AppIcons.gender,
                      label: l.profileGender,
                      value: profile.gender?.label(l),
                    ),
                    InfoRow(
                      icon: AppIcons.mission,
                      label: l.profileMissionType,
                      value: profile.missionType?.label(l),
                    ),
                    InfoRow(
                      icon: AppIcons.dateOfBirth,
                      label: l.profileDateOfBirth,
                      value: formatDate(profile.dateOfBirth),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                InfoSection(
                  title: l.profileSectionContact,
                  icon: AppIcons.phoneSy,
                  children: [
                    InfoRow(
                      icon: AppIcons.phoneSy,
                      label: l.profilePhoneSy,
                      value: profile.phoneSy,
                      action: InfoAction.call,
                    ),
                    InfoRow(
                      icon: AppIcons.phoneSa,
                      label: l.profilePhoneSa,
                      value: profile.phoneSa,
                      action: InfoAction.call,
                    ),
                    InfoRow(
                      icon: AppIcons.email,
                      label: l.profileEmail,
                      value: profile.email,
                      action: InfoAction.email,
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          _ActionRow(
            icon: AppIcons.edit,
            label: l.myProfileEdit,
            onTap: () => Navigator.of(context).push(
              fadeThroughRoute(
                (_) => ProfileCompletionScreen(existing: profile),
              ),
            ),
          ),
          Divider(
            height: 1,
            indent: 60,
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
          _ActionRow(
            icon: AppIcons.password,
            label: l.myProfileChangePassword,
            onTap: () => showChangePasswordSheet(context),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: scheme.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            const NavChevron(),
          ],
        ),
      ),
    );
  }
}
