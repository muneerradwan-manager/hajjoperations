import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/glass_tokens.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../profile/domain/profile.dart';
import '../../application/module_editor_cubit.dart';
import '../../domain/module_type.dart';
import '../../domain/reference_item.dart';
import '../employee_picker_screen.dart';
import 'picker_sheet.dart';

/// Adds or edits one place in a file — a sector, or a hotel inside one — with
/// everyone who holds a role there.
///
/// One sheet serves both because the LEVEL decides what it asks for: a level
/// with a master-data list asks which entry (which hotel), a level without one
/// asks for a name ("القطاع الأول"), and each then asks for its own roles. A
/// third level would need no new screen.
Future<NodeDraft?> showNodeEditorSheet(
  BuildContext context, {
  required ModuleLevel level,
  required String seasonId,
  required List<Profile> employees,
  ReferenceSet? referenceSet,
  Set<String> takenEntries = const {},
  NodeDraft? existing,
  String? suggestedLabel,
}) {
  return showModalBottomSheet<NodeDraft>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _NodeEditorSheet(
      level: level,
      seasonId: seasonId,
      employees: employees,
      referenceSet: referenceSet,
      takenEntries: takenEntries,
      existing: existing,
      suggestedLabel: suggestedLabel,
    ),
  );
}

class _NodeEditorSheet extends StatefulWidget {
  const _NodeEditorSheet({
    required this.level,
    required this.seasonId,
    required this.employees,
    required this.referenceSet,
    required this.takenEntries,
    required this.existing,
    required this.suggestedLabel,
  });

  final ModuleLevel level;
  final String seasonId;

  /// The season's participants, kept for rendering the names already chosen.
  /// Choosing someone new goes to the picker page, which asks the database.
  final List<Profile> employees;
  final ReferenceSet? referenceSet;
  final Set<String> takenEntries;
  final NodeDraft? existing;
  final String? suggestedLabel;

  @override
  State<_NodeEditorSheet> createState() => _NodeEditorSheetState();
}

class _NodeEditorSheetState extends State<_NodeEditorSheet> {
  late final _label = TextEditingController(
    text: widget.existing?.label ?? widget.suggestedLabel ?? '',
  );
  late String? _entry = widget.existing?.referenceItemId;
  late final Map<String, Set<String>> _members = {
    for (final role in widget.level.roles)
      role.id: {...(widget.existing?.membersOf(role.id) ?? const <String>{})},
  };

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _pickEntry() async {
    final l = context.l10n;
    final items = widget.referenceSet?.items ?? const <ReferenceItem>[];
    final result = await showPickerSheet(
      context,
      title: widget.level.name.of(context),
      // An entry standing elsewhere in this file is left out: a hotel belongs
      // to exactly one sector, and the database refuses a second one anyway.
      options: [
        for (final i in items)
          if (i.id == _entry || !widget.takenEntries.contains(i.id))
            PickerOption(id: i.id, label: i.name.of(context)),
      ],
      selected: {?_entry},
      emptyMessage: l.referenceEmpty,
    );
    if (result != null) setState(() => _entry = result.firstOrNull);
  }

  Future<void> _pickRole(ModuleRole role) async {
    final result = await showEmployeePicker(
      context,
      title: role.name.of(context),
      seasonId: widget.seasonId,
      multiple: role.allowsMultiple,
      selected: _members[role.id] ?? const {},
    );
    if (result != null && mounted) {
      setState(() => _members[role.id] = result);
    }
  }

  void _submit() {
    Navigator.of(context).pop(
      NodeDraft(
        id: widget.existing?.id,
        referenceItemId: widget.level.isNamedByHand ? null : _entry,
        label: widget.level.isNamedByHand ? _label.text.trim() : null,
        roleMembers: _members,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final level = widget.level;
    final entry = widget.referenceSet?.items
        .where((i) => i.id == _entry)
        .firstOrNull;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        // Not ResponsiveCenter: its `Center` expands to whatever height it is
        // allowed, which here is the 0.85 cap — so a sheet with four rows in it
        // stood nearly full-height with its content marooned in the middle.
        // `heightFactor: 1` sizes this to the content instead, and the cap goes
        // back to being a cap rather than a height.
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.existing == null
                              ? l.moduleNodeAdd(level.name.of(context))
                              : l.moduleNodeEdit(level.name.of(context)),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    children: [
                      if (level.isNamedByHand)
                        TextField(
                          controller: _label,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: '${l.moduleNodeName} *',
                            prefixIcon: const Icon(AppIcons.moduleType),
                          ),
                        )
                      else
                        InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          onTap: _pickEntry,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: '${level.name.of(context)} *',
                              prefixIcon: const Icon(AppIcons.organization),
                              suffixIcon: const Icon(Icons.arrow_drop_down),
                            ),
                            child: Text(
                              entry?.name.of(context) ?? l.moduleRoleUnassigned,
                              style: entry == null
                                  ? TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      for (final role in level.roles) ...[
                        const SizedBox(height: AppSpacing.md),
                        _RolePicker(
                          role: role,
                          people: [
                            for (final e in widget.employees)
                              if ((_members[role.id] ?? const {}).contains(
                                e.id,
                              ))
                                e,
                          ],
                          onTap: () => _pickRole(role),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(AppIcons.approve),
                        label: Text(l.commonSave),
                      ),
                      SizedBox(
                        height: MediaQuery.viewPaddingOf(context).bottom,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One role and who holds it. Nothing stops the same person appearing under two
/// roles here — a sector supervisor commonly stands in as his own deputy.
class _RolePicker extends StatelessWidget {
  const _RolePicker({
    required this.role,
    required this.people,
    required this.onTap,
  });

  final ModuleRole role;
  final List<Profile> people;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      blur: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  role.isRequired
                      ? '${role.name.of(context)} *'
                      : role.name.of(context),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Icon(
                role.allowsMultiple ? AppIcons.participants : AppIcons.jobTitle,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (people.isEmpty)
            Text(
              l.moduleRoleUnassigned,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final p in people)
                  Chip(
                    avatar: ProfileAvatar(
                      photoUrl: p.photoUrl,
                      name: p.fullName,
                      radius: 11,
                    ),
                    label: Text(p.fullName),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
