import 'package:flutter_test/flutter_test.dart';
import 'package:hajjoperations/core/l10n/localized_name.dart';
import 'package:hajjoperations/features/travel/domain/journey.dart';
import 'package:hajjoperations/features/travel/domain/journey_leg.dart';
import 'package:hajjoperations/features/travel/domain/trip.dart';

/// [Journey] is the one place in this feature where "where is he, and when does
/// he come back" is answered, and it is answered by ARITHMETIC over a list of
/// legs rather than by a column anybody maintains. That is the whole reason it
/// can be tested here, with no database and no widget — and the reason it must
/// be, because every screen in the feature reads its answers.
///
/// The cases below are the ones the design was argued over:
///
///   * a private car is a movement, not a missing booking
///   * a return that has not been booked yet is NORMAL, not an error
///   * two legs that do not join up produce a neutral gap, not a failure
///   * an empty journey is a sentence, not a broken screen

int _id = 0;

JourneyLeg _leg({
  required LegRole role,
  required String from,
  required String to,
  LegStatus status = LegStatus.planned,
  TravelMode mode = TravelMode.air,
  bool selfArranged = false,
  DateTime? plannedDeparture,
  DateTime? actualDeparture,
  DateTime? actualArrival,
  String? tripNumber,
}) => JourneyLeg(
  id: 'leg${_id++}',
  tripId: selfArranged ? null : 'trip$_id',
  role: role,
  mode: mode,
  status: status,
  selfArranged: selfArranged,
  fromPointId: from,
  fromPoint: LocalizedName(ar: from),
  toPointId: to,
  toPoint: LocalizedName(ar: to),
  tripNumber: tripNumber,
  plannedDepartureAt: plannedDeparture,
  actualDepartureAt: actualDeparture,
  actualArrivalAt: actualArrival,
);

Journey _journey(List<JourneyLeg> legs) =>
    Journey(participantId: 'p1', legs: legs);

void main() {
  final now = DateTime.now();
  final aWeekAgo = now.subtract(const Duration(days: 7));
  final inTwelveDays = now.add(const Duration(days: 12));

  group('an empty journey', () {
    test('is empty rather than broken', () {
      final j = _journey([]);
      expect(j.isEmpty, isTrue);
      expect(j.currentPlace, isNull);
      expect(j.line, isEmpty);
      expect(j.progress, 0);
      // The absence of a return is not an error even here.
      expect(j.returnLeg, isNull);
      expect(j.daysToReturn, isNull);
    });
  });

  group('where he is', () {
    test('is the destination of the last COMPLETED leg', () {
      final j = _journey([
        _leg(
          role: LegRole.inbound,
          from: 'دمشق',
          to: 'جدة',
          status: LegStatus.completed,
          actualDeparture: aWeekAgo,
          actualArrival: aWeekAgo.add(const Duration(hours: 3)),
        ),
        _leg(
          role: LegRole.internal,
          from: 'مكة',
          to: 'المدينة',
          plannedDeparture: now.add(const Duration(days: 2)),
        ),
      ]);
      expect(j.currentPlace?.ar, 'جدة');
      expect(j.hasDeparted, isTrue);
      expect(j.isHome, isFalse);
    });

    test('is his starting point before he has set off', () {
      final j = _journey([
        _leg(
          role: LegRole.inbound,
          from: 'دمشق',
          to: 'جدة',
          plannedDeparture: now.add(const Duration(days: 3)),
        ),
      ]);
      expect(j.currentPlace?.ar, 'دمشق');
      expect(j.hasDeparted, isFalse);
    });

    test('a completed return means he is home', () {
      final j = _journey([
        _leg(
          role: LegRole.inbound,
          from: 'دمشق',
          to: 'جدة',
          status: LegStatus.completed,
          actualArrival: aWeekAgo,
        ),
        _leg(
          role: LegRole.outbound,
          from: 'جدة',
          to: 'دمشق',
          status: LegStatus.completed,
          actualArrival: now,
        ),
      ]);
      expect(j.isHome, isTrue);
      expect(j.progress, 1.0);
    });
  });

  group('the way home', () {
    test('an unbooked return is null and NOT a failure', () {
      final j = _journey([
        _leg(
          role: LegRole.inbound,
          from: 'دمشق',
          to: 'جدة',
          status: LegStatus.completed,
          actualArrival: aWeekAgo,
        ),
      ]);
      expect(j.returnLeg, isNull);
      expect(j.daysToReturn, isNull);
      // Progress over what is KNOWN, and flagged as provisional so no screen
      // presents "100%" to a man with no flight home.
      expect(j.isProgressProvisional, isTrue);
      expect(j.legs.every((l) => !l.status.isFailure), isTrue);
    });

    test('counts whole calendar days, not 24-hour blocks', () {
      final j = _journey([
        _leg(
          role: LegRole.outbound,
          from: 'جدة',
          to: 'دمشق',
          plannedDeparture: inTwelveDays,
        ),
      ]);
      expect(j.daysToReturn, 12);
      expect(j.isProgressProvisional, isFalse);
    });

    test('a return late tonight still reads as tomorrow, not as today', () {
      final today = DateTime(now.year, now.month, now.day);
      final j = _journey([
        _leg(
          role: LegRole.outbound,
          from: 'جدة',
          to: 'دمشق',
          plannedDeparture: today.add(const Duration(days: 1, hours: 1)),
        ),
      ]);
      expect(j.daysToReturn, 1);
    });
  });

  group('a movement he arranged himself', () {
    test('is a leg like any other, and asks HIM to confirm it', () {
      final car = _leg(
        role: LegRole.internal,
        from: 'مكة',
        to: 'المدينة',
        mode: TravelMode.road,
        selfArranged: true,
        plannedDeparture: now.subtract(const Duration(days: 1)),
      );
      final j = _journey([car]);

      expect(car.selfArranged, isTrue);
      // The thing the whole requirement turned on: it is not a failure.
      expect(car.status.isFailure, isFalse);
      expect(car.carrierLabel, isNull, reason: 'a private car has no carrier row');
      expect(car.needsManualConfirmation, isTrue);
      expect(j.awaitingHisWord, hasLength(1));
      // Its hour has passed, so the board may ask — but only ask.
      expect(car.isOverdue, isTrue);
      expect(j.overdueLegs, hasLength(1));
    });

    test('once completed it moves him, exactly like a flight', () {
      final j = _journey([
        _leg(
          role: LegRole.internal,
          from: 'مكة',
          to: 'المدينة',
          mode: TravelMode.road,
          selfArranged: true,
          status: LegStatus.completed,
          actualArrival: now.subtract(const Duration(days: 1)),
        ),
      ]);
      expect(j.currentPlace?.ar, 'المدينة');
      expect(j.overdueLegs, isEmpty);
    });
  });

  group('superseded legs', () {
    test('are kept but do not stand', () {
      final j = _journey([
        _leg(
          role: LegRole.inbound,
          from: 'دمشق',
          to: 'جدة',
          status: LegStatus.rebooked,
          tripNumber: 'SR441',
        ),
        _leg(
          role: LegRole.inbound,
          from: 'دمشق',
          to: 'جدة',
          status: LegStatus.completed,
          tripNumber: 'SR447',
          actualArrival: aWeekAgo,
        ),
      ]);
      expect(j.allLegs, hasLength(2), reason: 'history is not deleted');
      expect(j.legs, hasLength(1), reason: 'only one still stands');
      expect(j.legs.single.tripNumber, 'SR447');
      expect(j.progress, 1.0);
    });
  });

  group('the drawn line', () {
    test('alternates places and movements, marking where he is', () {
      final j = _journey([
        _leg(
          role: LegRole.inbound,
          from: 'دمشق',
          to: 'جدة',
          status: LegStatus.completed,
          actualArrival: aWeekAgo,
        ),
        _leg(
          role: LegRole.outbound,
          from: 'جدة',
          to: 'دمشق',
          plannedDeparture: inTwelveDays,
        ),
      ]);

      final line = j.line;
      expect(line[0], isA<JourneyStop>());
      expect(line[1], isA<JourneyMove>());
      expect(line[2], isA<JourneyStop>());

      final stops = line.whereType<JourneyStop>().toList();
      expect(stops.map((s) => s.place?.ar), ['دمشق', 'جدة', 'دمشق']);
      expect(stops[0].state, JourneyStopState.done);
      expect(stops[1].state, JourneyStopState.current);
      expect(stops[2].state, JourneyStopState.upcoming);
    });

    test('emits a neutral gap where two legs do not join up', () {
      // He lands at جدة; his next recorded movement starts at مكة. The coach
      // between them is nobody's record — and must not read as a fault.
      final j = _journey([
        _leg(
          role: LegRole.inbound,
          from: 'دمشق',
          to: 'جدة',
          status: LegStatus.completed,
          actualArrival: aWeekAgo,
        ),
        _leg(
          role: LegRole.internal,
          from: 'مكة',
          to: 'المدينة',
          plannedDeparture: now.add(const Duration(days: 1)),
        ),
      ]);

      final gaps = j.line.whereType<JourneyGap>().toList();
      expect(gaps, hasLength(1));
      // It names both ends, so the reader is not left inferring which move the
      // line is asking about from the rows above and below it.
      expect(gaps.single.from?.ar, 'جدة');
      expect(gaps.single.to?.ar, 'مكة');
      expect(
        j.line.whereType<JourneyStop>().map((s) => s.place?.ar),
        ['دمشق', 'جدة', 'مكة', 'المدينة'],
      );
      // No leg is a failure. The gap is drawn, not blamed.
      expect(j.legs.any((l) => l.status.isFailure), isFalse);
    });

    test('emits no gap when the legs join up', () {
      final j = _journey([
        _leg(role: LegRole.inbound, from: 'دمشق', to: 'جدة'),
        _leg(role: LegRole.internal, from: 'جدة', to: 'المدينة'),
      ]);
      expect(j.line.whereType<JourneyGap>(), isEmpty);
    });
  });

  group('what is next', () {
    test('is the first leg he has not completed', () {
      final inbound = _leg(
        role: LegRole.inbound,
        from: 'دمشق',
        to: 'جدة',
        status: LegStatus.completed,
        actualArrival: aWeekAgo,
      );
      final internal = _leg(
        role: LegRole.internal,
        from: 'مكة',
        to: 'المدينة',
        plannedDeparture: now.add(const Duration(days: 1)),
      );
      final outbound = _leg(
        role: LegRole.outbound,
        from: 'المدينة',
        to: 'دمشق',
        plannedDeparture: inTwelveDays,
      );
      final j = _journey([inbound, internal, outbound]);

      expect(j.currentLeg?.id, internal.id);
      expect(j.nextLeg?.id, outbound.id);
      expect(j.progress, closeTo(1 / 3, 0.001));
    });
  });

  group('planned against actual', () {
    test('a materially late departure is flagged; a punctual one is not', () {
      final planned = now.subtract(const Duration(days: 1));
      final late = _leg(
        role: LegRole.inbound,
        from: 'دمشق',
        to: 'جدة',
        status: LegStatus.completed,
        plannedDeparture: planned,
        actualDeparture: planned.add(const Duration(hours: 6)),
      );
      final punctual = _leg(
        role: LegRole.outbound,
        from: 'جدة',
        to: 'دمشق',
        status: LegStatus.completed,
        plannedDeparture: planned,
        actualDeparture: planned.add(const Duration(minutes: 4)),
      );
      expect(late.departedLate, isTrue);
      expect(punctual.departedLate, isFalse);
    });
  });
}
