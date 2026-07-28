import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/password_field.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/job_title.dart';
import '../../profile/domain/profile_enums.dart';
import '../application/create_employee_cubit.dart';
import '../data/employees_repository.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/states.dart';

class CreateEmployeeScreen extends StatelessWidget {
  const CreateEmployeeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateEmployeeCubit(
        EmployeesRepository(),
        context.read<ProfileRepository>(),
      ),
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
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _firstName = TextEditingController();
  final _fatherName = TextEditingController();
  final _surname = TextEditingController();
  final _phoneSy = TextEditingController();
  final _phoneSa = TextEditingController();
  final _org = TextEditingController();
  final _externalRole = TextEditingController();

  String? _jobTitleId;
  Gender? _gender;
  MissionType? _mission;
  DateTime? _dob;
  bool _isExternal = false;

  @override
  void dispose() {
    for (final c in [
      _email,
      _password,
      _firstName,
      _fatherName,
      _surname,
      _phoneSy,
      _phoneSa,
      _org,
      _externalRole,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25),
      firstDate: DateTime(1940),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_jobTitleId == null ||
        _gender == null ||
        _mission == null ||
        _dob == null) {
      return;
    }
    context.read<CreateEmployeeCubit>().submit(
      email: _email.text,
      password: _password.text,
      firstName: _firstName.text.trim(),
      fatherName: _fatherName.text.trim(),
      surname: _surname.text.trim(),
      jobTitleId: _jobTitleId!,
      gender: _gender!,
      dateOfBirth: _dob!,
      missionType: _mission!,
      phoneSy: _phoneSy.text.trim(),
      phoneSa: _phoneSa.text.trim().isEmpty ? null : _phoneSa.text.trim(),
      isExternal: _isExternal,
      externalOrganization: _isExternal && _org.text.trim().isNotEmpty
          ? _org.text.trim()
          : null,
      externalTitle: _isExternal && _externalRole.text.trim().isNotEmpty
          ? _externalRole.text.trim()
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: GlassAppBar(title: Text(l.createEmployeeTitle)),
      body: SafeArea(
        child: BlocConsumer<CreateEmployeeCubit, CreateEmployeeState>(
          listener: (context, state) {
            if (state.status == CreateEmployeeStatus.created) {
              Navigator.of(context).pop(true);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(l.createEmployeeCreated)),
                );
            } else if (state.error != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.error!)));
            }
          },
          builder: (context, state) {
            if (state.status == CreateEmployeeStatus.loading) {
              return const AppLoader();
            }
            final submitting = state.status == CreateEmployeeStatus.submitting;
            return AbsorbPointer(
              absorbing: submitting,
              child: ResponsiveCenter(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: staggered([
                        _label(context, l.createEmployeeAccountSection),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: l.authEmail,
                            prefixIcon: const Icon(AppIcons.email),
                          ),
                          validator: (v) => Validators.isEmail(v ?? '')
                              ? null
                              : l.authInvalidEmail,
                        ),
                        const SizedBox(height: 12),
                        PasswordField(
                          controller: _password,
                          label: l.authPassword,
                          validator: (v) => (v ?? '').length < 8
                              ? l.authPasswordTooShort
                              : null,
                        ),
                        const SizedBox(height: 24),
                        _label(context, l.profileSectionPersonal),
                        const SizedBox(height: 8),
                        _text(
                          _firstName,
                          l.profileFirstName,
                          AppIcons.firstName,
                        ),
                        const SizedBox(height: 12),
                        _text(
                          _fatherName,
                          l.profileFatherName,
                          AppIcons.fatherName,
                        ),
                        const SizedBox(height: 12),
                        _text(_surname, l.profileSurname, AppIcons.surname),
                        const SizedBox(height: 12),
                        _jobTitleDropdown(l, state.jobTitles),
                        const SizedBox(height: 12),
                        _genderDropdown(l),
                        const SizedBox(height: 12),
                        _missionDropdown(l),
                        const SizedBox(height: 12),
                        _dobField(l),
                        const SizedBox(height: 12),
                        _text(
                          _phoneSy,
                          l.profilePhoneSy,
                          AppIcons.phoneSy,
                          keyboard: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _text(
                          _phoneSa,
                          '${l.profilePhoneSa} (${l.commonOptional})',
                          AppIcons.phoneSa,
                          keyboard: TextInputType.phone,
                          required: false,
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: const Icon(AppIcons.external),
                          title: Text(l.employeeIsExternal),
                          subtitle: Text(l.employeeIsExternalHint),
                          value: _isExternal,
                          onChanged: (v) => setState(() => _isExternal = v),
                        ),
                        if (_isExternal) ...[
                          const SizedBox(height: 8),
                          _text(
                            _org,
                            l.employeeOrganization,
                            AppIcons.organization,
                            required: false,
                          ),
                          const SizedBox(height: 12),
                          _text(
                            _externalRole,
                            l.employeeExternalRole,
                            AppIcons.jobTitle,
                            required: false,
                          ),
                        ],
                        const SizedBox(height: 28),
                        FilledButton(
                          onPressed: submitting ? null : _submit,
                          child: submitting
                              ? SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    strokeCap: StrokeCap.round,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                                )
                              : Text(l.createEmployeeSubmit),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => SectionHeader(text);

  Widget _text(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    bool required = true,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: required
          ? (v) => (v ?? '').trim().isEmpty ? context.l10n.commonRequired : null
          : null,
    );
  }

  Widget _jobTitleDropdown(dynamic l, List<JobTitle> titles) {
    // Sorted by the name being READ. The query orders by the Arabic column,
    // which in an English list is no order at all.
    final sorted = [...titles]
      ..sort((a, b) => a.name.of(context).compareTo(b.name.of(context)));

    return DropdownButtonFormField<String>(
      initialValue: _jobTitleId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l.profileJobTitle,
        prefixIcon: const Icon(AppIcons.jobTitle),
      ),
      items: [
        for (final t in sorted)
          DropdownMenuItem(value: t.id, child: Text(t.name.of(context))),
      ],
      validator: (v) => v == null ? l.commonRequired : null,
      onChanged: (v) => setState(() => _jobTitleId = v),
    );
  }

  Widget _genderDropdown(dynamic l) {
    return DropdownButtonFormField<Gender>(
      initialValue: _gender,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l.profileGender,
        prefixIcon: const Icon(AppIcons.gender),
      ),
      items: [
        DropdownMenuItem(value: Gender.male, child: Text(l.genderMale)),
        DropdownMenuItem(value: Gender.female, child: Text(l.genderFemale)),
      ],
      validator: (v) => v == null ? l.commonRequired : null,
      onChanged: (v) => setState(() => _gender = v),
    );
  }

  Widget _missionDropdown(dynamic l) {
    return DropdownButtonFormField<MissionType>(
      initialValue: _mission,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l.profileMissionType,
        prefixIcon: const Icon(AppIcons.mission),
      ),
      items: [
        DropdownMenuItem(
          value: MissionType.administrative,
          child: Text(l.missionAdministrative),
        ),
        DropdownMenuItem(
          value: MissionType.religious,
          child: Text(l.missionReligious),
        ),
        DropdownMenuItem(
          value: MissionType.medical,
          child: Text(l.missionMedical),
        ),
      ],
      validator: (v) => v == null ? l.commonRequired : null,
      onChanged: (v) => setState(() => _mission = v),
    );
  }

  Widget _dobField(dynamic l) {
    final text = _dob == null
        ? l.profileSelectDate
        : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: _pickDob,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l.profileDateOfBirth,
          prefixIcon: const Icon(AppIcons.dateOfBirth),
        ),
        child: Text(text),
      ),
    );
  }
}
