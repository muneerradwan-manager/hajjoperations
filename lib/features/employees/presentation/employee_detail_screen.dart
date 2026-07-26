import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/constants/permission_codes.dart';
import '../../../core/l10n/enum_labels.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/info_section.dart';
import '../../../core/widgets/profile_hero.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../auth/application/session_cubit.dart';
import '../../profile/domain/profile.dart';
import '../../seasons/data/seasons_repository.dart';
import '../../notifications/presentation/send_notification_sheet.dart';
import '../application/employee_manage_cubit.dart';
import '../data/employees_repository.dart';
import 'widgets/external_edit_sheet.dart';

class EmployeeDetailScreen extends StatelessWidget {
  const EmployeeDetailScreen({super.key, required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EmployeeManageCubit(
        EmployeesRepository(),
        SeasonsRepository(),
        profile,
      ),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = context.watch<SessionCubit>().state;
    final canSuspend = session.can(PermissionCodes.employeesSuspend);
    final canExternal = session.can(PermissionCodes.employeesExternal);
    final canManageParticipants = session.can(
      PermissionCodes.seasonsParticipants,
    );
    final canNotify = session.can(PermissionCodes.notificationsSend);
    final showManagement = canSuspend || canExternal || canManageParticipants;
    final employeeId = context.read<EmployeeManageCubit>().state.profile.id;

    return Scaffold(
      appBar: GlassAppBar(
        title: Text(l.employeeDetailTitle),
        actions: [
          if (canNotify)
            IconButton(
              tooltip: l.notificationSend,
              icon: const Icon(AppIcons.send),
              onPressed: () =>
                  showSendNotificationSheet(context, recipientId: employeeId),
            ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: BlocConsumer<EmployeeManageCubit, EmployeeManageState>(
            listenWhen: (p, c) => c.error != null && p.error != c.error,
            listener: (context, state) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.error!)));
            },
            builder: (context, state) {
              final p = state.profile;
              return ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xl + MediaQuery.viewPaddingOf(context).bottom,
                ),
                children: staggered([
                  ProfileHero(
                    name: p.fullName,
                    photoUrl: p.photoUrl,
                    roleLabel: p.jobTitleName,
                    badges: [
                      if (p.isAdmin)
                        GlassBadge(
                          label: l.profileBadgeAdmin,
                          color: Theme.of(context).colorScheme.secondary,
                          icon: AppIcons.shield,
                        ),
                      if (p.isExternal)
                        GlassBadge(
                          label: l.profileBadgeExternal,
                          color: Theme.of(context).colorScheme.tertiary,
                          icon: AppIcons.external,
                        ),
                      if (p.isSuspended)
                        GlassBadge(
                          label: l.statusSuspendedTitle,
                          color: Theme.of(context).colorScheme.error,
                          icon: AppIcons.suspend,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (showManagement) ...[
                    _ManagementCard(
                      state: state,
                      canSuspend: canSuspend,
                      canExternal: canExternal,
                      canManageParticipants: canManageParticipants,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  InfoSection(
                    title: l.profileSectionPersonal,
                    icon: AppIcons.firstName,
                    children: [
                      InfoRow(
                        icon: AppIcons.firstName,
                        label: l.profileFirstName,
                        value: p.firstName,
                      ),
                      InfoRow(
                        icon: AppIcons.fatherName,
                        label: l.profileFatherName,
                        value: p.fatherName,
                      ),
                      InfoRow(
                        icon: AppIcons.surname,
                        label: l.profileSurname,
                        value: p.surname,
                      ),
                      InfoRow(
                        icon: AppIcons.gender,
                        label: l.profileGender,
                        value: p.gender?.label(l),
                      ),
                      InfoRow(
                        icon: AppIcons.mission,
                        label: l.profileMissionType,
                        value: p.missionType?.label(l),
                      ),
                      InfoRow(
                        icon: AppIcons.dateOfBirth,
                        label: l.profileDateOfBirth,
                        value: formatDate(p.dateOfBirth),
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
                        value: p.phoneSy,
                      ),
                      InfoRow(
                        icon: AppIcons.phoneSa,
                        label: l.profilePhoneSa,
                        value: p.phoneSa,
                      ),
                    ],
                  ),
                  // Reading another employee's participation rows needs the
                  // same permission as managing them, so gate on it rather
                  // than render an empty list the viewer cannot see into.
                  if (canManageParticipants) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _SeasonHistorySection(state: state),
                  ],
                  if (p.isExternal) ...[
                    const SizedBox(height: AppSpacing.lg),
                    InfoSection(
                      title: l.employeeSectionOrganization,
                      icon: AppIcons.organization,
                      children: [
                        InfoRow(
                          icon: AppIcons.organization,
                          label: l.employeeOrganization,
                          value: p.externalOrganization,
                        ),
                        InfoRow(
                          icon: AppIcons.jobTitle,
                          label: l.employeeExternalRole,
                          value: p.externalTitle,
                        ),
                      ],
                    ),
                  ],
                ]),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The seasons this employee has taken part in, newest first, with the season
/// currently under way marked so it stands out from the historical ones.
class _SeasonHistorySection extends StatelessWidget {
  const _SeasonHistorySection({required this.state});

  final EmployeeManageState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return InfoSection(
      title: l.employeeSeasonsSection,
      icon: AppIcons.seasons,
      children: [
        if (state.loadingSeason)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (state.seasonHistory.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              l.employeeSeasonsEmpty,
              style: text.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          for (final s in state.seasonHistory)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      AppIcons.seasons,
                      size: 16,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.seasonHijriYear(s.hijriYear),
                          style: text.bodyLarge,
                        ),
                        if (s.gregorianLabel != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            s.gregorianLabel!,
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (s.id == state.currentSeason?.id)
                    GlassBadge(
                      label: l.employeeSeasonBadgeCurrent,
                      color: scheme.secondary,
                      dense: true,
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

class _ManagementCard extends StatelessWidget {
  const _ManagementCard({
    required this.state,
    required this.canSuspend,
    required this.canExternal,
    required this.canManageParticipants,
  });

  final EmployeeManageState state;
  final bool canSuspend;
  final bool canExternal;
  final bool canManageParticipants;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cubit = context.read<EmployeeManageCubit>();
    final p = state.profile;

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          if (canManageParticipants && state.currentSeason != null)
            SwitchListTile(
              secondary: const Icon(AppIcons.seasons),
              title: Text(l.seasonHijriYear(state.currentSeason!.hijriYear)),
              subtitle: Text(l.seasonManageParticipants),
              value: state.inCurrentSeason,
              onChanged: state.busy ? null : (_) => cubit.toggleCurrentSeason(),
            ),
          if (canSuspend)
            SwitchListTile(
              secondary: Icon(
                AppIcons.suspend,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(l.statusSuspendedTitle),
              value: p.isSuspended,
              onChanged: state.busy ? null : (_) => cubit.toggleSuspended(),
            ),
          if (canExternal)
            ListTile(
              leading: const Icon(AppIcons.external),
              title: Text(l.employeeEditExternalTitle),
              subtitle: Text(
                p.isExternal
                    ? (p.externalOrganization ?? l.employeeIsExternal)
                    : '—',
              ),
              trailing: const NavChevron(),
              onTap: state.busy
                  ? null
                  : () => showExternalEditSheet(context, cubit, p),
            ),
        ],
      ),
    );
  }
}
