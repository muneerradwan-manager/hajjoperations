import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/animations/animations.dart';
import '../../../core/attachments/attachment_picker.dart';
import '../../../core/attachments/attachments_view.dart';
import '../../../core/constants/permission_codes.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/l10n/error_text.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_accents.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/utils/arabic_search.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/info_section.dart';
import '../../../core/widgets/overflow_menu.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/states.dart';
import '../../auth/application/session_cubit.dart';
// The two screens link to each other — a file lists its people, and a person
// lists his files. Dart allows the cycle; the alternative is a router constant
// that hides which screen is actually being opened.
import '../../employees/presentation/employee_detail_screen.dart';
import '../../notifications/presentation/send_notification_sheet.dart';
import '../application/module_detail_cubit.dart';
import '../data/modules_repository.dart';
import '../domain/module_type.dart';
import '../domain/operational_module.dart';
import 'module_editor_screen.dart';
import 'widgets/cadence_label.dart';
import 'widgets/location_button.dart';
import 'widgets/star_rating.dart';

/// Everything an operational file holds, for whoever is allowed to see it: when
/// it starts and what ends it, its attachment, the duties that come with a
/// role in it, and the tree itself — every sector, the hotels under it, and who
/// to call at each.
class ModuleDetailScreen extends StatelessWidget {
  const ModuleDetailScreen({
    super.key,
    required this.moduleId,
    this.viewAsProfileId,
    this.fromOffice = false,
  });

  final String moduleId;

  /// Whose duties to show. Opened from an employee's page, the reader is asking
  /// what THAT employee is responsible for — showing the reader their own role
  /// instead would answer a question nobody asked. Null means the reader.
  final String? viewAsProfileId;

  /// Whether this file was opened from the office — إدارة الملفات — rather than
  /// from a man's own work, or from somebody's employee page.
  ///
  /// The permission is not the whole answer to "may this be edited here". A
  /// manager assigned to a tower reaches the same file down two different
  /// corridors, and under عام he is reading his own posting: the file he is
  /// serving in, the same one every other member of it sees. Putting Edit,
  /// Delete and Deactivate on that page hands him three ways to alter the
  /// season's paperwork from a list that never claimed to be about managing it
  /// — and one of them is one tap from destroying it.
  ///
  /// So the buttons wait behind BOTH: the permission, and having come in
  /// through the door that is for using it. Defaulting to false means any new
  /// way of reaching this screen is read-only until somebody says otherwise,
  /// which is the right way round for a delete button.
  final bool fromOffice;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ModuleDetailCubit(
        ModulesRepository(),
        moduleId,
        viewAsProfileId: viewAsProfileId,
      ),
      child: _View(fromOffice: fromOffice),
    );
  }
}

class _View extends StatefulWidget {
  const _View({required this.fromOffice});

  final bool fromOffice;

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
    // Both, and in that order: holding the permission is what makes the act
    // possible at all, and coming in through إدارة الملفات is what makes this
    // page the place to do it. See [ModuleDetailScreen.fromOffice].
    final canEdit =
        widget.fromOffice && session.can(PermissionCodes.modulesEdit);
    final canDelete =
        widget.fromOffice && session.can(PermissionCodes.modulesDelete);
    final canActivate =
        widget.fromOffice && session.can(PermissionCodes.modulesActivate);
    final canMembers =
        widget.fromOffice && session.can(PermissionCodes.modulesMembers);

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
                if ((canEdit || canDelete) && module != null)
                  OverflowMenu(
                    actions: [
                      if (canEdit)
                        MenuAction(
                          icon: AppIcons.edit,
                          label: l.commonEdit,
                          onSelected: () => _edit(module),
                        ),
                      if (canDelete)
                        MenuAction(
                          icon: AppIcons.delete,
                          label: l.moduleDelete,
                          isDestructive: true,
                          onSelected: _delete,
                        ),
                    ],
                  ),
              ],
            ),
            bottomNavigationBar: (canActivate && module != null)
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
              ModuleDetailStatus.loading => const SkeletonList(
                maxColumns: 1,
                panel: true,
                height: 120,
                count: 4,
              ),
              ModuleDetailStatus.error => EmptyState(
                icon: AppIcons.modules,
                title: friendlyError(context, state.error),
              ),
              ModuleDetailStatus.ready => _Body(
                state: state,
                module: module!,
                fromOffice: widget.fromOffice,
                canEdit: canEdit,
                canMembers: canMembers,
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

class _Body extends StatefulWidget {
  const _Body({
    required this.state,
    required this.module,
    required this.fromOffice,
    required this.canEdit,
    required this.canMembers,
    required this.onOpenPdf,
    required this.onBuildTree,
  });

  final ModuleDetailState state;
  final OperationalModule module;

  /// Whether this page was reached through إدارة الملفات rather than عام —
  /// the same distinction the edit/delete flags above already encode, carried
  /// separately for the acts decided inside the body (the broadcast button).
  final bool fromOffice;

  final bool canEdit;
  final bool canMembers;
  final void Function(ModuleFile file) onOpenPdf;
  final VoidCallback onBuildTree;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  /// Below this a filter bar is furniture: إدارة شؤون مكاتب البعثة has two
  /// people in it, and a search box above two names is a worse page than no
  /// search box. Files that need one have tens or hundreds.
  static const _worthFiltering = 10;

  _RosterFilter _filter = const _RosterFilter();

  ModuleDetailState get state => widget.state;
  OperationalModule get module => widget.module;
  bool get canEdit => widget.canEdit;
  bool get canMembers => widget.canMembers;

  String _display(BuildContext context, ModuleField field) =>
      displayFieldValue(context, state, field, module.data[field.key]);

  /// Every role somebody actually holds in this file, with how many hold it.
  ///
  /// Read off the postings rather than off the type: offering to filter by a
  /// role nobody was given leads to an empty screen and no explanation.
  (List<ModuleRole>, Map<String, int>) _rolesPresent() {
    final counts = <String, int>{};
    for (final m in state.members) {
      counts.update(m.roleId, (v) => v + 1, ifAbsent: () => 1);
    }
    for (final n in state.nodes) {
      for (final m in n.members) {
        counts.update(m.roleId, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    final all = <ModuleRole>[
      ...?state.type?.roles,
      for (final level in state.type?.levels ?? const <ModuleLevel>[])
        ...level.roles,
    ];
    return (all.where((r) => counts.containsKey(r.id)).toList(), counts);
  }

  /// How many postings survive the filter, over the whole file.
  int _showing() {
    if (!_filter.isActive) return state.peopleCount;
    var n = 0;
    for (final role in state.type?.roles ?? const <ModuleRole>[]) {
      for (final m in state.membersOf(role.id)) {
        if (_filter.keeps(m, role)) n++;
      }
    }
    for (final level in state.type?.levels ?? const <ModuleLevel>[]) {
      for (final node in state.nodes.where((n) => n.levelId == level.id)) {
        n += _filter.survivorsIn(node, level);
      }
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Writing to the whole file is a broadcast, and carries its own permission
    // — and, like every other act of administration on this page, it belongs
    // to the office door only. Reached from عام the file is something being
    // read, and a broadcast button on a reading page is administration leaking
    // into the general section, permission or no permission.
    final canNotify =
        widget.fromOffice &&
        context.watch<SessionCubit>().state.can(
          PermissionCodes.notificationsBroadcastModule,
        );
    final (rolesPresent, roleCounts) = _rolesPresent();
    final showing = _showing();
    final type = state.type;
    final fields = type?.fields ?? const <ModuleField>[];
    final pdfFields = fields.where((f) => f.kind == ModuleFieldKind.pdf);
    final roles = state.focusRoles;
    final focusName = state.focusName;
    final sectorLevel = state.parentLevel;
    final sectors = state.parentNodes;

    // What the file IS: its season, the days it runs between, what ends it,
    // and whatever paperwork was attached to it. None of it changes while the
    // page is open and all of it is what the rest of the page is read against
    // — which is exactly what belongs in a panel that does not scroll away.
    final facts = <Widget>[
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
          // What that date is the date of, when the type states it.
          if (type?.startCondition != null)
            InfoRow(
              icon: AppIcons.seasons,
              label: l.moduleStartCondition,
              value: type!.startCondition!.of(context),
            ),
          if (module.reportCadence.asksForReports)
            InfoRow(
              icon: AppIcons.tasks,
              label: l.moduleReportCadence,
              value: cadenceLabel(context, module.reportCadence),
            ),
          InfoRow(
            icon: AppIcons.pending,
            label: l.moduleEndCondition,
            value: (type?.endCondition ?? module.endCondition)?.of(context),
          ),
          // The condition above says what event ends files of this kind.
          // This says the day THIS one is done — shown only when somebody
          // set it, since most files run on the condition alone.
          if (module.endsOn != null)
            InfoRow(
              icon: AppIcons.pending,
              label: l.moduleEndDate,
              value: formatDate(module.endsOn),
            ),
          if ((module.decisionNumber ?? '').isNotEmpty)
            InfoRow(
              icon: AppIcons.file,
              label: l.moduleDecisionNumber,
              value: module.decisionNumber,
            ),
          for (final field in fields)
            if (field.kind != ModuleFieldKind.pdf)
              // A place is somewhere to go, never a line of URL to read.
              if (field.kind == ModuleFieldKind.location &&
                  isOpenableLocation(module.data[field.key]))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: LocationButton(
                      url: module.data[field.key] as String,
                      label: field.label.of(context),
                    ),
                  ),
                )
              else
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
          onOpen: widget.onOpenPdf,
        ),
      ],
    ];

    // The work: who is on the file, what each of them owes, and how the ground
    // is divided. All of it changes, all of it is read against the facts above,
    // and it is the part with a scrollbar.
    final work = <Widget>[
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

      if (module.reportCadence.asksForReports) ...[
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(l.moduleReports, icon: AppIcons.tasks),
        _ReportsCard(module: module, reports: state.reports),
      ],
      // What a finished file is for. Only its own people, only once it is
      // over, and only ever their own result back.
      if (state.canRate) ...[
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(l.moduleRatingSection, icon: AppIcons.approvals),
        _RatingCard(state: state),
      ],

      const SizedBox(height: AppSpacing.lg),
      SectionHeader(
        l.moduleMembersCount(state.peopleCount),
        icon: AppIcons.participants,
      ),

      // Writing to everyone in the file, from the page that lists them. The
      // audience is not asked for — standing here IS the answer, and a sheet
      // that opened from this button and then made you choose the file again
      // would be asking a question it had already been told.
      if (canNotify && state.peopleCount > 0) ...[
        FilledButton.tonalIcon(
          onPressed: () =>
              showSendNotificationSheet(context, moduleId: module.id),
          icon: const Icon(AppIcons.send),
          label: Text(l.moduleNotifyMembers),
        ),
        const SizedBox(height: AppSpacing.md),
      ],

      if (state.peopleCount >= _worthFiltering) ...[
        _RosterFilterBar(
          filter: _filter,
          roles: rolesPresent,
          counts: roleCounts,
          showing: showing,
          total: state.peopleCount,
          onChanged: (f) => setState(() => _filter = f),
        ),
        const SizedBox(height: AppSpacing.md),
      ],

      // Nothing survived, and the tree below has folded away entirely. Said
      // once here rather than left as a page that looks like it failed to load.
      if (_filter.isActive && showing == 0)
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(l.moduleRosterNoMatch),
        ),

      // Roles held on the file itself — the entire roster of a file with
      // no tree, and each member's share of his team's duties.
      for (final role in type?.roles ?? const <ModuleRole>[])
        _RoleRosterCard(state: state, role: role, filter: _filter),

      if (type?.hasTree ?? true)
        if (sectorLevel == null || sectors.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.moduleNoNodes),
                if (canEdit) ...[
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: widget.onBuildTree,
                    icon: const Icon(AppIcons.add),
                    // Named by the level, so the same button offers
                    // "إضافة القطاع" on one file and "إضافة المركز" on
                    // another.
                    label: Text(
                      sectorLevel == null
                          ? l.moduleBuildTree
                          : l.moduleNodeAdd(sectorLevel.name.of(context)),
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          for (final sector in sectors)
            _SectorCard(
              state: state,
              level: sectorLevel,
              sector: sector,
              filter: _filter,
            )
      else if (state.members.isEmpty)
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.moduleNoMembers),
              if (canMembers) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: widget.onBuildTree,
                  icon: const Icon(AppIcons.add),
                  label: Text(l.moduleTeamPick),
                ),
              ],
            ],
          ),
        ),
    ];

    Future<void> reload() => context.read<ModuleDetailCubit>().load();

    return ResponsivePage(
      builder: (context, size) => size.hasSidePanel
          ? TwoPaneLayout(
              gutter: size.gutter,
              // Wider than the app's usual panel: this one holds labelled rows
              // rather than a name under a face, and "شرط انتهاء الملف" beside
              // its value does not fit in three hundred pixels.
              panelWidth: 380,
              panel: FadeSlideIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: facts,
                ),
              ),
              onRefresh: reload,
              children: staggered(work),
            )
          : SinglePaneLayout(
              gutter: size.gutter,
              onRefresh: reload,
              children: staggered([...facts, ...work]),
            ),
    );
  }
}

/// What the reader is currently looking for in a file's roster.
///
/// A file is not a small thing — تشكيل فرق المشاعر holds two hundred and
/// fourteen postings across seven قطاعات — and until now the only way to find
/// one man in it was to scroll. This narrows the whole screen at once: the tree
/// keeps its shape, and the places with nobody left in them fold away.
///
/// View state, deliberately. It answers a question the reader is asking right
/// now, it should not survive a reload, and it belongs to no one but this
/// screen — so it lives in the widget rather than in the cubit's state.
class _RosterFilter {
  const _RosterFilter({this.query = '', this.roleId});

  final String query;

  /// Narrowed to holders of one role — "show me the مشرفون". Null for all.
  final String? roleId;

  bool get isActive => query.trim().isNotEmpty || roleId != null;

  /// Whether this posting survives, under the role it is held here.
  ///
  /// The role's own name is searched alongside the person's, because "مشرف
  /// البرج" is a thing a reader types into a box that is sitting above a list
  /// of them. Spelling is folded the way the directory folds it: أ and ا are
  /// one letter here too.
  bool keeps(ModuleMember member, ModuleRole role) {
    if (roleId != null && role.id != roleId) return false;
    if (query.trim().isEmpty) return true;
    final p = member.profile;
    return arabicMatchesAll([
      p?.firstName,
      p?.fatherName,
      p?.surname,
      p?.fullName,
      p?.jobTitleName?.ar,
      p?.jobTitleName?.en,
      role.name.ar,
      role.name.en,
    ], query);
  }

  /// How many of [node]'s postings survive, under [level]'s roles.
  int survivorsIn(ModuleNode node, ModuleLevel level) {
    var n = 0;
    for (final role in level.roles) {
      for (final member in node.membersOf(role.id)) {
        if (keeps(member, role)) n++;
      }
    }
    return n;
  }
}

/// The search box and the role chips that narrow a file's roster.
///
/// The chips are the roles this file actually has somebody in — not the type's
/// catalogue. A file where nobody was ever made نائب should not offer to filter
/// by نائب and then show an empty screen.
class _RosterFilterBar extends StatefulWidget {
  const _RosterFilterBar({
    required this.filter,
    required this.roles,
    required this.counts,
    required this.showing,
    required this.total,
    required this.onChanged,
  });

  final _RosterFilter filter;
  final List<ModuleRole> roles;

  /// How many people hold each role here, shown on its chip.
  final Map<String, int> counts;

  final int showing;
  final int total;
  final ValueChanged<_RosterFilter> onChanged;

  @override
  State<_RosterFilterBar> createState() => _RosterFilterBarState();
}

class _RosterFilterBarState extends State<_RosterFilterBar> {
  late final _controller = TextEditingController(text: widget.filter.query);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final f = widget.filter;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onChanged: (v) =>
                widget.onChanged(_RosterFilter(query: v, roleId: f.roleId)),
            decoration: InputDecoration(
              isDense: true,
              hintText: l.moduleRosterSearchHint,
              prefixIcon: const Icon(AppIcons.search, size: 20),
              suffixIcon: f.query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(AppIcons.reject, size: 18),
                      onPressed: () {
                        _controller.clear();
                        widget.onChanged(_RosterFilter(roleId: f.roleId));
                      },
                    ),
            ),
          ),
          if (widget.roles.length > 1) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                ChoiceChip(
                  label: Text(l.moduleRosterAllRoles),
                  selected: f.roleId == null,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) =>
                      widget.onChanged(_RosterFilter(query: f.query)),
                ),
                for (final role in widget.roles)
                  ChoiceChip(
                    label: Text(
                      '${role.name.of(context)} (${widget.counts[role.id] ?? 0})',
                    ),
                    selected: f.roleId == role.id,
                    visualDensity: VisualDensity.compact,
                    // Tapping the chip already on cancels it, so the way back
                    // to everyone is the chip under your finger.
                    onSelected: (on) => widget.onChanged(
                      _RosterFilter(
                        query: f.query,
                        roleId: on && f.roleId != role.id ? role.id : null,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (f.isActive) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.moduleRosterShowing(widget.showing, widget.total),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: widget.showing == 0
                          ? scheme.error
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged(const _RosterFilter());
                  },
                  child: Text(l.moduleRosterClear),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The narrowest a member may get before a roster drops a column.
///
/// A member is a face, a name under it and up to three dialable numbers in a
/// row. Below this the numbers start wrapping one to a line, and the card grows
/// taller than the column it just saved — which is the opposite of the point.
const _kMemberWidth = 340.0;

/// The same, for a roster nested inside a node's card.
///
/// A grid measures the box it is given, and inside the card that box is already
/// two paddings narrower than the one the file-level rosters get. Asked for the
/// full [_kMemberWidth] it therefore drops a column before they do — at 1200,
/// where the side panel first appears and the content pane is at its narrowest,
/// مخيمات عرفات would stand in one column while the team beside it stood in
/// two. Giving back a gutter's width is what keeps the tree columning in step
/// with everything else on the screen.
const _kNestedMemberWidth = _kMemberWidth - AppSpacing.lg;

/// One team of a file with no tree: everyone on it, and under each of them the
/// duties he was actually handed.
///
/// The duties are on the roster rather than tucked behind a tap because that is
/// what this file is for — "who is doing the passports" is the question it
/// exists to answer.
class _RoleRosterCard extends StatelessWidget {
  const _RoleRosterCard({
    required this.state,
    required this.role,
    this.filter = const _RosterFilter(),
  });

  final ModuleDetailState state;
  final ModuleRole role;
  final _RosterFilter filter;

  @override
  Widget build(BuildContext context) {
    final members = state
        .membersOf(role.id)
        .where((m) => filter.keeps(m, role))
        .toList();
    // A team nobody on it matches is not an empty team — it is a team the
    // reader is not asking about, so it goes rather than showing a heading
    // over nothing.
    if (members.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        SectionHeader(role.name.of(context), icon: AppIcons.roles),
        // The same width every other roster on this screen uses.
        //
        // It asked for 400 once, so that a duty title would fit on one line.
        // It bought the opposite: 400 columns one step later than 340, so at
        // the widths people actually work at — a 1280 laptop, a half-screen
        // window — a FILE-LEVEL team stood in a single column while the tree
        // beside it stood in two. Two files in three carry such a team, so most
        // of the catalog read as though it were laid out differently from
        // مخيمات عرفات, which happens to have none.
        //
        // And the line it was protecting does not exist: a duty is a sentence,
        // it wraps at 400 as readily as at 340. A column was traded for a wrap
        // that happened anyway.
        AdaptiveGrid(
          minTileWidth: _kMemberWidth,
          children: [
            for (final member in members)
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MemberTile(member: member, dense: true),
                    ..._duties(context, member.taskIds),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
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
    this.filter = const _RosterFilter(),
  });

  final ModuleDetailState state;
  final ModuleLevel level;
  final ModuleNode sector;
  final _RosterFilter filter;

  @override
  Widget build(BuildContext context) {
    final towerLevel = state.childLevel;
    final towers = state.childrenOf(sector.id);

    // Whoever runs the sector itself, in the order the level lists the roles.
    final supervisors = <Widget>[
      for (final role in level.roles)
        for (final member in sector.membersOf(role.id))
          if (filter.keeps(member, role))
            _MemberTile(member: member, roleName: role.name.of(context)),
    ];

    // A whole قطاع with nobody matching in it, nor in any برج beneath it, is
    // not part of the answer — so the sector folds away rather than standing
    // as a heading over a gap.
    if (filter.isActive) {
      final below = towerLevel == null
          ? 0
          : towers.fold<int>(
              0,
              (n, t) => n + filter.survivorsIn(t, towerLevel),
            );
      if (supervisors.isEmpty && below == 0) return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        SectionHeader(
          sector.label ?? level.name.of(context),
          icon: AppIcons.roles,
        ),
        if (supervisors.isNotEmpty) ...[
          AdaptiveGrid(minTileWidth: _kMemberWidth, children: supervisors),
          const SizedBox(height: AppSpacing.md),
        ],
        if (towerLevel != null)
          for (final tower in towers)
            _TowerCard(
              state: state,
              level: towerLevel,
              tower: tower,
              filter: filter,
            ),
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
    this.filter = const _RosterFilter(),
  });

  final ModuleDetailState state;
  final ModuleLevel level;
  final ModuleNode tower;
  final _RosterFilter filter;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final entry = state.referenceItem(
      level.referenceSetId,
      tower.referenceItemId,
    );
    // What the tower is tied to — its تكتل. Resolved against every season's
    // entries, never just this one: last season's file must still read.
    final tied = state.referenceItem(
      level.secondaryReferenceSetId,
      tower.secondaryReferenceItemId,
    );
    final tiedSet = state.referenceSetById(level.secondaryReferenceSetId);
    final entrySet = state.referenceSetById(level.referenceSetId);

    // Everyone serving in this tower — the supervisor, his deputies and the
    // mission members — each carrying the role he is here under.
    final serving = <Widget>[
      for (final role in level.roles)
        for (final member in tower.membersOf(role.id))
          if (filter.keeps(member, role))
            _MemberTile(
              member: member,
              roleName: role.name.of(context),
              dense: true,
            ),
    ];

    // The برج itself is only shown while it still has somebody the reader is
    // looking for. Its hotel, its تكتل and its capacity are context for the
    // people in it, not an answer on their own.
    if (filter.isActive && serving.isEmpty) return const SizedBox.shrink();

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
                if (tied != null)
                  GlassBadge(
                    label: tied.name.of(context),
                    icon: AppIcons.participants,
                    dense: true,
                  ),
              ],
            ),
            if (tiedSet != null && tied == null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  '${tiedSet.name.of(context)}: ${l.moduleRoleUnassigned}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            // What the node itself carries — the الطاقة الاستيعابية of a مخيم,
            // and where it is. Empty for a level that asks for nothing further,
            // which is every level but one.
            for (final field in level.fields)
              if (field.kind == ModuleFieldKind.location)
                if (isOpenableLocation(tower.data[field.key]))
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: LocationButton(
                      url: tower.data[field.key] as String,
                      label: field.label.of(context),
                      dense: true,
                    ),
                  )
                else
                  const SizedBox.shrink()
              else if (displayFieldValue(
                    context,
                    state,
                    field,
                    tower.data[field.key],
                  )
                  case final text when text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Row(
                    children: [
                      Text(
                        '${field.label.of(context)}: ',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          text,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
            // And the place of the ENTRY this node stands for — the فندق behind
            // a برج keeps its address in the hotels list, not on the node.
            for (final field in entrySet?.fields ?? const <ModuleField>[])
              if (field.kind == ModuleFieldKind.location &&
                  isOpenableLocation(entry?.data[field.key]))
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: LocationButton(
                    url: entry!.data[field.key] as String,
                    label: field.label.of(context),
                    dense: true,
                  ),
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
            if (serving.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                // No card of their own inside this one, so the gutter between
                // two of them has to be wide enough to read as a gutter — and
                // no forced equal heights, because there is no bottom edge to
                // line up.
                child: AdaptiveGrid(
                  minTileWidth: _kNestedMemberWidth,
                  spacing: AppSpacing.lg,
                  equalHeights: false,
                  children: serving,
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
                color: Accent.gold.of(context),
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
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Text(
              role.description!.of(context),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.6),
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
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
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
  const _MemberTile({required this.member, this.roleName, this.dense = false});

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
                      profile.jobTitleName!.of(context),
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

    // The roster is a list of people, and a person on this screen is somebody
    // you may need to know more about than his phone number — which season he
    // has served, what else he is assigned to, how to reach him a second way.
    // All of that is already a page; this is the link to it.
    //
    // The profile travels with the tap rather than being fetched again: the
    // roster query already embeds it whole, and the detail screen takes one.
    void open() => Navigator.of(context).push(
      fadeThroughRoute((_) => EmployeeDetailScreen(profile: profile)),
    );

    if (dense) {
      // No card of its own here, so the tap needs a shape to land in — and a
      // little padding, so the ripple does not stop at the text's edge.
      return InkWell(
        onTap: open,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: body,
        ),
      );
    }
    return GlassCard(
      onTap: open,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: body,
    );
  }
}

/// Renders a stored value the way its field kind means it to be read.
///
/// Takes the value rather than reading it off the file, because a node carries
/// its own now: the الطاقة الاستيعابية of a مخيم is the same kind of fact as a
/// field of the file, and is read the same way.
String displayFieldValue(
  BuildContext context,
  ModuleDetailState state,
  ModuleField field,
  Object? value,
) => switch (field.kind) {
  ModuleFieldKind.reference =>
    state.referenceItem(field.referenceSetId, value)?.name.of(context) ?? '',
  ModuleFieldKind.date => formatDate(
    value is String ? DateTime.tryParse(value) : null,
  ),
  ModuleFieldKind.pdf => ModuleFile.fromJson(value)?.name ?? '',
  _ => value?.toString() ?? '',
};

/// The rating of a finished file: what the viewer received, and a star row per
/// colleague for what he thinks of them.
///
/// Everyone in the file appears once, wherever they sit in it — a tower member
/// may rate the supervisor of his sector, because they carried the same file.
/// The viewer is not in his own list.
class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.state});

  final ModuleDetailState state;

  /// Everyone in the file but the viewer, each appearing once however many
  /// roles they hold in it.
  List<ModuleMember> _colleagues(String me) {
    final seen = <String>{me};
    final out = <ModuleMember>[];
    for (final m in [
      ...state.members,
      for (final n in state.nodes) ...n.members,
    ]) {
      if (seen.add(m.profileId)) out.add(m);
    }
    return out;
  }

  Future<void> _rate(BuildContext context, String rateeId, int? stars) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<ModuleDetailCubit>().rate(rateeId, stars);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            error ??
                (stars == null ? l.moduleRatingCleared : l.moduleRatingSaved),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final me = supabase.auth.currentUser?.id;
    if (me == null) return const SizedBox.shrink();
    final summary = state.myRatingSummary;
    final colleagues = _colleagues(me);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.moduleRatingMine, style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          if (summary.isRated)
            RatingSummaryLine(
              average: summary.average,
              ratings: summary.ratings,
              label: l.moduleRatingValue(
                summary.average.toStringAsFixed(1),
                summary.ratings,
              ),
            )
          else
            Text(
              l.moduleRatingNone,
              style: text.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(l.moduleRatingRate, style: text.titleSmall),
          const SizedBox(height: 2),
          // Said out loud, and said BEFORE the stars: somebody about to rate a
          // colleague is entitled to know who will see it.
          Text(
            l.moduleRatingAnonymous,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (colleagues.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              // A name and five stars need less room than a member card does, so
              // this one columns earlier — a file of thirty people is otherwise
              // thirty rows of stars against a mostly empty card.
              child: AdaptiveGrid(
                minTileWidth: 300,
                spacing: AppSpacing.lg,
                equalHeights: false,
                children: [
                  for (final colleague in colleagues)
                    Row(
                      children: [
                        ProfileAvatar(
                          photoUrl: colleague.profile?.photoUrl,
                          name: colleague.profile?.fullName ?? '',
                          radius: 16,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            colleague.profile?.fullName ?? '—',
                            style: text.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StarRating(
                          value: (state.myRatings[colleague.profileId] ?? 0)
                              .toDouble(),
                          size: 20,
                          onRated: (stars) =>
                              _rate(context, colleague.profileId, stars),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The reports of one file: a way in for whoever is in it, and the ones already
/// filed underneath.
///
/// RLS decides what "already filed" means — a member sees their own, a manager
/// sees everyone's — so this widget renders whatever came back without asking
/// who is looking.
class _ReportsCard extends StatelessWidget {
  const _ReportsCard({required this.module, required this.reports});

  final OperationalModule module;
  final List<ModuleReport> reports;

  Future<void> _file(BuildContext context) async {
    final l = context.l10n;
    final cubit = context.read<ModuleDetailCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final filed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => BlocProvider.value(
        value: cubit,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: _ReportSheet(existing: cubit.state.myReportForThisPeriod),
        ),
      ),
    );
    if (filed != true) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.moduleReportSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final state = context.watch<ModuleDetailCubit>().state;
    final mine = state.myReportForThisPeriod;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Only someone actually in the file may file one — the database says
          // so too, and this keeps the button from being a trap.
          if (state.isMember)
            OutlinedButton.icon(
              onPressed: () => _file(context),
              icon: const Icon(AppIcons.attach),
              label: Text(
                mine == null ? l.moduleReportWrite : l.moduleReportEdit,
              ),
            ),
          if (reports.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                l.moduleReportsEmpty,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            for (final report in reports)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: _ReportTile(report: report),
              ),
        ],
      ),
    );
  }
}

/// One report as it is read: who filed it and for when, what came with it, and
/// their notes underneath if they left any.
class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report});

  final ModuleReport report;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final notes = report.notes?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                report.author?.fullName ?? '',
                style: text.titleSmall,
              ),
            ),
            Text(
              formatDate(report.periodStart ?? report.createdAt),
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        AttachmentsView(
          attachments: report.attachments,
          signer: context.read<ModuleDetailCubit>().signAttachment,
        ),
        // A report with neither is not possible to file, but one filed before
        // attachments existed has only notes, and one filed since may have only
        // files — so both sides are optional here.
        if (report.attachments.isEmpty && notes.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              l.moduleReportNothingAttached,
              style: text.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        if (notes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(notes, style: text.bodyMedium?.copyWith(height: 1.5)),
          ),
      ],
    );
  }
}

/// Filing one: the files themselves, and a box for notes if there are any.
///
/// Re-opened for a report already filed this period, it shows what is on it —
/// attachments can be taken back off, more added, the notes rewritten — because
/// the database edits that report rather than adding a second.
class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.existing});

  final ModuleReport? existing;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');

  /// What is already filed, minus whatever has been taken off in this sheet.
  late final _kept = [...?widget.existing?.attachments];
  final _removed = <StoredAttachment>[];
  final _added = <PendingAttachment>[];
  bool _busy = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _attach() async {
    final picked = await pickAttachment(context);
    if (picked != null) setState(() => _added.add(picked));
  }

  /// A report is the things attached to it, so there is nothing to file until
  /// something is.
  bool get _canFile => _kept.isNotEmpty || _added.isNotEmpty;

  Future<void> _save() async {
    setState(() => _busy = true);
    final notes = _notes.text.trim();
    final error = await context.read<ModuleDetailCubit>().submitReport(
      notes: notes.isEmpty ? null : notes,
      attachments: _added,
      removed: _removed,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null
                  ? l.moduleReportWrite
                  : l.moduleReportEdit,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l.moduleReportAttachHint,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final attachment in _kept)
              _KeptAttachmentRow(
                attachment: attachment,
                onRemove: _busy
                    ? null
                    : () => setState(() {
                        _kept.remove(attachment);
                        _removed.add(attachment);
                      }),
              ),
            for (var i = 0; i < _added.length; i++)
              PendingAttachmentRow(
                attachment: _added[i],
                onRemove: _busy
                    ? null
                    : () => setState(() => _added.removeAt(i)),
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _busy ? null : _attach,
                icon: const Icon(AppIcons.attach, size: 18),
                label: Text(l.notificationAttach),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _notes,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l.moduleReportNotes,
                helperText: l.moduleReportNotesHint,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _busy || !_canFile ? null : _save,
              icon: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(AppIcons.approve),
              label: Text(l.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}

/// An attachment already filed, in the sheet that is editing it.
class _KeptAttachmentRow extends StatelessWidget {
  const _KeptAttachmentRow({required this.attachment, this.onRemove});

  final StoredAttachment attachment;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            attachmentIcon(attachment.kind),
            size: 18,
            color: scheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              attachment.name,
              style: text.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: context.l10n.commonDelete,
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            icon: const Icon(AppIcons.delete, size: 16),
          ),
        ],
      ),
    );
  }
}
