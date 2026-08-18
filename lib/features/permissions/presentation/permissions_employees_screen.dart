import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/error_text.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/employee_tile.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/search_field.dart';
import '../../profile/domain/profile.dart';
import '../application/employees_cubit.dart';
import '../data/permissions_repository.dart';
import 'permission_editor_screen.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/states.dart';

class PermissionsEmployeesScreen extends StatelessWidget {
  const PermissionsEmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EmployeesCubit(PermissionsRepository()),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: GlassAppBar(title: Text(l.navPermissions)),
      body: SafeArea(
        child: ResponsivePage(
          builder: (context, size) => Column(
            children: [
              SearchFilterBar(
                hint: l.commonSearch,
                onChanged: (v) => context.read<EmployeesCubit>().search(v),
              ),
              Expanded(
                child: BlocConsumer<EmployeesCubit, EmployeesState>(
                  listenWhen: (p, c) => c.error != null && p.error != c.error,
                  listener: (context, state) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(friendlyError(context, state.error))));
                  },
                  builder: (context, state) {
                    if (state.status == EmployeesStatus.loading) {
                      return const SkeletonList(
                        height: 84,
                        padding: EdgeInsets.all(AppSpacing.lg),
                      );
                    }
                    final items = state.filtered;
                    if (items.isEmpty) {
                      return EmptyState(
                        icon: AppIcons.employees,
                        title: l.employeesEmpty,
                      );
                    }
                    return AdaptiveGridView(
                      padding: EdgeInsets.fromLTRB(
                        size.gutter,
                        AppSpacing.sm,
                        size.gutter,
                        AppSpacing.lg +
                            MediaQuery.viewPaddingOf(context).bottom,
                      ),
                      onRefresh: () => context.read<EmployeesCubit>().load(),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final e = items[i];
                        return FadeSlideIn(
                          delay: Duration(milliseconds: 30 * (i < 8 ? i : 8)),
                          child: EmployeeTile(
                            name: e.fullName,
                            photoUrl: e.photoUrl,
                            subtitle: e.jobTitleName?.of(context),
                            isExternal: e.isExternal,
                            trailing: const NavChevron(),
                            onTap: () => _openEditor(context, e),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, Profile employee) {
    Navigator.of(context).push(
      fadeThroughRoute(
        (_) => PermissionEditorScreen(
          userId: employee.id,
          employeeName: employee.fullName,
        ),
      ),
    );
  }
}
