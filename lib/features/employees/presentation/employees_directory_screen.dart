import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/constants/permission_codes.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/employee_tile.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/states.dart';
import '../../auth/application/session_cubit.dart';
import '../../profile/domain/profile.dart';
import '../application/employees_directory_cubit.dart';
import '../../seasons/data/seasons_repository.dart';
import '../data/employees_repository.dart';
import 'create_employee_screen.dart';
import 'employee_detail_screen.dart';

class EmployeesDirectoryScreen extends StatelessWidget {
  const EmployeesDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          EmployeesDirectoryCubit(EmployeesRepository(), SeasonsRepository()),
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
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openCreate(BuildContext context) async {
    final cubit = context.read<EmployeesDirectoryCubit>();
    final created = await Navigator.of(
      context,
    ).push<bool>(fadeThroughRoute((_) => const CreateEmployeeScreen()));
    if (created == true) cubit.load();
  }

  /// Case-insensitive match across the fields a user would actually search by.
  ///
  /// A job title is matched in BOTH languages, whichever the app is set to:
  /// someone reading an English list may still search "طبيب", and the two names
  /// are the same title.
  List<Profile> _filter(List<Profile> source) {
    if (_query.isEmpty) return source;
    final q = _query.toLowerCase();
    return source.where((e) {
      final title = e.jobTitleName;
      return e.fullName.toLowerCase().contains(q) ||
          (title?.ar ?? '').toLowerCase().contains(q) ||
          (title?.en ?? '').toLowerCase().contains(q) ||
          (e.externalOrganization ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: GlassAppBar(
          title: Text(l.navEmployees),
          actions: [
            Builder(
              builder: (context) {
                final canCreate = context.watch<SessionCubit>().state.can(
                  PermissionCodes.employeesCreate,
                );
                if (!canCreate) return const SizedBox.shrink();
                return IconButton(
                  tooltip: l.createEmployeeTitle,
                  icon: const Icon(AppIcons.addUser),
                  onPressed: () => _openCreate(context),
                );
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l.employeesPermanentSection),
              Tab(text: l.employeesExternalSection),
            ],
          ),
        ),
        body: SafeArea(
          child: BlocConsumer<EmployeesDirectoryCubit, EmployeesDirectoryState>(
            listenWhen: (p, c) => c.error != null && p.error != c.error,
            listener: (context, state) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.error!)));
            },
            builder: (context, state) {
              if (state.status == DirectoryStatus.loading) {
                return const SkeletonList(count: 7, height: 70);
              }
              return Column(
                children: [
                  ResponsiveCenter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.xs,
                      ),
                      child: _SearchField(
                        controller: _search,
                        hint: l.commonSearch,
                        onChanged: (v) => setState(() => _query = v.trim()),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _EmployeeList(
                          employees: _filter(state.permanent),
                          emptyTitle: l.employeesEmpty,
                          searching: _query.isNotEmpty,
                          onRefresh: () =>
                              context.read<EmployeesDirectoryCubit>().load(),
                        ),
                        _EmployeeList(
                          employees: _filter(state.external),
                          emptyTitle: l.employeesExternalEmpty,
                          searching: _query.isNotEmpty,
                          onRefresh: () =>
                              context.read<EmployeesDirectoryCubit>().load(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped glass search box with a clear affordance once text is entered.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(AppIcons.search, size: 20),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide(color: context.glass.stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide(color: context.glass.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.6,
          ),
        ),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(AppIcons.reject, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
        ),
      ),
    );
  }
}

class _EmployeeList extends StatelessWidget {
  const _EmployeeList({
    required this.employees,
    required this.emptyTitle,
    required this.searching,
    required this.onRefresh,
  });

  final List<Profile> employees;
  final String emptyTitle;
  final bool searching;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (employees.isEmpty) {
      return EmptyState(
        icon: searching ? AppIcons.search : AppIcons.employees,
        title: searching ? context.l10n.commonSearch : emptyTitle,
        message: searching ? emptyTitle : null,
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ResponsiveCenter(
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg + MediaQuery.viewPaddingOf(context).bottom,
          ),
          itemCount: employees.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, i) {
            final e = employees[i];
            return FadeSlideIn(
              // Cap the cascade so row 40 doesn't wait a second to appear.
              delay: Duration(milliseconds: 30 * (i < 8 ? i : 8)),
              child: EmployeeTile(
                name: e.fullName,
                photoUrl: e.photoUrl,
                subtitle: e.isExternal
                    ? e.externalOrganization
                    : e.jobTitleName?.of(context),
                isExternal: e.isExternal,
                onTap: () => Navigator.of(context).push(
                  fadeThroughRoute((_) => EmployeeDetailScreen(profile: e)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
