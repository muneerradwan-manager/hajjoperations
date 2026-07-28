import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/constants/permission_codes.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/employee_tile.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../auth/application/session_cubit.dart';
import '../../profile/domain/profile.dart';
import '../application/seasons_cubit.dart';
import '../data/seasons_repository.dart';
import '../domain/season.dart';
import 'season_participants_screen.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/states.dart';

class SeasonDetailScreen extends StatefulWidget {
  const SeasonDetailScreen({super.key, required this.season});
  final Season season;

  @override
  State<SeasonDetailScreen> createState() => _SeasonDetailScreenState();
}

class _SeasonDetailScreenState extends State<SeasonDetailScreen> {
  final _repo = SeasonsRepository();
  late Future<List<Profile>> _participants;

  @override
  void initState() {
    super.initState();
    _participants = _repo.fetchParticipants(widget.season.id);
  }

  void _reload() {
    setState(() {
      _participants = _repo.fetchParticipants(widget.season.id);
    });
  }

  Future<void> _manage() async {
    await Navigator.of(context).push(
      fadeThroughRoute((_) => SeasonParticipantsScreen(season: widget.season)),
    );
    _reload();
  }

  Future<void> _setCurrent() async {
    final l = context.l10n;
    await context.read<SeasonsCubit>().setCurrent(widget.season.id);
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.seasonSetCurrentDone)));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = context.watch<SessionCubit>().state;
    final canManageParticipants = session.can(
      PermissionCodes.seasonsParticipants,
    );
    final canManageSeasons = session.can(PermissionCodes.seasonsManage);

    return Scaffold(
      appBar: GlassAppBar(
        title: Text(l.seasonHijriYear(widget.season.hijriYear)),
        actions: [
          if (canManageParticipants)
            IconButton(
              tooltip: l.seasonManageParticipants,
              onPressed: _manage,
              icon: const Icon(AppIcons.manageParticipants),
            ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: Column(
            children: [
              if (widget.season.gregorianLabel != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          AppIcons.seasons,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(widget.season.gregorianLabel!),
                        const Spacer(),
                        if (widget.season.isCurrent)
                          GlassBadge(
                            label: l.seasonBadgeCurrent,
                            icon: AppIcons.current,
                          ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: FutureBuilder<List<Profile>>(
                  future: _participants,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const SkeletonList();
                    }
                    if (snap.hasError) {
                      return Center(child: Text('${snap.error}'));
                    }
                    final people = snap.data ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.sm,
                          ),
                          child: SectionHeader(
                            l.seasonParticipantsCount(people.length),
                            icon: AppIcons.participants,
                          ),
                        ),
                        Expanded(
                          child: people.isEmpty
                              ? EmptyState(
                                  icon: AppIcons.participants,
                                  title: l.seasonNoParticipants,
                                )
                              : ListView.separated(
                                  padding: EdgeInsets.fromLTRB(
                                    AppSpacing.lg,
                                    0,
                                    AppSpacing.lg,
                                    AppSpacing.lg +
                                        MediaQuery.viewPaddingOf(
                                          context,
                                        ).bottom,
                                  ),
                                  itemCount: people.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: AppSpacing.md),
                                  itemBuilder: (context, i) {
                                    final p = people[i];
                                    return FadeSlideIn(
                                      delay: Duration(
                                        milliseconds: 30 * (i < 8 ? i : 8),
                                      ),
                                      child: EmployeeTile(
                                        name: p.fullName,
                                        photoUrl: p.photoUrl,
                                        subtitle: p.jobTitleName?.of(context),
                                        isExternal: p.isExternal,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: (!widget.season.isCurrent && canManageSeasons)
          ? GlassSurface(
              radius: 0,
              strong: true,
              shadow: false,
              bordered: false,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: FilledButton.icon(
                    onPressed: _setCurrent,
                    icon: const Icon(AppIcons.current),
                    label: Text(l.seasonSetCurrent),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
