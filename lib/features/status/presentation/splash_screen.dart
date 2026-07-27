import 'package:flutter/material.dart';

import '../../../core/widgets/app_logo.dart';
import '../../../core/theme/glass_tokens.dart';

/// Shown while the session is being resolved at startup: the brand mark rises
/// into place over the aurora, with an indeterminate bar rather than a spinner
/// so the wait reads as progress.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => Opacity(
            opacity: t.clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 18),
              child: Transform.scale(scale: 0.88 + 0.12 * t, child: child),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.35),
                      blurRadius: 44,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: const AppLogo(size: 140),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: scheme.primary.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
