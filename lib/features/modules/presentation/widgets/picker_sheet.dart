import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/glass_tokens.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../../core/widgets/states.dart';

/// One selectable row in a [showPickerSheet].
class PickerOption {
  const PickerOption({
    required this.id,
    required this.label,
    this.subtitle,
    this.photoUrl,
    this.showAvatar = false,
  });

  final String id;
  final String label;
  final String? subtitle;
  final String? photoUrl;

  /// People are recognised by face before name; master-data entries are not.
  final bool showAvatar;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return label.toLowerCase().contains(q) ||
        (subtitle?.toLowerCase().contains(q) ?? false);
  }
}

/// A searchable dropdown replacement. Both the master-data fields and the role
/// assignments pick from long lists of look-alike names, so search is not
/// optional — and the same sheet serves single- and multi-select roles.
///
/// Returns the new selection, or null when dismissed without confirming.
Future<Set<String>?> showPickerSheet(
  BuildContext context, {
  required String title,
  required List<PickerOption> options,
  required Set<String> selected,
  bool multiple = false,
  String? emptyMessage,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PickerSheet(
      title: title,
      options: options,
      selected: selected,
      multiple: multiple,
      emptyMessage: emptyMessage,
    ),
  );
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.multiple,
    this.emptyMessage,
  });

  final String title;
  final List<PickerOption> options;
  final Set<String> selected;
  final bool multiple;
  final String? emptyMessage;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  late final Set<String> _selected = {...widget.selected};
  String _query = '';

  void _toggle(String id) {
    if (!widget.multiple) {
      // A single-holder role: choosing replaces, and closes straight away.
      Navigator.of(context).pop(_selected.contains(id) ? <String>{} : {id});
      return;
    }
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final visible = widget.options.where((o) => o.matches(_query)).toList();
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (widget.multiple)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(_selected),
                      child: Text(l.commonSave),
                    ),
                ],
              ),
            ),
            if (widget.options.length > 8)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: TextField(
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: l.commonSearch,
                    prefixIcon: const Icon(AppIcons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            Flexible(
              child: visible.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xl,
                      ),
                      child: EmptyState(
                        icon: AppIcons.search,
                        title: widget.emptyMessage ?? l.referenceEmpty,
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.lg + MediaQuery.viewPaddingOf(context).bottom,
                      ),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        final option = visible[i];
                        final isSelected = _selected.contains(option.id);
                        return GlassCard(
                          blur: false,
                          emphasised: isSelected,
                          padding: EdgeInsets.zero,
                          onTap: () => _toggle(option.id),
                          child: ListTile(
                            leading: option.showAvatar
                                ? ProfileAvatar(
                                    photoUrl: option.photoUrl,
                                    name: option.label,
                                    radius: 20,
                                  )
                                : Icon(
                                    isSelected
                                        ? AppIcons.selected
                                        : AppIcons.unselected,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            title: Text(option.label),
                            subtitle: option.subtitle == null
                                ? null
                                : Text(option.subtitle!),
                            trailing: option.showAvatar
                                ? Icon(
                                    isSelected
                                        ? AppIcons.selected
                                        : AppIcons.unselected,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
