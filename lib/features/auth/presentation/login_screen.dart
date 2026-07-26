import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animations/animations.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/brand_header.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/password_field.dart';
import '../application/auth_cubit.dart';
import 'widgets/google_button.dart';
import 'widgets/settings_menu_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      context.read<AuthCubit>().signIn(_email.text, _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(actions: const [SettingsMenuButton()]),
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthUiState>(
          listener: (context, state) {
            if (state.status == AuthStatus.error && state.error != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.error!)));
            }
          },
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  // Keeps the submit button reachable above the keyboard.
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 36,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: AutofillGroup(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: staggered([
                                const SizedBox(height: AppSpacing.lg),
                                BrandHeader(
                                  title: l.authLoginTitle,
                                  subtitle: l.authLoginSubtitle,
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                // The credentials sit on their own pane so the
                                // form reads as one contained task.
                                GlassCard(
                                  radius: AppRadius.xl,
                                  padding: const EdgeInsets.all(AppSpacing.xl),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      TextFormField(
                                        controller: _email,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [
                                          AutofillHints.email,
                                        ],
                                        decoration: InputDecoration(
                                          labelText: l.authEmail,
                                          prefixIcon: const Icon(
                                            AppIcons.email,
                                          ),
                                        ),
                                        validator: (v) =>
                                            Validators.isEmail(v ?? '')
                                            ? null
                                            : l.authInvalidEmail,
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      PasswordField(
                                        controller: _password,
                                        label: l.authPassword,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [
                                          AutofillHints.password,
                                        ],
                                        onFieldSubmitted: (_) =>
                                            _submit(context),
                                        validator: (v) => (v ?? '').isEmpty
                                            ? l.commonRequired
                                            : null,
                                      ),
                                      const SizedBox(height: AppSpacing.xl),
                                      FilledButton(
                                        onPressed: state.isSubmitting
                                            ? null
                                            : () => _submit(context),
                                        child: state.isSubmitting
                                            ? const _ButtonSpinner()
                                            : Text(l.authSignIn),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                _OrDivider(label: l.authOrContinueWith),
                                const SizedBox(height: AppSpacing.xl),
                                GoogleButton(
                                  label: l.authGoogle,
                                  onPressed: state.isSubmitting
                                      ? null
                                      : () => context
                                            .read<AuthCubit>()
                                            .signInWithGoogle(),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      l.authNoAccount,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          context.push(Routes.register),
                                      child: Text(l.authSignUp),
                                    ),
                                  ],
                                ),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 22,
    width: 22,
    child: CircularProgressIndicator(
      strokeWidth: 2.4,
      strokeCap: StrokeCap.round,
      color: Theme.of(context).colorScheme.onPrimary,
    ),
  );
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
            style: TextStyle(color: color, fontSize: 12, letterSpacing: 0.4),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
