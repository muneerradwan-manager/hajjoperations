import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/selection_indicator.dart';
import '../../../core/widgets/states.dart';
import '../application/employee_picker_cubit.dart';
import '../data/modules_repository.dart';
import '../domain/assignable_employee.dart';

/// Chooses the people for one role in a file.
///
/// A page, not a sheet. Choosing who runs a tower is not a quick confirmation —
/// it is a decision made against what each candidate already carries, and it
/// needs the room to show that: the name, the job title, whether they are from
/// outside the mission, and every other file they are already serving in.
///
/// Pops the new selection, or null when backed out of.
Future<Set<String>?> showEmployeePicker(
  BuildContext context, {
  required String title,
  required String seasonId,
  required Set<String> selected,
  bool multiple = true,
}) {
  return Navigator.of(context).push<Set<String>>(
    fadeThroughRoute(
      (_) => EmployeePickerScreen(
        title: title,
        seasonId: seasonId,
        selected: selected,
        multiple: multiple,
      ),
      // Opened from the sector/tower sheet as often as from a page, and a modal
      // sheet does not fade itself out the way a page does — left transparent,
      // it and its barrier show straight through this one.
      opaque: true,
    ),
  );
}

class EmployeePickerScreen extends StatelessWidget {
  const EmployeePickerScreen({
    super.key,
    required this.title,
    required this.seasonId,
    required this.selected,
    this.multiple = true,
  });

  /// The role being filled — the only thing that says what this page is for.
  final String title;

  final String seasonId;
  final Set<String> selected;

  /// A supervisor is one person; mission members are many. A single-holder role
  /// takes the tap as the answer and leaves.
  final bool multiple;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EmployeePickerCubit(
        ModulesRepository(),
        seasonId: seasonId,
        selected: selected,
      ),
      child: _View(title: title, multiple: multiple),
    );
  }
}

class _View extends StatefulWidget {
  const _View({required this.title, required this.multiple});

  final String title;
  final bool multiple;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  /// Asks for the next page before the list actually runs out, so scrolling
  /// does not stop to wait.
  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      context.read<EmployeePickerCubit>().loadMore();
    }
  }

  void _tap(String profileId) {
    final cubit = context.read<EmployeePickerCubit>();
    if (widget.multiple) {
      cubit.toggle(profileId);
      return;
    }
    // One holder: the tap IS the answer. Tapping the person already chosen
    // clears the role instead.
    final wasSelected = cubit.state.selected.contains(profileId);
    Navigator.of(context).pop(wasSelected ? <String>{} : {profileId});
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return BlocBuilder<EmployeePickerCubit, EmployeePickerState>(
      builder: (context, state) {
        final cubit = context.read<EmployeePickerCubit>();

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: GlassAppBar(
            title: Text(widget.title),
            actions: [
              if (widget.multiple)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(state.selected),
                  child: Text(l.commonSave),
                ),
            ],
          ),
          body: Column(
            children: [
              _SearchBar(
                query: state.query,
                filter: state.filter,
                onChanged: cubit.search,
                onFilter: cubit.setFilter,
              ),
              Expanded(
                child: switch (state.status) {
                  PickerStatus.loading => const SkeletonList(),
                  PickerStatus.error => EmptyState(
                    icon: AppIcons.participants,
                    title: state.error ?? '',
                    action: FilledButton(
                      onPressed: cubit.refresh,
                      child: Text(l.commonRetry),
                    ),
                  ),
                  PickerStatus.ready when state.people.isEmpty => EmptyState(
                    icon: AppIcons.search,
                    title:
                        state.query.isEmpty &&
                            state.filter == ParticipantFilter.all
                        ? l.moduleNoParticipants
                        : l.modulePickerNoMatches,
                  ),
                  PickerStatus.ready => ResponsiveCenter(
                    child: RefreshIndicator(
                      onRefresh: cubit.refresh,
                      child: ListView.separated(
                        controller: _scroll,
                        // No top inset: the search bar above already cleared
                        // the app bar this list scrolls under.
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          MediaQuery.viewPaddingOf(context).bottom +
                              AppSpacing.xl,
                        ),
                        itemCount: state.people.length + 1,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) {
                          if (i == state.people.length) {
                            return _Footer(
                              loading: state.loadingMore,
                              count: state.people.length,
                            );
                          }
                          final person = state.people[i];
                          return _CandidateTile(
                            person: person,
                            isSelected: state.selected.contains(
                              person.profile.id,
                            ),
                            onTap: () => _tap(person.profile.id),
                          );
                        },
                      ),
                    ),
                  ),
                },
              ),
            ],
          ),
          bottomNavigationBar: widget.multiple
              ? GlassSurface(
                  radius: 0,
                  strong: true,
                  shadow: false,
                  bordered: false,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: FilledButton.icon(
                        onPressed: () =>
                            Navigator.of(context).pop(state.selected),
                        icon: const Icon(AppIcons.approve),
                        label: Text(
                          l.modulePickerConfirm(state.selected.length),
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

/// The search field and the internal/external filter, pinned above the list —
/// both go to the database, so neither is a view over something already here.
class _SearchBar extends StatefulWidget {
  const _SearchBar({
    required this.query,
    required this.filter,
    required this.onChanged,
    required this.onFilter,
  });

  final String query;
  final ParticipantFilter filter;
  final ValueChanged<String> onChanged;
  final ValueChanged<ParticipantFilter> onFilter;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final _controller = TextEditingController(text: widget.query);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return ResponsiveCenter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          MediaQuery.paddingOf(context).top + AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l.modulePickerSearchHint,
                prefixIcon: const Icon(AppIcons.search),
                suffixIcon: widget.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(AppIcons.reject, size: 18),
                        onPressed: () {
                          _controller.clear();
                          widget.onChanged('');
                        },
                      ),
              ),
              onChanged: widget.onChanged,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                for (final filter in ParticipantFilter.values)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.sm,
                    ),
                    child: ChoiceChip(
                      label: Text(switch (filter) {
                        ParticipantFilter.all => l.modulePickerAll,
                        ParticipantFilter.internal => l.modulePickerInternal,
                        ParticipantFilter.external => l.modulePickerExternal,
                      }),
                      selected: widget.filter == filter,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => widget.onFilter(filter),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One candidate: who they are, and what they are already carrying.
class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.person,
    required this.isSelected,
    required this.onTap,
  });

  final AssignableEmployee person;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final profile = person.profile;

    return GlassCard(
      emphasised: isSelected,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatar(
                photoUrl: profile.photoUrl,
                name: profile.fullName,
                radius: 23,
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
                            style: text.titleMedium,
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
                    if ((profile.jobTitleName?.of(context) ?? '')
                        .isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        profile.jobTitleName!.of(context),
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // An external participant belongs to somebody; naming them
                    // is half of what "external" means.
                    if (profile.isExternal &&
                        (profile.externalOrganization ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        profile.externalOrganization!,
                        style: text.bodySmall?.copyWith(color: scheme.tertiary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Several people go into a file, so this is a checkbox and an
              // empty one has to look empty — it used to be a filled disc in
              // the accent colour, which is what CHOSEN looks like.
              SelectionIndicator(
                selected: isSelected,
                shape: SelectionShape.many,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // The reason this is a page and not a sheet: somebody already running
          // a tower is not free to also run the kitchens, and that has to be
          // visible while choosing rather than discovered afterwards.
          if (person.files.isEmpty)
            Text(
              l.modulePickerFree,
              style: text.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            )
          else ...[
            Text(
              l.modulePickerAlreadyIn(person.files.length),
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                // No year: these are this season's files and nothing else, so
                // stamping every badge with the same number said nothing and
                // took the room the file's own name needed.
                for (final file in person.files)
                  GlassBadge(
                    label: file.name.of(context),
                    icon: AppIcons.modules,
                    dense: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The end of the list: the spinner that fetches the next page, or how many
/// there turned out to be.
class _Footer extends StatelessWidget {
  const _Footer({required this.loading, required this.count});

  final bool loading;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                context.l10n.moduleMembersCount(count),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
      ),
    );
  }
}
