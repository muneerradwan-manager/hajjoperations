import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/glass_tokens.dart';
import '../../../../core/widgets/glass.dart';
import '../../application/auth_cubit.dart';

/// How long before another code may be asked for.
///
/// Sixty because that is Supabase's own minimum between two letters to one
/// address. Set shorter, the button goes live while the server would still
/// refuse — and the reader presses an enabled button and is told off for it,
/// which reads as the app being broken rather than as a rule.
///
/// It also stops the button being pressed four times in six seconds by
/// somebody who has decided the first letter is not coming: that posts four
/// codes of which only the last one works, and leaves them typing an earlier
/// one out of whichever letter they happened to open.
const _resendCooldown = Duration(seconds: 60);

/// The second half of creating an account: the six digits that came by post.
///
/// A CODE rather than a link, which is the whole reason this screen exists. A
/// confirmation link mailed to a phone opens in whichever browser the phone
/// prefers — not in the app — so the account is confirmed somewhere the person
/// cannot see, while the screen they are actually looking at has not moved.
/// Six digits carried back by hand close that gap with nothing to configure.
///
/// It replaces the form in place rather than pushing a screen. The address is
/// on it, the way back is on it, and the reader never leaves the page they
/// started on — a sign-up is one errand and should look like one.
class VerifyCodeCard extends StatefulWidget {
  const VerifyCodeCard({super.key, required this.email});

  /// The address the code went to. Shown, because the commonest reason a code
  /// never arrives is that it went somewhere with a letter missing.
  final String email;

  @override
  State<VerifyCodeCard> createState() => _VerifyCodeCardState();
}

class _VerifyCodeCardState extends State<VerifyCodeCard> {
  final _code = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Timer? _ticker;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    // The first code went out with the sign-up, so the clock starts at once —
    // otherwise "إعادة الإرسال" is live at the moment the first letter is still
    // in the air, which is exactly when it is pressed by mistake.
    _startCooldown();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _ticker?.cancel();
    setState(() => _secondsLeft = _resendCooldown.inSeconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().verifyCode(_code.text);
  }

  void _resend() {
    _startCooldown();
    context.read<AuthCubit>().resendCode();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final state = context.watch<AuthCubit>().state;
    final waiting = _secondsLeft > 0;

    return GlassCard(
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(AppIcons.email, size: 18, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l.authVerifyTitle,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l.authVerifySubtitle(widget.email),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _code,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              // The platform's own one-time-code autofill. On both phones this
              // is what puts the digits in from the notification without the
              // reader leaving the app to go and read the letter.
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              // Spaced and centred, because six digits copied off a screen are
              // read in pairs and a proportional font runs them together.
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(
                letterSpacing: 10,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                labelText: l.authVerifyCode,
                hintText: l.authVerifyCodeHint,
                counterText: '',
                hintStyle: text.bodyMedium?.copyWith(
                  letterSpacing: 0,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              onFieldSubmitted: (_) => _submit(),
              validator: (v) => (v ?? '').trim().length == 6
                  ? null
                  : l.authVerifyCodeTooShort,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: state.isSubmitting ? null : _submit,
              child: state.isSubmitting
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        strokeCap: StrokeCap.round,
                        color: scheme.onPrimary,
                      ),
                    )
                  : Text(l.authVerifyAction),
            ),
            const SizedBox(height: AppSpacing.sm),
            // The junk folder, said before it is asked about. It is where these
            // letters land often enough that leaving the reader to think of it
            // themselves costs more than one quiet line does.
            Text(
              l.authVerifyJunkHint,
              textAlign: TextAlign.center,
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: state.isSubmitting
                      ? null
                      : () => context.read<AuthCubit>().cancelVerification(),
                  child: Text(l.authVerifyChangeEmail),
                ),
                TextButton(
                  onPressed: waiting || state.isSubmitting ? null : _resend,
                  child: Text(
                    waiting
                        ? l.authVerifyResendIn(_secondsLeft)
                        : l.authVerifyResend,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
