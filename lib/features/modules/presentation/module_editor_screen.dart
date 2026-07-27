import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/info_section.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/states.dart';
import '../application/module_editor_cubit.dart';
import '../data/modules_repository.dart';
import '../domain/module_type.dart';
import '../domain/operational_module.dart';
import 'employee_picker_screen.dart';
import 'widgets/module_field_input.dart';
import 'widgets/node_editor_sheet.dart';
import 'widgets/picker_sheet.dart';

/// Builds one operational file, in the order it is really built. A file with a
/// tree takes three steps:
///
///   1. the file itself — when work at the towers starts, and its attachments;
///   2. its sectors — each named, with a supervisor and his deputies;
///   3. the hotels inside each sector, and who runs each tower.
///
/// A file that is only a roster — الطوافة والنقل — takes two: the file, then its
/// teams, each member put on one and handed the duties that are his.
///
/// Each step is saved as it is finished, because a file is assembled over days:
/// the sectors are known long before the last hotel is confirmed. Pops `true`
/// when anything was written.
class ModuleEditorScreen extends StatelessWidget {
  const ModuleEditorScreen({
    super.key,
    required this.moduleTypeId,
    required this.seasonId,
    this.existing,
    this.initialStep = 0,
  });

  final String moduleTypeId;
  final String seasonId;
  final OperationalModule? existing;

  /// Editing an existing file usually means adding towers, not revisiting the
  /// start date — so the caller says where to land.
  final int initialStep;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ModuleEditorCubit(
        ModulesRepository(),
        moduleTypeId: moduleTypeId,
        seasonId: seasonId,
        existing: existing,
      )..goTo(existing == null ? 0 : initialStep),
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
  /// Whether anything reached the database, so the screen behind us reloads.
  bool _dirty = false;

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _complaint(SaveResult result) {
    final l = context.l10n;
    return switch (result.outcome) {
      SaveOutcome.ok => l.moduleSaved,
      SaveOutcome.missingDate => '${l.moduleStartDate} — ${l.commonRequired}',
      SaveOutcome.missingField ||
      SaveOutcome.missingEntry ||
      SaveOutcome.missingRole =>
        '${result.name?.of(context) ?? ''} — ${l.commonRequired}',
      SaveOutcome.failed => result.message ?? '',
    };
  }

  Future<void> _next() async {
    final cubit = context.read<ModuleEditorCubit>();
    final state = cubit.state;

    if (state.step == 0) {
      final result = await cubit.saveInfo();
      if (!mounted) return;
      if (result.ok) {
        _dirty = true;
      } else {
        _say(_complaint(result));
      }
      return;
    }
    if (state.step < state.lastStep) {
      cubit.goTo(state.step + 1);
      return;
    }
    Navigator.of(context).pop(_dirty);
  }

  /// Puts people on one of the teams of a file that has no tree.
  Future<void> _pickTeam(ModuleRole role) async {
    final cubit = context.read<ModuleEditorCubit>();

    final result = await showEmployeePicker(
      context,
      title: role.name.of(context),
      seasonId: cubit.seasonId,
      multiple: role.allowsMultiple,
      selected: cubit.state.memberProfileIdsOf(role.id),
    );
    if (result == null || !mounted) return;

    final error = await cubit.setRoleMembers(role.id, result);
    if (!mounted) return;
    if (error != null) {
      _say(error);
      return;
    }
    _dirty = true;
  }

  /// Hands one member his share of the duties open to him — or takes them all
  /// back, which leaves him in the file with none, and is allowed.
  ///
  /// What is open to him is his role's own list and the file's, whichever the
  /// type declares, laid out in the stages the work happens in.
  Future<void> _pickTasks(ModuleRole role, ModuleMember member) async {
    final cubit = context.read<ModuleEditorCubit>();
    final type = cubit.state.type;
    final l = context.l10n;
    if (type == null) return;

    final result = await showPickerSheet(
      context,
      title: member.profile?.fullName ?? role.name.of(context),
      multiple: true,
      selected: member.taskIds,
      emptyMessage: l.moduleNoTasks,
      options: [
        for (final (stage, tasks) in type.byStage(type.assignableFor(role)))
          for (final task in tasks)
            PickerOption(
              id: task.id,
              label: task.title.of(context),
              subtitle: task.description?.of(context),
              group: stage?.name.of(context),
            ),
      ],
    );
    if (result == null || !mounted) return;

    final error = await cubit.setMemberTasks(member.id, result);
    if (!mounted) return;
    if (error != null) {
      _say(error);
      return;
    }
    _dirty = true;
  }

  /// Adds or edits a sector (no [parent]) or a hotel inside one.
  Future<void> _editNode(
    ModuleLevel level, {
    ModuleNode? node,
    ModuleNode? parent,
  }) async {
    final cubit = context.read<ModuleEditorCubit>();
    final state = cubit.state;

    final draft = await showNodeEditorSheet(
      context,
      level: level,
      seasonId: cubit.seasonId,
      employees: state.employees,
      referenceSet: state.referenceSetById(level.referenceSetId),
      takenEntries: state.takenEntries(level.id, except: node?.id),
      suggestedLabel: node != null || !level.isNamedByHand
          ? null
          : context.l10n.moduleSectorSuggestedName(
              state.parentNodes.length + 1,
            ),
      existing: node == null
          ? null
          : NodeDraft(
              id: node.id,
              referenceItemId: node.referenceItemId,
              label: node.label,
              roleMembers: {
                for (final role in level.roles)
                  role.id: node.profileIdsOf(role.id),
              },
            ),
    );
    if (draft == null || !mounted) return;

    final result = await cubit.saveNode(
      level: level,
      draft: draft,
      parentId: parent?.id,
    );
    if (!mounted) return;
    if (result.ok) {
      _dirty = true;
    } else {
      _say(_complaint(result));
    }
  }

  Future<void> _deleteNode(
    ModuleLevel level,
    ModuleNode node,
    String name,
  ) async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.moduleNodeDelete(level.name.of(context))),
        content: Text(l.moduleNodeDeleteConfirm(name)),
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

    final error = await context.read<ModuleEditorCubit>().deleteNode(node.id);
    if (!mounted) return;
    if (error != null) {
      _say(error);
      return;
    }
    _dirty = true;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cubit = context.watch<ModuleEditorCubit>();
    final state = cubit.state;
    final saving = state.status == EditorStatus.saving;

    // A file with no tree has nothing to divide into sectors and towers: its
    // people are the second and last step.
    final steps = state.hasTree
        ? [l.moduleStepInfo, l.moduleStepSectors, l.moduleStepTowers]
        : [l.moduleStepInfo, l.moduleStepMembers];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_dirty);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          // The file has no name of its own — its type names it.
          title: Text(state.type?.name.of(context) ?? l.moduleNew),
          bottom: state.type == null
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(34),
                  child: _StepBar(
                    steps: steps,
                    current: state.step,
                    // Steps beyond the first need a row to hang off.
                    onTap: state.isCreated ? cubit.goTo : null,
                  ),
                ),
        ),
        body: switch (state.status) {
          EditorStatus.loading => const AppLoader(),
          EditorStatus.error => EmptyState(
            icon: AppIcons.modules,
            title: state.error ?? '',
          ),
          _ => switch ((state.step, state.hasTree)) {
            (0, _) => _InfoStep(state: state),
            (_, false) => _TeamsStep(
              state: state,
              onPickTeam: _pickTeam,
              onPickTasks: _pickTasks,
            ),
            (1, true) => _NodesStep(
              state: state,
              onAdd: (level) => _editNode(level),
              onEdit: (level, node) => _editNode(level, node: node),
              onDelete: _deleteNode,
            ),
            _ => _TowersStep(
              state: state,
              onAdd: (level, parent) => _editNode(level, parent: parent),
              onEdit: (level, node) => _editNode(level, node: node),
              onDelete: _deleteNode,
            ),
          },
        },
        bottomNavigationBar: state.type == null
            ? null
            : GlassSurface(
                radius: 0,
                strong: true,
                shadow: false,
                bordered: false,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        if (state.step > 0) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: saving
                                  ? null
                                  : () => cubit.goTo(state.step - 1),
                              child: Text(l.commonBack),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                        ],
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: saving ? null : _next,
                            icon: saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : Icon(
                                    state.step >= state.lastStep
                                        ? AppIcons.approve
                                        : AppIcons.activate,
                                  ),
                            label: Text(
                              state.step >= state.lastStep
                                  ? l.commonDone
                                  : l.commonNext,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Which of the three steps we are on. Tappable once the file exists, so an
/// admin coming back to add a hotel jumps straight to the last step.
class _StepBar extends StatelessWidget {
  const _StepBar({required this.steps, required this.current, this.onTap});

  final List<String> steps;
  final int current;
  final void Function(int step)? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                onTap: onTap == null ? null : () => onTap!(i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${i + 1}. ${steps[i]}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: i == current
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        fontWeight: i == current ? FontWeight.w700 : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: i <= current
                            ? scheme.primary
                            : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Step 1 — when the work starts, and whatever else the type asks of the file
/// as a whole. There is no name to enter: the type is the name.
class _InfoStep extends StatelessWidget {
  const _InfoStep({required this.state});

  final ModuleEditorState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final type = state.type!;
    final cubit = context.read<ModuleEditorCubit>();

    return ResponsiveCenter(
      child: ListView(
        padding: context.scrollPadding(),
        children: staggered([
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: state.startsOn ?? now,
                      firstDate: DateTime(now.year - 2),
                      lastDate: DateTime(now.year + 5),
                    );
                    if (picked != null) cubit.setStartsOn(picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: '${l.moduleStartDate} *',
                      prefixIcon: const Icon(AppIcons.seasons),
                    ),
                    child: Text(
                      state.startsOn == null
                          ? l.profileSelectDate
                          : formatDate(state.startsOn),
                      style: state.startsOn == null
                          ? TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            )
                          : null,
                    ),
                  ),
                ),
                // What the date above is the date OF. Sits under the picker
                // rather than replacing it: somebody still has to say when the
                // work actually began.
                if (type.startCondition != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        AppIcons.seasons,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '${l.moduleStartCondition}: '
                          '${type.startCondition!.of(context)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
                if (type.endCondition != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  // Not a date and not editable: every file of this type ends
                  // on the same event, which the type states once.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        AppIcons.pending,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '${l.moduleEndCondition}: '
                          '${type.endCondition!.of(context)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
                for (final field in type.fields) ...[
                  const SizedBox(height: AppSpacing.lg),
                  ModuleFieldInput(
                    field: field,
                    value: state.values[field.key],
                    referenceSet: state.referenceSetById(field.referenceSetId),
                    onChanged: (v) => cubit.setValue(field.key, v),
                    onFilePicked: (file, name) =>
                        cubit.attachFile(field.key, file, name),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              l.moduleOnePerSeason,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Step 2 — the sectors. Each is named here and given its supervisor and his
/// deputies; the hotels come in the step after.
class _NodesStep extends StatelessWidget {
  const _NodesStep({
    required this.state,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final ModuleEditorState state;
  final void Function(ModuleLevel level) onAdd;
  final void Function(ModuleLevel level, ModuleNode node) onEdit;
  final void Function(ModuleLevel level, ModuleNode node, String name) onDelete;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final level = state.parentLevel;
    if (level == null) {
      return EmptyState(icon: AppIcons.modules, title: l.moduleNoLevels);
    }
    final sectors = state.parentNodes;

    return ResponsiveCenter(
      child: ListView(
        padding: context.scrollPadding(),
        children: staggered([
          SectionHeader(
            l.moduleSectorsCount(sectors.length),
            icon: AppIcons.roles,
          ),
          if (sectors.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(l.moduleNoSectors),
            ),
          for (final sector in sectors) ...[
            _NodeCard(
              state: state,
              level: level,
              node: sector,
              onEdit: () => onEdit(level, sector),
              onDelete: (name) => onDelete(level, sector, name),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.xs),
          OutlinedButton.icon(
            onPressed: () => onAdd(level),
            icon: const Icon(AppIcons.add),
            label: Text(l.moduleNodeAdd(level.name.of(context))),
          ),
        ]),
      ),
    );
  }
}

/// Step 3 — the hotels of every sector, each with its tower supervisor, his
/// deputies and the mission members serving there.
class _TowersStep extends StatelessWidget {
  const _TowersStep({
    required this.state,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final ModuleEditorState state;
  final void Function(ModuleLevel level, ModuleNode parent) onAdd;
  final void Function(ModuleLevel level, ModuleNode node) onEdit;
  final void Function(ModuleLevel level, ModuleNode node, String name) onDelete;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sectorLevel = state.parentLevel;
    final towerLevel = state.childLevel;
    if (sectorLevel == null || towerLevel == null) {
      return EmptyState(icon: AppIcons.modules, title: l.moduleNoLevels);
    }
    final sectors = state.parentNodes;
    if (sectors.isEmpty) {
      return EmptyState(
        icon: AppIcons.roles,
        title: l.moduleNoSectors,
        message: l.moduleSectorsFirst,
      );
    }

    return ResponsiveCenter(
      child: ListView(
        padding: context.scrollPadding(),
        children: staggered([
          for (final sector in sectors) ...[
            SectionHeader(
              sector.label ?? sectorLevel.name.of(context),
              icon: AppIcons.roles,
            ),
            for (final tower in state.childrenOf(sector.id)) ...[
              _NodeCard(
                state: state,
                level: towerLevel,
                node: tower,
                onEdit: () => onEdit(towerLevel, tower),
                onDelete: (name) => onDelete(towerLevel, tower, name),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            OutlinedButton.icon(
              onPressed: () => onAdd(towerLevel, sector),
              icon: const Icon(AppIcons.add),
              label: Text(l.moduleNodeAdd(towerLevel.name.of(context))),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ]),
      ),
    );
  }
}

/// The second and last step of a file with no tree — its teams. Each team is
/// filled from the season's participants, and each person on it is then handed
/// the duties that are actually his, out of the list his team owns.
///
/// Handing him none is a real answer, not an unfinished one: he is on the team,
/// and the team's job description already says what that means.
class _TeamsStep extends StatelessWidget {
  const _TeamsStep({
    required this.state,
    required this.onPickTeam,
    required this.onPickTasks,
  });

  final ModuleEditorState state;
  final void Function(ModuleRole role) onPickTeam;
  final void Function(ModuleRole role, ModuleMember member) onPickTasks;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final type = state.type;
    final roles = type?.roles ?? const <ModuleRole>[];
    if (type == null || roles.isEmpty) {
      return EmptyState(icon: AppIcons.roles, title: l.moduleNoRoles);
    }

    return ResponsiveCenter(
      child: ListView(
        padding: context.scrollPadding(),
        children: staggered([
          SectionHeader(
            l.moduleMembersCount(state.members.length),
            icon: AppIcons.participants,
          ),
          for (final role in roles) ...[
            _TeamCard(
              role: role,
              members: state.membersOf(role.id),
              // How much there is to hand out — the role's own list plus the
              // file's, which is where this type keeps all of its duties.
              menuSize: type.assignableFor(role).length,
              onPick: () => onPickTeam(role),
              onPickTasks: (member) => onPickTasks(role, member),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ]),
      ),
    );
  }
}

/// One team: who is on it, and what each of them was handed.
class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.role,
    required this.members,
    required this.menuSize,
    required this.onPick,
    required this.onPickTasks,
  });

  final ModuleRole role;
  final List<ModuleMember> members;

  /// How many duties there are to hand out here, for the "3 of 15" on each row.
  final int menuSize;

  final VoidCallback onPick;
  final void Function(ModuleMember member) onPickTasks;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      blur: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.roles, size: 18, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  role.name.of(context),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${members.length}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: scheme.primary),
              ),
            ],
          ),
          if (members.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                l.moduleNoTeamMembers,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            for (final member in members)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: _TeamMemberRow(
                  member: member,
                  menuSize: menuSize,
                  onTap: () => onPickTasks(member),
                ),
              ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(AppIcons.participants),
            label: Text(l.moduleTeamPick),
          ),
        ],
      ),
    );
  }
}

/// One person on a team, and how much of its list is his. Tapping opens the
/// list to hand him more of it, or take some back.
class _TeamMemberRow extends StatelessWidget {
  const _TeamMemberRow({
    required this.member,
    required this.menuSize,
    required this.onTap,
  });

  final ModuleMember member;
  final int menuSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final profile = member.profile;
    final assigned = member.taskIds.length;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            ProfileAvatar(
              photoUrl: profile?.photoUrl,
              name: profile?.fullName ?? '',
              radius: 18,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (profile?.fullName.isEmpty ?? true)
                        ? '—'
                        : profile!.fullName,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    assigned == 0
                        ? l.moduleNoAssignedTasks
                        : l.moduleAssignedTasksCount(assigned, menuSize),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: assigned == 0
                          ? scheme.onSurfaceVariant
                          : scheme.primary,
                      fontStyle: assigned == 0 ? FontStyle.italic : null,
                    ),
                  ),
                ],
              ),
            ),
            Icon(AppIcons.tasks, size: 18, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

/// A sector or a tower as it appears in the editor: what it is, who holds each
/// of its roles, and the two things you can do to it.
class _NodeCard extends StatelessWidget {
  const _NodeCard({
    required this.state,
    required this.level,
    required this.node,
    required this.onEdit,
    required this.onDelete,
  });

  final ModuleEditorState state;
  final ModuleLevel level;
  final ModuleNode node;
  final VoidCallback onEdit;
  final void Function(String name) onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entry = state.referenceItem(
      level.referenceSetId,
      node.referenceItemId,
    );
    final name = entry?.name.of(context) ?? node.label ?? '—';

    return GlassCard(
      blur: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                level.isNamedByHand
                    ? AppIcons.moduleType
                    : AppIcons.organization,
                size: 18,
                color: scheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: context.l10n.commonEdit,
                visualDensity: VisualDensity.compact,
                onPressed: onEdit,
                icon: const Icon(AppIcons.edit, size: 18),
              ),
              IconButton(
                tooltip: context.l10n.commonDelete,
                visualDensity: VisualDensity.compact,
                onPressed: () => onDelete(name),
                icon: const Icon(AppIcons.delete, size: 18),
              ),
            ],
          ),
          for (final role in level.roles)
            if (node.profileIdsOf(role.id).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 116,
                      child: Text(
                        role.name.of(context),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final id in node.profileIdsOf(role.id))
                            if (state.profileById(id) case final p?)
                              Chip(
                                avatar: ProfileAvatar(
                                  photoUrl: p.photoUrl,
                                  name: p.fullName,
                                  radius: 10,
                                ),
                                label: Text(p.fullName),
                                visualDensity: VisualDensity.compact,
                              ),
                        ],
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
