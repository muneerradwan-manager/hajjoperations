import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/constants/permission_codes.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/info_section.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/states.dart';
import '../../auth/application/session_cubit.dart';
import '../../seasons/data/seasons_repository.dart';
import '../application/modules_cubit.dart';
import '../data/modules_repository.dart';
import '../domain/module_type.dart';
import '../domain/operational_module.dart';
import 'module_detail_screen.dart';
import 'module_editor_screen.dart';

/// The operational modules the signed-in user can reach: the ones they were
/// assigned to, plus — for managers — everything including unreleased drafts.
class ModulesScreen extends StatelessWidget {
  const ModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ModulesCubit(ModulesRepository(), SeasonsRepository()),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  Future<void> _create(BuildContext context, ModulesState state) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<ModulesCubit>();
    void say(String message) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

    // Roles are filled from the current season's participants, so a file
    // cannot be created before a season is running. The list already loaded it.
    final season = state.season;
    if (season == null) {
      say(l.moduleNoCurrentSeason);
      return;
    }

    // A file of a kind exists once in a season, so a kind already opened this
    // season is not on offer at all — rather than failing at the save.
    final available = state.typesAvailable();
    if (available.isEmpty) {
      say(state.types.isEmpty ? l.moduleNoTypes : l.moduleAllTypesUsed);
      return;
    }

    final type = available.length == 1
        ? available.single
        : await showModalBottomSheet<ModuleType>(
            context: context,
            // The list of types is as long as the season has kinds of file —
            // ten of them now — and a sheet left unscrollable stops at half the
            // screen and overflows the rest.
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => _TypePickerSheet(types: available),
          );
    if (type == null || !context.mounted) return;

    final saved = await Navigator.of(context).push<bool>(
      fadeThroughRoute(
        (_) => ModuleEditorScreen(moduleTypeId: type.id, seasonId: season.id),
      ),
    );
    if (saved == true) await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = context.watch<SessionCubit>().state;
    final canManage = session.can(PermissionCodes.modulesManage);

    return Scaffold(
      extendBodyBehindAppBar: true,
      // The season is in the title because the list is now only ever one
      // season's: without it, switching the season silently changes what this
      // screen means.
      appBar: GlassAppBar(
        title: BlocBuilder<ModulesCubit, ModulesState>(
          buildWhen: (p, c) => p.season != c.season,
          builder: (context, state) => Text(
            state.season == null
                ? l.modulesTitle
                : '${l.modulesTitle} — ${l.seasonHijriYear(state.season!.hijriYear)}',
          ),
        ),
      ),
      floatingActionButton: canManage
          ? BlocBuilder<ModulesCubit, ModulesState>(
              buildWhen: (p, c) => p.types != c.types,
              builder: (context, state) => FloatingActionButton.extended(
                onPressed: state.types.isEmpty
                    ? null
                    : () => _create(context, state),
                icon: const Icon(AppIcons.add),
                label: Text(l.moduleNew),
              ),
            )
          : null,
      body: BlocBuilder<ModulesCubit, ModulesState>(
        builder: (context, state) {
          if (state.status == ModulesStatus.loading) {
            return const SkeletonList();
          }
          if (state.status == ModulesStatus.error) {
            return EmptyState(
              icon: AppIcons.modules,
              title: state.error ?? '',
              action: FilledButton(
                onPressed: () => context.read<ModulesCubit>().load(),
                child: Text(l.commonRetry),
              ),
            );
          }
          if (state.modules.isEmpty) {
            return EmptyState(
              icon: AppIcons.modules,
              title: canManage ? l.modulesEmptyManager : l.modulesEmpty,
              message: canManage && state.types.isEmpty
                  ? l.moduleNoTypes
                  : null,
            );
          }

          return ResponsiveCenter(
            child: RefreshIndicator(
              onRefresh: () => context.read<ModulesCubit>().load(),
              child: ListView(
                padding: context.scrollPadding(),
                children: staggered([
                  if (state.active.isNotEmpty) ...[
                    SectionHeader(
                      l.moduleActiveSection,
                      icon: AppIcons.modules,
                    ),
                    ...state.active.map((m) => _ModuleCard(module: m)),
                  ],
                  if (state.drafts.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    SectionHeader(l.moduleDraftSection, icon: AppIcons.edit),
                    ...state.drafts.map((m) => _ModuleCard(module: m)),
                  ],
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});

  final OperationalModule module;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        blur: false,
        padding: const EdgeInsets.all(AppSpacing.lg),
        onTap: () async {
          final changed = await Navigator.of(context).push<bool>(
            fadeThroughRoute((_) => ModuleDetailScreen(moduleId: module.id)),
          );
          if (changed == true && context.mounted) {
            await context.read<ModulesCubit>().load();
          }
        },
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(AppIcons.modules, size: 20, color: scheme.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The type is the name: a file is created once per season,
                  // so there is nothing to tell two of them apart by.
                  Text(
                    module.moduleTypeName?.of(context) ?? '—',
                    style: text.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (module.startsOn != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${l.moduleStartDate}: ${formatDate(module.startsOn)}',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (module.seasonHijriYear != null)
                        GlassBadge(
                          label: l.seasonHijriYear(module.seasonHijriYear!),
                          icon: AppIcons.seasons,
                          dense: true,
                        ),
                      if (!module.isActive)
                        GlassBadge(
                          label: l.moduleBadgeDraft,
                          icon: AppIcons.edit,
                          color: AppColors.darkGold,
                          dense: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const NavChevron(),
          ],
        ),
      ),
    );
  }
}

/// Creating a file starts by choosing its type — that choice decides what the
/// file is called, how it is structured, and which roles and tasks it carries.
/// Only types not already opened this season are offered.
class _TypePickerSheet extends StatelessWidget {
  const _TypePickerSheet({required this.types});

  final List<ModuleType> types;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      // Sizes to the content and scrolls only once it would pass the cap: three
      // types should not open a sheet built for ten.
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl + MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.moduleChooseType,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    for (final type in types)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: GlassCard(
                          blur: false,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          onTap: () => Navigator.of(context).pop(type),
                          child: Row(
                            children: [
                              Icon(
                                AppIcons.moduleType,
                                size: 20,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      type.name.of(context),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    if (type.description != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        type.description!.of(context),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const NavChevron(),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
