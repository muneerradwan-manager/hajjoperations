import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/states.dart';
import '../../modules/presentation/widgets/picker_sheet.dart';
import '../application/audit_cubit.dart';
import '../data/audit_repository.dart';
import '../domain/audit_event.dart';
import '../domain/audit_labels.dart';
import 'widgets/audit_event_sheet.dart';
import 'widgets/audit_pulse.dart';
import 'widgets/audit_style.dart';

/// The log itself: everything that happened, newest first, narrowed by who,
/// what kind of act, which section, when — and read line by line.
class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuditCubit(AuditRepository()),
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
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Search waits for the typing to pause: every keystroke is a server round
  /// trip otherwise, and the answer to "أح" is not worth one.
  void _onQuery(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final cubit = context.read<AuditCubit>();
      cubit.setFilters(cubit.state.filters.copyWith(query: value));
    });
  }

  Future<void> _pickAction() async {
    final l = context.l10n;
    final cubit = context.read<AuditCubit>();
    final current = cubit.state.filters.action;
    final result = await showPickerSheet(
      context,
      title: l.auditFilterAction,
      options: [
        for (final action in AuditAction.values)
          PickerOption(
            id: action.name,
            label: auditActionLabel(context, action),
          ),
      ],
      selected: {if (current != null) current.name},
    );
    if (result == null) return;
    cubit.setFilters(
      cubit.state.filters.copyWith(
        action: result.isEmpty ? null : AuditAction.fromName(result.first),
      ),
    );
  }

  Future<void> _pickEntity() async {
    final l = context.l10n;
    final cubit = context.read<AuditCubit>();
    final result = await showPickerSheet(
      context,
      title: l.auditFilterEntity,
      options: [
        for (final group in AuditLabels.groups)
          PickerOption(id: group.key, label: group.name.of(context)),
      ],
      selected: {?cubit.state.filters.groupKey},
    );
    if (result == null) return;
    cubit.setFilters(
      cubit.state.filters.copyWith(
        groupKey: result.isEmpty ? null : result.first,
      ),
    );
  }

  Future<void> _pickActor() async {
    final l = context.l10n;
    final cubit = context.read<AuditCubit>();
    final List<AuditActor> actors;
    try {
      actors = await cubit.actors();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l.commonConnectionErrorTitle)),
        );
      return;
    }
    if (!mounted) return;
    final result = await showPickerSheet(
      context,
      title: l.auditFilterActor,
      options: [
        for (final actor in actors)
          PickerOption(
            id: actor.id,
            label: actor.name ?? l.auditSystem,
            photoUrl: actor.photoUrl,
            showAvatar: true,
          ),
      ],
      selected: {?cubit.state.filters.actor?.id},
    );
    if (result == null) return;
    cubit.setFilters(
      cubit.state.filters.copyWith(
        actor: result.isEmpty
            ? null
            : actors.firstWhere((a) => a.id == result.first),
      ),
    );
  }

  Future<void> _pickDates() async {
    final cubit = context.read<AuditCubit>();
    final filters = cubit.state.filters;
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: filters.from == null || filters.to == null
          ? null
          : DateTimeRange(start: filters.from!, end: filters.to!),
    );
    if (range == null) return;
    cubit.setFilters(filters.copyWith(from: range.start, to: range.end));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      appBar: GlassAppBar(title: Text(l.navAuditLog)),
      body: SafeArea(
        child: BlocBuilder<AuditCubit, AuditState>(
          builder: (context, state) {
            return ResponsivePage(
              maxWidth: 1200,
              builder: (context, size) => Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      size.gutter,
                      AppSpacing.md,
                      size.gutter,
                      AppSpacing.sm,
                    ),
                    child: _FilterBar(
                      filters: state.filters,
                      onQuery: _onQuery,
                      onAction: _pickAction,
                      onEntity: _pickEntity,
                      onActor: _pickActor,
                      onDates: _pickDates,
                      onClear: () => context.read<AuditCubit>().clearFilters(),
                    ),
                  ),
                  Expanded(child: _Body(state: state, gutter: size.gutter)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.gutter});

  final AuditState state;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    if (state.status == AuditStatus.loading) {
      return const SkeletonList(
        count: 6,
        minTileWidth: 380,
        maxColumns: 2,
        padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
      );
    }
    if (state.status == AuditStatus.error) {
      return EmptyState(
        icon: AppIcons.auditLog,
        title: l.commonConnectionErrorTitle,
        message: l.commonConnectionErrorBody,
        action: FilledButton(
          onPressed: () => context.read<AuditCubit>().load(),
          child: Text(l.commonRetry),
        ),
      );
    }
    if (state.events.isEmpty) {
      return EmptyState(
        icon: AppIcons.auditLog,
        title: l.auditEmptyTitle,
        message: l.auditEmptyBody,
      );
    }

    // The next page arrives before the reader hits the bottom, not after.
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 400) {
          context.read<AuditCubit>().loadMore();
        }
        return false;
      },
      child: AdaptiveGridView(
        padding: EdgeInsets.fromLTRB(
          gutter,
          4,
          gutter,
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        onRefresh: () => context.read<AuditCubit>().load(),
        // The shape of what is being read, above what is being read — and only
        // once it has arrived. It is counted in a second call that may still be
        // in flight or may have failed, and neither is a reason to hold up the
        // register or to draw an empty frame where a chart is going to be.
        header: state.summary == null
            ? null
            : AuditPulse(summary: state.summary!),
        minTileWidth: 380,
        maxColumns: 2,
        spacing: 10,
        itemCount: state.events.length + (state.loadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= state.events.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            );
          }
          final event = state.events[i];
          return FadeSlideIn(
            // Cap the cascade so a row first built deep in the scroll doesn't
            // sit invisible for seconds (same rule as the inbox).
            delay: Duration(milliseconds: 25 * (i < 8 ? i : 8)),
            child: _EventCard(event: event),
          );
        },
      ),
    );
  }
}

/// Search on top, the four knobs under it, and — only once something is
/// narrowed — the way back to everything.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filters,
    required this.onQuery,
    required this.onAction,
    required this.onEntity,
    required this.onActor,
    required this.onDates,
    required this.onClear,
  });

  final AuditFilters filters;
  final ValueChanged<String> onQuery;
  final VoidCallback onAction;
  final VoidCallback onEntity;
  final VoidCallback onActor;
  final VoidCallback onDates;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    String dateLabel() {
      if (filters.from == null || filters.to == null) return l.auditFilterDate;
      String d(DateTime v) => '${v.month}/${v.day}';
      return '${d(filters.from!)} – ${d(filters.to!)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: l.auditSearchHint,
            prefixIcon: const Icon(AppIcons.search),
            isDense: true,
          ),
          onChanged: onQuery,
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: filters.action == null
                    ? l.auditFilterAction
                    : auditActionLabel(context, filters.action!),
                active: filters.action != null,
                onTap: onAction,
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterChip(
                label: filters.groupKey == null
                    ? l.auditFilterEntity
                    : AuditLabels.groups
                          .firstWhere((g) => g.key == filters.groupKey)
                          .name
                          .of(context),
                active: filters.groupKey != null,
                onTap: onEntity,
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterChip(
                label: filters.actor?.name ?? l.auditFilterActor,
                active: filters.actor != null,
                onTap: onActor,
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterChip(
                label: dateLabel(),
                active: filters.from != null,
                onTap: onDates,
              ),
              if (!filters.isEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                TextButton.icon(
                  onPressed: onClear,
                  icon: Icon(AppIcons.reject, size: 16, color: scheme.error),
                  label: Text(
                    l.auditClearFilters,
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      emphasised: active,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 8,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: active ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: active ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// One line of the log: the act's icon in its colour, what it was about, who
/// did it and when. Tapping opens the full account of it.
class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final AuditEvent event;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = auditActionColor(context, event.action);

    return GlassCard(
      onTap: () => showAuditEventSheet(context, event),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
              child: Icon(auditActionIcon(event.action), size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auditTitle(context, event),
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    auditSubtitle(context, event),
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ProfileAvatar(
                        photoUrl: event.actorPhotoUrl,
                        name: event.actorName ?? l.auditSystem,
                        radius: 9,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          event.actorName ?? l.auditSystem,
                          style: text.labelSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        auditFmtTime(event.occurredAt),
                        style: text.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
