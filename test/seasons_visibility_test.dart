import 'package:flutter_test/flutter_test.dart';
import 'package:hajjoperations/core/constants/permission_codes.dart';
import 'package:hajjoperations/features/auth/application/session_cubit.dart';
import 'package:hajjoperations/features/profile/domain/profile.dart';
import 'package:hajjoperations/features/profile/domain/profile_enums.dart';

/// Which season the Administration is working through, and who takes part in
/// it, is the Administration's to set. The dashboard showed that section to
/// every approved user — the one card in the list with no permission on it —
/// and the route had no opinion at all.
///
/// Both now ask [SessionState.canSeeSeasons], so this is the single place the
/// rule can be got wrong.
void main() {
  SessionState session({Set<String> permissions = const {}, bool admin = false}) {
    return SessionState(
      status: SessionStatus.approved,
      profile: Profile(
        id: 'p1',
        isAdmin: admin,
        accountStatus: AccountStatus.approved,
      ),
      permissions: permissions,
    );
  }

  test('an ordinary member does not see seasons', () {
    expect(session().canSeeSeasons, isFalse);
  });

  test('holding an unrelated permission is not enough', () {
    expect(
      session(permissions: {PermissionCodes.employeesView}).canSeeSeasons,
      isFalse,
    );
  });

  test('the section, or either action inside it, is enough', () {
    for (final code in [
      PermissionCodes.seasons,
      PermissionCodes.seasonsManage,
      PermissionCodes.seasonsParticipants,
    ]) {
      expect(
        session(permissions: {code}).canSeeSeasons,
        isTrue,
        reason: '$code should open the seasons section',
      );
    }
  });

  test('an admin sees everything, as everywhere else', () {
    expect(session(admin: true).canSeeSeasons, isTrue);
  });
}
