import '../../../core/l10n/localized_name.dart';
import 'journey_leg.dart';
import 'trip.dart';

/// One man's whole season of travel, **derived and never stored**.
///
/// 0064 wrote the argument down once and it is the same one here: a cluster's
/// capacity is a column and the sum of its groups is not, because the second is
/// a function of rows that already exist and a column would only be a second
/// place for it to be wrong. Where a man is now, what is next, how many days
/// until he flies home — every one of these is a function of his legs. Stored,
/// they would go stale the first time somebody edited a leg and nothing
/// recomputed; computed here, they cannot.
///
/// So this class holds no state of its own. It is built from the rows
/// `employee_journey` (0130) returns, and everything on it is a getter over
/// that list — which is also what makes it testable with no database at all.
class Journey {
  Journey({required this.participantId, required List<JourneyLeg> legs})
    : _all = List.unmodifiable(legs);

  final String participantId;
  final List<JourneyLeg> _all;

  /// Every leg ever recorded, including the ones that were superseded. The
  /// history is here for whoever wants it.
  List<JourneyLeg> get allLegs => _all;

  /// The legs that still stand, in the order they happen. This is what the
  /// timeline draws and what every derivation below reads.
  late final List<JourneyLeg> legs = _all
      .where((l) => l.status.isLive)
      .toList(growable: false);

  /// Nothing has been recorded at all. Not an error and not a broken screen —
  /// most of the roster looks like this until the flights are entered — so the
  /// UI says so in a sentence rather than drawing an empty skeleton.
  bool get isEmpty => legs.isEmpty;

  // ------------------------------------------------------------ where he is

  /// The legs he has actually completed, in order.
  late final List<JourneyLeg> _done = legs
      .where((l) => l.status.isDone)
      .toList(growable: false);

  /// **Where he is now**: the destination of the last movement he completed.
  ///
  /// Null before he has completed anything, which reads as "he has not set off
  /// yet" — and the origin of his first leg is the honest thing to show then.
  LocalizedName? get currentPlace =>
      _done.isEmpty ? legs.firstOrNull?.fromPoint : _done.last.toPoint;

  /// When he got there.
  DateTime? get currentPlaceSince =>
      _done.isEmpty ? null : _done.last.effectiveArrivalAt;

  /// Whether he has set off at all yet.
  bool get hasDeparted =>
      _done.isNotEmpty || legs.any((l) => l.actualDepartureAt != null);

  /// Whether the whole journey is behind him — he has completed a return.
  bool get isHome =>
      _done.any((l) => l.role == LegRole.outbound && l.status.isDone);

  // --------------------------------------------------------- what is next

  /// The movement he is in the middle of, or about to make: the first live leg
  /// he has not completed. Null once everything recorded is done.
  JourneyLeg? get currentLeg => legs.where((l) => !l.status.isDone).firstOrNull;

  /// The one after that.
  JourneyLeg? get nextLeg {
    final rest = legs.where((l) => !l.status.isDone).toList();
    return rest.length > 1 ? rest[1] : null;
  }

  // ---------------------------------------------------------- the way home

  /// His flight home, if one has been booked. **Null is the ordinary state**
  /// for most of the season — a charter return is very often set two days out —
  /// and the UI must say «لم تُحدَّد رحلة العودة بعد» in the plain text colour
  /// rather than as a warning (BR-12).
  JourneyLeg? get returnLeg =>
      legs.where((l) => l.role == LegRole.outbound).firstOrNull;

  DateTime? get returnAt => returnLeg?.effectiveDepartureAt;

  /// The leg that brought him in, once it has happened.
  JourneyLeg? get arrivalLeg =>
      legs.where((l) => l.role == LegRole.inbound).firstOrNull;

  DateTime? get arrivedAt {
    final leg = arrivalLeg;
    return leg != null && leg.status.isDone ? leg.effectiveArrivalAt : null;
  }

  /// Whole days until he flies home, counted the way a person counts them —
  /// by the calendar, not by elapsed hours. "tomorrow" is 1 even at 23:00.
  ///
  /// Negative once the date has passed with nothing confirmed, which the gaps
  /// board is the right place to notice; here it just stops being a countdown.
  int? get daysToReturn {
    final at = returnAt;
    return at == null ? null : _wholeDaysBetween(DateTime.now(), at);
  }

  /// Which day of his stay it is. 1 on the day he landed.
  int? get dayOfJourney {
    final from = arrivedAt;
    return from == null ? null : _wholeDaysBetween(from, DateTime.now()) + 1;
  }

  /// How far through he is, 0 to 1.
  ///
  /// Provisional while [returnLeg] is null: a journey with no way home booked
  /// has no known end, so the figure is over what is KNOWN and the UI should
  /// not present it as a percentage of the whole. [isProgressProvisional] says
  /// which case this is.
  double get progress {
    if (legs.isEmpty) return 0;
    return _done.length / legs.length;
  }

  bool get isProgressProvisional => returnLeg == null;

  // -------------------------------------------------------- what is missing

  /// Movements whose hour passed with nobody saying what happened. The private
  /// car lands here, and so does a flight nobody ticked off.
  List<JourneyLeg> get overdueLegs =>
      legs.where((l) => l.isOverdue).toList(growable: false);

  /// Legs only he can close out, because nothing else in the world can.
  List<JourneyLeg> get awaitingHisWord =>
      legs.where((l) => l.needsManualConfirmation).toList(growable: false);

  // ------------------------------------------------------------ the drawing

  /// The journey as an ordered line of places and movements — what the timeline
  /// renders, built once here so the widget stays a widget.
  ///
  /// Where two consecutive legs do not join up (he landed at جدة and his next
  /// recorded movement starts at مكة) a [JourneyGap] is emitted between them.
  /// That gap is drawn as a **neutral** connector, never as an error: the
  /// commonest cause by far is the airport coach, which nobody tracks and
  /// nobody needs to.
  late final List<JourneyEntry> line = _buildLine();

  List<JourneyEntry> _buildLine() {
    if (legs.isEmpty) return const [];

    final out = <JourneyEntry>[];
    final reached = _done.length;

    // Where he stands on the line, as an index into the stops: 0 is the origin
    // he has not left, 1 is the destination of his first completed leg.
    var stopIndex = 0;

    void addStop(LocalizedName? place, DateTime? at) {
      final state = stopIndex < reached
          ? JourneyStopState.done
          : stopIndex == reached
          ? JourneyStopState.current
          : JourneyStopState.upcoming;
      out.add(JourneyStop(place: place, state: state, at: at));
      stopIndex++;
    }

    addStop(legs.first.fromPoint, legs.first.actualDepartureAt);

    for (var i = 0; i < legs.length; i++) {
      final leg = legs[i];
      out.add(JourneyMove(leg));
      addStop(leg.toPoint, leg.effectiveArrivalAt);

      final next = i + 1 < legs.length ? legs[i + 1] : null;
      if (next != null &&
          leg.toPointId != null &&
          next.fromPointId != null &&
          leg.toPointId != next.fromPointId) {
        // Named at both ends. A bare «لم تُسجَّل وسيلة الانتقال» floating
        // between two rows does not say WHICH move it is asking about, and a
        // reader looking at جدة above it and مكة below it should not have to
        // work that out.
        out.add(JourneyGap(from: leg.toPoint, to: next.fromPoint));
        addStop(next.fromPoint, next.effectiveDepartureAt);
      }
    }

    return List.unmodifiable(out);
  }

  /// Whole calendar days from [from] to [to]. Date arithmetic and not
  /// `Duration.inDays`, because the second answers "how many 24-hour blocks"
  /// and nobody has ever meant that by "بعد يومين".
  static int _wholeDaysBetween(DateTime from, DateTime to) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  static Journey fromRows(
    String participantId,
    List<Map<String, dynamic>> rows,
  ) => Journey(
    participantId: participantId,
    legs: rows.map(JourneyLeg.fromRow).toList(growable: false),
  );
}

/// One thing on the drawn line: a place, a movement between places, or an
/// unrecorded step between them.
sealed class JourneyEntry {
  const JourneyEntry();
}

enum JourneyStopState {
  /// He has been and gone.
  done,

  /// Where he is now.
  current,

  /// Ahead of him.
  upcoming,
}

/// Somewhere he stands, or stood, or will.
class JourneyStop extends JourneyEntry {
  const JourneyStop({required this.place, required this.state, this.at});

  final LocalizedName? place;
  final JourneyStopState state;

  /// When he reached it — or, for the origin, when he left it.
  final DateTime? at;
}

/// A recorded movement between two places.
class JourneyMove extends JourneyEntry {
  const JourneyMove(this.leg);

  final JourneyLeg leg;
}

/// Two legs that do not join up.
///
/// **Not an error, and not a demand.** Almost always the coach from the
/// airport, which nobody tracks and nobody needs to — so it is drawn as a
/// dotted connector in the plain text colour, says which two places it falls
/// between, and calls itself optional. The button beside it is an invitation
/// for the cases where somebody DOES want the move on the record, not a blank
/// the timeline is refusing to accept.
class JourneyGap extends JourneyEntry {
  const JourneyGap({this.from, this.to});

  /// Where the movement before it ended, and where the next one starts.
  final LocalizedName? from;
  final LocalizedName? to;
}
