import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/widgets/image_picker_field.dart';
import '../../auth/application/session_cubit.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/widgets/settings_menu_button.dart';
import '../application/profile_completion_cubit.dart';
import '../data/profile_repository.dart';
import '../domain/job_title.dart';
import '../domain/profile.dart';
import '../domain/profile_enums.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/states.dart';

class ProfileCompletionScreen extends StatelessWidget {
  const ProfileCompletionScreen({super.key, this.existing});

  /// When provided, the screen edits this profile instead of completing a new one.
  final Profile? existing;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCompletionCubit(
        context.read<ProfileRepository>(),
        existing: existing,
      ),
      child: _ProfileCompletionView(existing: existing),
    );
  }
}

class _ProfileCompletionView extends StatefulWidget {
  const _ProfileCompletionView({this.existing});
  final Profile? existing;

  @override
  State<_ProfileCompletionView> createState() => _ProfileCompletionViewState();
}

class _ProfileCompletionViewState extends State<_ProfileCompletionView> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _surname = TextEditingController();
  final _fatherName = TextEditingController();
  final _phoneSy = TextEditingController();
  final _phoneSa = TextEditingController();

  File? _photo;
  File? _passport;
  File? _visa;
  File? _nusuk;
  String? _jobTitleId;
  Gender? _gender;
  MissionType? _mission;
  DateTime? _dob;
  bool _photoError = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _firstName.text = e.firstName ?? '';
      _fatherName.text = e.fatherName ?? '';
      _surname.text = e.surname ?? '';
      _phoneSy.text = e.phoneSy ?? '';
      _phoneSa.text = e.phoneSa ?? '';
      _jobTitleId = e.jobTitleId;
      _gender = e.gender;
      _mission = e.missionType;
      _dob = e.dateOfBirth;
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _surname.dispose();
    _fatherName.dispose();
    _phoneSy.dispose();
    _phoneSa.dispose();
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
    final formOk = _formKey.currentState?.validate() ?? false;
    // Photo required when creating; in edit mode the existing photo may stay.
    final photoMissing =
        _photo == null && (widget.existing?.photoUrl?.isEmpty ?? true);
    setState(() => _photoError = photoMissing);
    if (!formOk || photoMissing) return;

    context.read<ProfileCompletionCubit>().submit(
      firstName: _firstName.text.trim(),
      surname: _surname.text.trim(),
      fatherName: _fatherName.text.trim(),
      photo: _photo,
      jobTitleId: _jobTitleId!,
      gender: _gender!,
      dateOfBirth: _dob!,
      missionType: _mission!,
      phoneSy: _phoneSy.text.trim(),
      phoneSa: _phoneSa.text.trim().isEmpty ? null : _phoneSa.text.trim(),
      passport: _passport,
      visa: _visa,
      nusuk: _nusuk,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      appBar: GlassAppBar(
        automaticallyImplyLeading: _isEdit,
        title: Text(_isEdit ? l.myProfileEditTitle : l.profileCompleteTitle),
        actions: [
          if (!_isEdit)
            IconButton(
              tooltip: l.commonLogout,
              onPressed: () => context.read<AuthRepository>().signOut(),
              icon: const Icon(AppIcons.logout),
            ),
          const SettingsMenuButton(),
        ],
      ),
      body: BlocConsumer<ProfileCompletionCubit, ProfileCompletionState>(
        listener: (context, state) {
          if (state.status == ProfileFormStatus.submitted) {
            // Refresh the session so the router / profile view reflect changes.
            context.read<SessionCubit>().reload();
            if (_isEdit) {
              Navigator.of(context).maybePop();
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(l.myProfileSaved)));
            }
          } else if (state.status == ProfileFormStatus.error &&
              state.error != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          if (state.status == ProfileFormStatus.loading) {
            return const AppLoader();
          }
          return _buildForm(context, l, state);
        },
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    dynamic l,
    ProfileCompletionState state,
  ) {
    final submitting = state.status == ProfileFormStatus.submitting;

    return AbsorbPointer(
      absorbing: submitting,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: staggered([
                  if (!_isEdit)
                    Text(
                      l.profileCompleteSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 24),
                  Center(
                    child: ImagePickerField(
                      label: l.profilePhoto,
                      file: _photo,
                      circular: true,
                      existingUrl: widget.existing?.photoUrl,
                      errorText: _photoError ? l.commonRequired : null,
                      onPicked: (f) => setState(() {
                        _photo = f;
                        _photoError = false;
                      }),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _text(_firstName, l.profileFirstName, AppIcons.firstName),
                  const SizedBox(height: 16),
                  _text(_fatherName, l.profileFatherName, AppIcons.fatherName),
                  const SizedBox(height: 16),
                  _text(_surname, l.profileSurname, AppIcons.surname),
                  const SizedBox(height: 16),
                  _jobTitleDropdown(l, state.jobTitles),
                  const SizedBox(height: 16),
                  _genderDropdown(l),
                  const SizedBox(height: 16),
                  _missionDropdown(l),
                  const SizedBox(height: 16),
                  _dobField(l),
                  const SizedBox(height: 16),
                  _text(
                    _phoneSy,
                    l.profilePhoneSy,
                    AppIcons.phoneSy,
                    keyboard: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _text(
                    _phoneSa,
                    '${l.profilePhoneSa} (${l.commonOptional})',
                    AppIcons.phoneSa,
                    keyboard: TextInputType.phone,
                    required: false,
                  ),
                  const SizedBox(height: 28),
                  _DocumentsSection(
                    title: l.profileDocumentsSection,
                    passportLabel: l.profilePassportPhoto,
                    visaLabel: l.profileVisaPhoto,
                    nusukLabel: l.profileNusukPhoto,
                    passport: _passport,
                    visa: _visa,
                    nusuk: _nusuk,
                    onPassport: (f) => setState(() => _passport = f),
                    onVisa: (f) => setState(() => _visa = f),
                    onNusuk: (f) => setState(() => _nusuk = f),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: submitting ? null : _submit,
                    child: submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEdit ? l.commonSave : l.profileSubmitForApproval,
                          ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

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
    return DropdownButtonFormField<String>(
      initialValue: _jobTitleId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l.profileJobTitle,
        prefixIcon: const Icon(AppIcons.jobTitle),
      ),
      items: [
        for (final t in titles)
          DropdownMenuItem(value: t.id, child: Text(t.name)),
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
          errorText: null,
        ),
        child: Text(text),
      ),
    );
  }
}

class _DocumentsSection extends StatelessWidget {
  const _DocumentsSection({
    required this.title,
    required this.passportLabel,
    required this.visaLabel,
    required this.nusukLabel,
    required this.passport,
    required this.visa,
    required this.nusuk,
    required this.onPassport,
    required this.onVisa,
    required this.onNusuk,
  });

  final String title;
  final String passportLabel;
  final String visaLabel;
  final String nusukLabel;
  final File? passport;
  final File? visa;
  final File? nusuk;
  final ValueChanged<File> onPassport;
  final ValueChanged<File> onVisa;
  final ValueChanged<File> onNusuk;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ImagePickerField(
          label: passportLabel,
          file: passport,
          onPicked: onPassport,
        ),
        const SizedBox(height: 10),
        ImagePickerField(label: visaLabel, file: visa, onPicked: onVisa),
        const SizedBox(height: 10),
        ImagePickerField(label: nusukLabel, file: nusuk, onPicked: onNusuk),
      ],
    );
  }
}
