import 'package:flutter_test/flutter_test.dart';

import 'package:hajjoperations/features/checkin/application/my_check_ins_cubit.dart';
import 'package:hajjoperations/features/checkin/domain/check_in.dart';

/// A person's own record: what the two filters may and may not do to it.
void main() {
  PresenceLine at(String place, {String id = 'x'}) => PresenceLine(
    id: id,
    profileId: 'me',
    fullName: '',
    itemId: place,
    placeName: place,
    distanceM: 12,
    radiusM: 200,
    createdAt: DateTime(2026, 8, 7, 6),
  );

  test('the place filter offers only places this person has stood in', () {
    // Derived from the rows rather than from the master list: the filter should
    // offer the two hotels he has actually been to, not the sixty the mission
    // contracted.
    final state = MyCheckInsState(
      lines: [at('فندق', id: '1'), at('مخيم', id: '2'), at('فندق', id: '3')],
    );

    expect(state.places.map((p) => p.name), ['فندق', 'مخيم']);
  });

  test('narrowing to a place does not empty the list of places', () {
    // The reason the place filter runs in memory and the window at the server.
    // Asked of the server, choosing a place would return only those rows — and
    // the choices, being derived from the rows, would collapse to the one
    // already chosen, with no way back to the others.
    final state = MyCheckInsState(
      lines: [at('فندق', id: '1'), at('مخيم', id: '2')],
    ).copyWith(place: 'فندق');

    expect(state.shown, hasLength(1));
    expect(state.places, hasLength(2), reason: 'the way back must remain');
  });

  test('clearing the place is a state, not the absence of one', () {
    // `copyWith(place: null)` cannot mean "clear" — null is what an unset
    // named argument looks like, so it would mean "leave it alone". Every
    // filter that can be turned off needs this and it is easy to miss.
    final narrowed = const MyCheckInsState().copyWith(place: 'فندق');
    expect(narrowed.place, 'فندق');
    expect(narrowed.copyWith(clearPlace: true).place, isNull);
  });

  test('a window knows how far back it reaches, and "all" reaches forever', () {
    expect(CheckInWindow.day.since(), isNotNull);
    expect(CheckInWindow.week.since(), isNotNull);
    expect(
      CheckInWindow.all.since(),
      isNull,
      reason: 'no lower bound is what "all" means to the query',
    );
    expect(
      CheckInWindow.week.since()!.isBefore(CheckInWindow.day.since()!),
      isTrue,
    );
  });
}
