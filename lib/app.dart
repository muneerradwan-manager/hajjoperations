import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bootstrap.dart';
import 'core/router/app_router.dart';
import 'core/settings/settings_cubit.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/aurora_background.dart';
import 'features/auth/application/auth_cubit.dart';
import 'features/auth/application/session_cubit.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/notifications/data/push_service.dart';
import 'features/profile/data/profile_repository.dart';
import 'l10n/app_localizations.dart';

class HajjOperationsApp extends StatelessWidget {
  const HajjOperationsApp({super.key, required this.deps});

  final AppDependencies deps;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => ProfileRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => SettingsCubit(deps.prefs)),
          BlocProvider(
            create: (context) => SessionCubit(
              context.read<AuthRepository>(),
              context.read<ProfileRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => AuthCubit(context.read<AuthRepository>()),
          ),
        ],
        child: const _AppView(),
      ),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final _router = buildRouter(context.read<SessionCubit>());

  @override
  void initState() {
    super.initState();
    PushService.instance.pendingTap.addListener(_deliverTap);
    _deliverTap();
  }

  @override
  void dispose() {
    PushService.instance.pendingTap.removeListener(_deliverTap);
    super.dispose();
  }

  /// Takes a notification tapped in the phone's tray to the inbox.
  ///
  /// Two things have to be true at once, and they do not arrive together. The
  /// tap can land before there is anybody signed in — a cold start from a tap
  /// begins at the splash with the session still resolving — and navigating
  /// then means navigating into a redirect that sends you back to the home
  /// page. So this runs on both: whenever a tap arrives, and whenever the
  /// session changes. Whichever is second is the one that does the work.
  ///
  /// The tap is deliberately NOT consumed here. The inbox takes it when it is
  /// on screen, and only then, because it is the inbox that knows how to open
  /// what the notification was about — and how to say so honestly when the file
  /// has since been deleted.
  void _deliverTap() {
    if (!mounted) return;
    if (PushService.instance.pendingTap.value == null) return;
    if (context.read<SessionCubit>().state.status != SessionStatus.approved) {
      return;
    }
    _router.go(Routes.notifications);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;

    return BlocListener<SessionCubit, SessionState>(
      listener: (_, _) => _deliverTap(),
      child: _app(settings),
    );
  }

  Widget _app(SettingsState settings) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router,
      // The animated backdrop lives above the navigator's own background and
      // below every route, so it survives page transitions without restarting.
      builder: (context, child) =>
          AuroraBackground(child: child ?? const SizedBox.shrink()),
    );
  }
}
