import 'package:flutter_test/flutter_test.dart';
import 'package:hajjoperations/core/constants/permission_codes.dart';
import 'package:hajjoperations/core/router/app_router.dart';
import 'package:hajjoperations/features/auth/application/session_cubit.dart';
import 'package:hajjoperations/features/profile/domain/profile.dart';
import 'package:hajjoperations/features/profile/domain/profile_enums.dart';

/// The sections of الإدارة are hidden from whoever does not hold them, and this
/// is what makes that a rule rather than a decoration: the route refuses too.
///
/// A hidden card and an open route look identical while you are testing as an
/// admin. The difference shows up as a link somebody was sent, or a location
/// restored from the last run, opening a page that person was never meant to
/// reach.
SessionState _holding(Set<String> permissions) =>
    SessionState(status: SessionStatus.approved, permissions: permissions);

void main() {
  group('sectionGuards', () {
    test('every administered section refuses somebody holding nothing', () {
      final open = SessionState(status: SessionStatus.approved);
      for (final entry in sectionGuards.entries) {
        expect(
          entry.value(open),
          isFalse,
          reason: '${entry.key} let in a user with no permissions',
        );
      }
    });

    test('each section is opened by its own permission and no other', () {
      // The pairs the home screen draws its cards by, written out again so
      // that changing one without the other fails here rather than in the
      // hands of somebody who should not have seen the page.
      const owners = {
        '/seasons': PermissionCodes.seasons,
        '/modules/manage': PermissionCodes.modulesManage,
        '/reports/manage': PermissionCodes.reportsManage,
        '/employees': PermissionCodes.employeesView,
        '/approvals': PermissionCodes.approvalsDecide,
        '/permissions': PermissionCodes.permissionsManage,
        '/reference-data': PermissionCodes.modulesTypes,
      };

      owners.forEach((route, code) {
        final guard = sectionGuards[route];
        expect(guard, isNotNull, reason: '$route has no guard at all');

        expect(
          guard!(_holding({code})),
          isTrue,
          reason: '$route refused the permission that owns it',
        );

        // Holding every OTHER permission is not enough. This is the half that
        // catches a guard copy-pasted from the line above it and left asking
        // for the wrong code — which passes a "the right person gets in" test
        // and lets the whole mission in.
        final others = owners.values.where((c) => c != code).toSet();
        expect(
          guard(_holding(others)),
          isFalse,
          reason: '$route opened for a permission that does not own it',
        );
      });
    });

    test('the seasons door opens for any of the three season permissions', () {
      // The permissions editor grants the section before it shows the actions,
      // but nothing in the database enforces that order, and a row written any
      // other way still means this person works with seasons.
      final guard = sectionGuards['/seasons']!;
      for (final code in [
        PermissionCodes.seasons,
        PermissionCodes.seasonsManage,
        PermissionCodes.seasonsParticipants,
      ]) {
        expect(guard(_holding({code})), isTrue, reason: '$code was refused');
      }
    });

    test('an admin is admitted everywhere without holding a single code', () {
      // Admin is a property of the profile, not a row in the permission table,
      // and every guard has to go through `can` for that to hold.
      final admin = SessionState(
        status: SessionStatus.approved,
        profile: const Profile(
          id: 'admin',
          accountStatus: AccountStatus.approved,
          isAdmin: true,
        ),
      );
      for (final entry in sectionGuards.entries) {
        expect(
          entry.value(admin),
          isTrue,
          reason: '${entry.key} refused an admin',
        );
      }
    });

    test('the guarded set is exactly what we mean to guard', () {
      // Written out so that dropping a guard is an edit somebody has to make
      // on purpose, in two places, rather than a line quietly deleted.
      expect(sectionGuards.keys.toSet(), {
        '/seasons',
        '/modules/manage',
        '/reports/manage',
        '/employees',
        '/approvals',
        '/permissions',
        '/reference-data',
      });
    });

    test('what everyone may reach is not guarded', () {
      // /modules is a person's own assigned work and /reports is what the
      // whole mission reads — guarding either would lock ordinary members out
      // of their own files. /dashboard answers for itself section by section
      // on the server, so anyone holding any part of it may open it.
      for (final open in ['/modules', '/reports', '/dashboard', '/']) {
        expect(
          sectionGuards.containsKey(open),
          isFalse,
          reason: '$open was closed, and it belongs to everyone',
        );
      }
    });

    test('a guard matches its own path only, never by prefix', () {
      // An employee's page is opened from inside an operational file, by people
      // who run files and may not keep the directory. It is pushed rather than
      // routed for that reason, and nothing here may reach past /employees to
      // close it.
      expect(sectionGuards.containsKey('/employees/some-id'), isFalse);
      expect(sectionGuards.containsKey('/modules/some-id'), isFalse);
    });
  });
}
