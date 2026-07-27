import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/animations/animations.dart';
import '../../../core/constants/permission_codes.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/info_section.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/states.dart';
import '../../auth/application/session_cubit.dart';
import '../application/module_detail_cubit.dart';
import '../data/modules_repository.dart';
import '../domain/module_type.dart';
import '../domain/operational_module.dart';
import 'module_editor_screen.dart';

/// Everything an operational file holds, for whoever is allowed to see it: when
/// it starts and what ends it, its attachment, the duties that come with a
/// role in it, and the tree itself — every sector, the hotels under it, and who
/// to call at each.
class ModuleDetailScreen extends StatelessWidget {
  const ModuleDetailScreen({
    super.key,
    required this.moduleId,
    this.viewAsProfileId,
  });

  final String moduleId;

  /// Whose duties to show. Opened from an employee's page, the reader is asking
  /// what THAT employee is responsible for — showing the reader their own role
  /// instead would answer a question nobody asked. Null means the reader.
  final String? viewAsProfileId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ModuleDetailCubit(
        ModulesRepository(),
        moduleId,
        viewAsProfileId: viewAsProfileId,
      ),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  /// Whether anything changed that the list behind us should pick up.
  bool _dirty = false;

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPdf(ModuleFile file) async {
    final l = context.l10n;
    final url = await context.read<ModuleDetailCubit>().signedUrl(file.path);
    if (!mounted) return;
    if (url == null) {
      _say(l.modulePdfOpenFailed);
      return;
    }
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) _say(l.modulePdfOpenFailed);
  }

  /// [step] lands the editor where the work is: the file's own details, or
  /// straight at the towers.
  Future<void> _edit(OperationalModule module, {int step = 0}) async {
    final cubit = context.read<ModuleDetailCubit>();
    final saved = await Navigator.of(context).push<bool>(
      fadeThroughRoute(
        (_) => ModuleEditorScreen(
          moduleTypeId: module.moduleTypeId,
          seasonId: module.seasonId,
          existing: module,
          initialStep: step,
        ),
      ),
    );
    if (saved == true) {
      _dirty = true;
      await cubit.load();
    }
  }

  Future<void> _toggleActive(OperationalModule module) async {
    final l = context.l10n;
    final error = await context.read<ModuleDetailCubit>().toggleActive();
    if (!mounted) return;
    _dirty = true;
    _say(error ?? (module.isActive ? l.moduleDeactivated : l.moduleActivated));
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.moduleDelete),
        content: Text(l.moduleDeleteConfirm),
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
    if (confirmed != true || !mounted) return;

    final error = await context.read<ModuleDetailCubit>().delete();
    if (!mounted) return;
    if (error != null) {
      _say(error);
      return;
    }
    _say(l.moduleDeleted);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = context.watch<SessionCubit>().state;
    final canManage = session.can(PermissionCodes.modulesManage);

    return BlocBuilder<ModuleDetailCubit, ModuleDetailState>(
      builder: (context, state) {
        final module = state.module;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) Navigator.of(context).pop(_dirty);
          },
          child: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: GlassAppBar(
              // A file has no name of its own; its type is its name.
              title: Text(
                state.type?.name.of(context) ??
                    module?.moduleTypeName?.of(context) ??
                    l.modulesTitle,
              ),
              actions: [
                if (canManage && module != null) ...[
                  IconButton(
                    tooltip: l.commonEdit,
                    onPressed: () => _edit(module),
                    icon: const Icon(AppIcons.edit),
                  ),
                  IconButton(
                    tooltip: l.moduleDelete,
                    onPressed: _delete,
                    icon: const Icon(AppIcons.delete),
                  ),
                ],
              ],
            ),
            bottomNavigationBar: (canManage && module != null)
                ? GlassSurface(
                    radius: 0,
                    strong: true,
                    shadow: false,
                    bordered: false,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: module.isActive
                            ? OutlinedButton.icon(
                                onPressed: () => _toggleActive(module),
                                icon: const Icon(AppIcons.suspend),
                                label: Text(l.moduleDeactivate),
                              )
                            : FilledButton.icon(
                                onPressed: () => _toggleActive(module),
                                icon: const Icon(AppIcons.activate),
                                label: Text(l.moduleActivate),
                              ),
                      ),
                    ),
                  )
                : null,
            body: switch (state.status) {
              ModuleDetailStatus.loading => const SkeletonList(),
              ModuleDetailStatus.error => EmptyState(
                icon: AppIcons.modules,
                title: state.error ?? '',
              ),
              ModuleDetailStatus.ready => _Body(
                state: state,
                module: module!,
                canManage: canManage,
                onOpenPdf: _openPdf,
                onBuildTree: () => _edit(module, step: 1),
              ),
            },
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.module,
    required this.canManage,
    required this.onOpenPdf,
    required this.onBuildTree,
  });

  final ModuleDetailState state;
  final OperationalModule module;
  final bool canManage;
  final void Function(ModuleFile file) onOpenPdf;
  final VoidCallback onBuildTree;

  /// Renders a stored value the way its field kind means it to be read.
  String _display(BuildContext context, ModuleField field) {
    final value = module.data[field.key];
    return switch (field.kind) {
      ModuleFieldKind.reference =>
        state.referenceItem(field.referenceSetId, value)?.name.of(context) ?? '',
      ModuleFieldKind.date => formatDate(
        value is String ? DateTime.tryParse(value) : null,
      ),
      ModuleFieldKind.pdf => ModuleFile.fromJson(value)?.name ?? '',
      _ => value?.toString() ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final type = state.type;
    final fields = type?.fields ?? const <ModuleField>[];
    final pdfFields = fields.where((f) => f.kind == ModuleFieldKind.pdf);
    final roles = state.focusRoles;
    final focusName = state.focusName;
    final sectorLevel = state.parentLevel;
    final sectors = state.parentNodes;

    return ResponsiveCenter(
      child: RefreshIndicator(
        onRefresh: () => context.read<ModuleDetailCubit>().load(),
        child: ListView(
          padding: context.scrollPadding(),
          children: staggered([
            InfoSection(
              title: l.moduleSectionInfo,
              icon: AppIcons.modules,
              children: [
                if (module.seasonHijriYear != null)
                  InfoRow(
                    icon: AppIcons.seasons,
                    label: l.moduleSeasonLabel,
                    value: l.seasonHijriYear(module.seasonHijriYear!),
                  ),
                InfoRow(
                  icon: AppIcons.activate,
                  label: l.moduleStartDate,
                  value: formatDate(module.startsOn),
                ),
                InfoRow(
                  icon: AppIcons.pending,
                  label: l.moduleEndCondition,
                  value:
                      (type?.endCondition ?? module.endCondition)?.of(context),
                ),
                for (final field in fields)
                  if (field.kind != ModuleFieldKind.pdf)
                    InfoRow(
                      icon: AppIcons.document,
                      label: field.label.of(context),
                      value: _display(context, field),
                    ),
              ],
            ),
            for (final field in pdfFields) ...[
              const SizedBox(height: AppSpacing.md),
              _PdfCard(
                label: field.label.of(context),
                file: module.fileAt(field.key),
                onOpen: onOpenPdf,
              ),
            ],
            if (roles.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(
                focusName == null
                    ? l.moduleSectionTasks
                    : l.moduleSectionTasksOf(focusName),
                icon: AppIcons.tasks,
              ),
              for (final held in roles) ...[
                _TaskCard(type: type!, held: held),
                const SizedBox(height: AppSpacing.md),
              ],
            ],

            const SizedBox(height: AppSpacing.lg),
            SectionHeader(
              l.moduleMembersCount(state.peopleCount),
              icon: AppIcons.participants,
            ),

            // Roles held on the file itself — the entire roster of a file with
            // no tree, and each member's share of his team's duties.
            for (final role in type?.roles ?? const <ModuleRole>[])
              _RoleRosterCard(state: state, role: role),

            if (type?.hasTree ?? true)
              if (sectorLevel == null || sectors.isEmpty)
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l.moduleNoSectors),
                      if (canManage) ...[
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton.icon(
                          onPressed: onBuildTree,
                          icon: const Icon(AppIcons.add),
                          label: Text(l.moduleBuildTree),
                        ),
                      ],
                    ],
                  ),
                )
              else
                for (final sector in sectors)
                  _SectorCard(state: state, level: sectorLevel, sector: sector)
            else if (state.members.isEmpty)
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.moduleNoMembers),
                    if (canManage) ...[
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: onBuildTree,
                        icon: const Icon(AppIcons.add),
                        label: Text(l.moduleTeamPick),
                      ),
                    ],
                  ],
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

/// One team of a file with no tree: everyone on it, and under each of them the
/// duties he was actually handed.
///
/// The duties are on the roster rather than tucked behind a tap because that is
/// what this file is for — "who is doing the passports" is the question it
/// exists to answer.
class _RoleRosterCard extends StatelessWidget {
  const _RoleRosterCard({required this.state, required this.role});

  final ModuleDetailState state;
  final ModuleRole role;

  @override
  Widget build(BuildContext context) {
    final members = state.membersOf(role.id);
    if (members.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        SectionHeader(role.name.of(context), icon: AppIcons.roles),
        for (final member in members)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: GlassCard(
              blur: false,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MemberTile(member: member, dense: true),
                  ..._duties(context, member.taskIds),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// What this person was handed, in the stages the work happens in. Someone
  /// with nothing handed to him is not an oversight — being in the file is
  /// itself the posting — so this says so plainly rather than leaving a gap.
  List<Widget> _duties(BuildContext context, Set<String> assigned) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final type = state.type;
    if (type == null || !role.tasksAreAssigned) return const [];
    final tasks = type.dutiesOf(role, assigned);

    return [
      const SizedBox(height: AppSpacing.md),
      if (tasks.isEmpty)
        Text(
          l.moduleNoAssignedTasks,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        )
      else ...[
        Text(
          l.moduleAssignedTasks,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...stagedTasks(context, type, tasks),
      ],
    ];
  }
}

/// One sector: its supervisors, then each of its towers underneath.
class _SectorCard extends StatelessWidget {
  const _SectorCard({
    required this.state,
    required this.level,
    required this.sector,
  });

  final ModuleDetailState state;
  final ModuleLevel level;
  final ModuleNode sector;

  @override
  Widget build(BuildContext context) {
    final towerLevel = state.childLevel;
    final towers = state.childrenOf(sector.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        SectionHeader(
          sector.label ?? level.name.of(context),
          icon: AppIcons.roles,
        ),
        for (final role in level.roles)
          for (final member in sector.membersOf(role.id))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _MemberTile(member: member, roleName: role.name.of(context)),
            ),
        if (towerLevel != null)
          for (final tower in towers)
            _TowerCard(state: state, level: towerLevel, tower: tower),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

/// One tower: the hotel, and everyone serving in it.
class _TowerCard extends StatelessWidget {
  const _TowerCard({
    required this.state,
    required this.level,
    required this.tower,
  });

  final ModuleDetailState state;
  final ModuleLevel level;
  final ModuleNode tower;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final entry = state.referenceItem(
      level.referenceSetId,
      tower.referenceItemId,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.organization, size: 18, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    entry?.name.of(context) ?? tower.label ?? '—',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (tower.members.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  l.moduleNoMembers,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            for (final role in level.roles)
              for (final member in tower.membersOf(role.id))
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: _MemberTile(
                    member: member,
                    roleName: role.name.of(context),
                    dense: true,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _PdfCard extends StatelessWidget {
  const _PdfCard({
    required this.label,
    required this.file,
    required this.onOpen,
  });

  final String label;
  final ModuleFile? file;
  final void Function(ModuleFile file) onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final attached = file;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: attached == null ? null : () => onOpen(attached),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              attached == null ? AppIcons.documentEmpty : AppIcons.pdf,
              size: 18,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(
                  attached?.name ?? l.moduleNoPdf,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (attached != null)
            Icon(AppIcons.view, size: 18, color: scheme.primary),
        ],
      ),
    );
  }
}

/// What a role actually is: its job description, and the duties on top of it.
/// The description is defined once on the module type, so it appears here
/// without ever being re-entered per file.
///
/// The duties are whichever of the two kinds the role uses — the standing list
/// every holder carries, or only the share this person was handed. Nobody
/// should be shown a duty that is not his.
///
/// The places are on the card because the same role is often held in several
/// towers at once, and "which towers" is half the answer.
class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.type, required this.held});

  final ModuleType type;
  final RoleHere held;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final role = held.role;
    final tasks = held.tasks;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              GlassBadge(
                label: role.name.of(context),
                icon: AppIcons.roles,
                color: AppColors.darkGold,
              ),
              for (final place in held.places)
                GlassBadge(
                  label: place.of(context),
                  icon: AppIcons.organization,
                  dense: true,
                ),
            ],
          ),
          if (role.description != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l.moduleJobDescription,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              role.description!.of(context),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (tasks.isEmpty)
            // Two different silences. A role whose duties are handed out one by
            // one and has handed this person none says so — it is a fact about
            // him, not about the role. A role with a description and no extra
            // duties needs no apology at all.
            if (role.tasksAreAssigned)
              Text(
                l.moduleNoAssignedTasksMine,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              )
            else if (role.description == null)
              Text(
                l.moduleNoTasks,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              const SizedBox.shrink()
          else ...[
            if (role.tasksAreAssigned) ...[
              Text(
                l.moduleAssignedTasks,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            ...stagedTasks(context, type, tasks),
          ],
        ],
      ),
    );
  }
}

/// [tasks] laid out in the stages of the work, each under its heading — or as a
/// plain list, for a type whose duties fall into no stages.
List<Widget> stagedTasks(
  BuildContext context,
  ModuleType type,
  List<RoleTask> tasks,
) {
  final scheme = Theme.of(context).colorScheme;

  return [
    for (final (stage, inStage) in type.byStage(tasks)) ...[
      if (stage != null)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            stage.name.of(context),
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: scheme.primary),
          ),
        ),
      for (final task in inStage) _TaskLine(task: task),
      if (stage != null) const SizedBox(height: AppSpacing.xs),
    ],
  ];
}

/// One duty, wherever it is listed.
class _TaskLine extends StatelessWidget {
  const _TaskLine({required this.task});

  final RoleTask task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(AppIcons.tasks, size: 15, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title.of(context),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                if (task.description != null)
                  Text(
                    task.description!.of(context),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A member row that surfaces the phone numbers directly, and dials them on
/// tap: coordinating between a tower and its sector is the everyday use of
/// this screen, and it is why members can see each other at all.
class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    this.roleName,
    this.dense = false,
  });

  final ModuleMember member;

  /// Shown as a badge — inside a tower the same card carries a supervisor, his
  /// deputies and the mission members, so the role has to be on the row.
  final String? roleName;

  /// Towers nest their members inside the tower card, which already has a
  /// border of its own.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final profile = member.profile;
    if (profile == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // Every way to reach this person, each one live: coordinating between a
    // tower and its sector is the everyday use of this screen, and a number you
    // have to retype is a number you get wrong.
    final contacts = <(String, String, IconData, InfoAction)>[
      if (profile.phoneSy != null && profile.phoneSy!.isNotEmpty)
        (
          l.moduleContactSy,
          profile.phoneSy!,
          AppIcons.phoneSy,
          InfoAction.call,
        ),
      if (profile.phoneSa != null && profile.phoneSa!.isNotEmpty)
        (
          l.moduleContactSa,
          profile.phoneSa!,
          AppIcons.phoneSa,
          InfoAction.call,
        ),
      if (profile.email != null && profile.email!.isNotEmpty)
        (l.profileEmail, profile.email!, AppIcons.email, InfoAction.email),
    ];

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ProfileAvatar(
              photoUrl: profile.photoUrl,
              name: profile.fullName,
              radius: dense ? 19 : 23,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          profile.fullName.isEmpty ? '—' : profile.fullName,
                          style: dense ? text.titleSmall : text.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (profile.isExternal) ...[
                        const SizedBox(width: AppSpacing.sm),
                        GlassBadge(
                          label: l.profileBadgeExternal,
                          color: scheme.tertiary,
                          icon: AppIcons.external,
                          dense: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (roleName != null)
                    Text(
                      roleName!,
                      style: text.bodySmall?.copyWith(color: scheme.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (profile.jobTitleName != null)
                    Text(
                      profile.jobTitleName!,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        if (contacts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final (label, value, icon, action) in contacts)
                // The chip claims the tap; long-press falls through to here,
                // which is the escape hatch when the device has no app to
                // handle the link.
                GestureDetector(
                  onLongPress: () => copyToClipboard(context, value),
                  child: ActionChip(
                    avatar: Icon(icon, size: 15),
                    label: Text(value),
                    tooltip: label,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => launchUrl(action.uriFor(value)),
                  ),
                ),
            ],
          ),
        ],
      ],
    );

    if (dense) return body;
    return GlassCard(
      blur: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: body,
    );
  }
}
