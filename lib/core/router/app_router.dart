import 'package:go_router/go_router.dart';

import '../../features/auth/application/session_cubit.dart';
import '../../features/approval/presentation/approval_queue_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/employees/presentation/employees_directory_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/modules/presentation/modules_screen.dart';
import '../../features/modules/presentation/reference_data_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/permissions/presentation/permissions_employees_screen.dart';
import '../../features/profile/presentation/my_profile_screen.dart';
import '../../features/profile/presentation/profile_completion_screen.dart';
import '../../features/seasons/presentation/seasons_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/status/presentation/pending_screen.dart';
import '../../features/status/presentation/rejected_screen.dart';
import '../../features/status/presentation/splash_screen.dart';
import '../../features/status/presentation/suspended_screen.dart';
import '../animations/animations.dart';
import 'go_router_refresh_stream.dart';

/// Route paths.
abstract class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const completeProfile = '/profile/complete';
  static const pending = '/pending';
  static const rejected = '/rejected';
  static const home = '/';
  static const approvals = '/approvals';
  static const permissions = '/permissions';
  static const seasons = '/seasons';
  static const suspended = '/suspended';
  static const employees = '/employees';
  static const myProfile = '/my-profile';
  static const notifications = '/notifications';
  static const modules = '/modules';
  static const referenceData = '/reference-data';
  static const settings = '/settings';
}

GoRouter buildRouter(SessionCubit session) {
  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: GoRouterRefreshStream(session.stream),
    redirect: (context, state) {
      final status = session.state.status;
      final loc = state.matchedLocation;

      // Still resolving the session — show the splash.
      if (status == SessionStatus.unknown) {
        return loc == Routes.splash ? null : Routes.splash;
      }

      final onAuthPage = loc == Routes.login || loc == Routes.register;

      switch (status) {
        case SessionStatus.unauthenticated:
          return onAuthPage ? null : Routes.login;
        case SessionStatus.incomplete:
          return loc == Routes.completeProfile ? null : Routes.completeProfile;
        case SessionStatus.pending:
          return loc == Routes.pending ? null : Routes.pending;
        case SessionStatus.rejected:
          // Allow editing the profile again from the rejected screen.
          if (loc == Routes.rejected || loc == Routes.completeProfile) {
            return null;
          }
          return Routes.rejected;
        case SessionStatus.suspended:
          return loc == Routes.suspended ? null : Routes.suspended;
        case SessionStatus.approved:
          if (onAuthPage ||
              loc == Routes.splash ||
              loc == Routes.pending ||
              loc == Routes.rejected ||
              loc == Routes.suspended ||
              loc == Routes.completeProfile) {
            return Routes.home;
          }
          return null;
        case SessionStatus.unknown:
          return null;
      }
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: Routes.login,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: Routes.register,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const RegisterScreen()),
      ),
      GoRoute(
        path: Routes.completeProfile,
        pageBuilder: (c, s) => fadeThroughPage(
          key: s.pageKey,
          child: const ProfileCompletionScreen(),
        ),
      ),
      GoRoute(
        path: Routes.pending,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const PendingScreen()),
      ),
      GoRoute(
        path: Routes.rejected,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const RejectedScreen()),
      ),
      GoRoute(
        path: Routes.suspended,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const SuspendedScreen()),
      ),
      GoRoute(
        path: Routes.home,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const HomeScreen()),
      ),
      GoRoute(
        path: Routes.notifications,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const NotificationsScreen()),
      ),
      GoRoute(
        path: Routes.settings,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const SettingsScreen()),
      ),
      GoRoute(
        path: Routes.approvals,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const ApprovalQueueScreen()),
      ),
      GoRoute(
        path: Routes.permissions,
        pageBuilder: (c, s) => fadeThroughPage(
          key: s.pageKey,
          child: const PermissionsEmployeesScreen(),
        ),
      ),
      GoRoute(
        path: Routes.seasons,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const SeasonsScreen()),
      ),
      GoRoute(
        path: Routes.employees,
        pageBuilder: (c, s) => fadeThroughPage(
          key: s.pageKey,
          child: const EmployeesDirectoryScreen(),
        ),
      ),
      GoRoute(
        path: Routes.modules,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const ModulesScreen()),
      ),
      GoRoute(
        path: Routes.referenceData,
        pageBuilder: (c, s) => fadeThroughPage(
          key: s.pageKey,
          child: const ReferenceDataScreen(),
        ),
      ),
      GoRoute(
        path: Routes.myProfile,
        pageBuilder: (c, s) =>
            fadeThroughPage(key: s.pageKey, child: const MyProfileScreen()),
      ),
    ],
  );
}
