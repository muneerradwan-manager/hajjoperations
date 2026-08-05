import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajjoperations/core/l10n/error_text.dart';
import 'package:hajjoperations/features/checkin/data/check_in_repository.dart';
import 'package:hajjoperations/features/checkin/domain/check_in.dart';
import 'package:hajjoperations/l10n/app_localizations.dart';

PresenceLine line({double? distance, double? accuracy}) => PresenceLine(
  id: 'c1',
  profileId: 'p1',
  fullName: 'منير عبدالله رضوان',
  method: CheckInMethod.qr,
  createdAt: DateTime(2026, 8, 4, 20, 15),
  distanceM: distance,
  accuracyM: accuracy,
);

void main() {
  group('the code on the gate', () {
    test('it survives being written and read back', () {
      const code = CheckInCode(moduleId: 'm-1', nodeId: 'n-7');

      expect(CheckInCode.parse(code.encode()), code);
    });

    test('a code for the file itself carries no place', () {
      const code = CheckInCode(moduleId: 'm-1');

      final read = CheckInCode.parse(code.encode());

      expect(read?.moduleId, 'm-1');
      expect(
        read?.nodeId,
        isNull,
        reason: 'a flat file has people who arrive at it and no towers to '
            'arrive at',
      );
    });

    test('somebody else\'s QR is not a check-in', () {
      // A camera held up in a crowd reads all sorts of things. Each of these
      // must be refused as what it is, rather than sent to the server as a node
      // id that happens not to exist.
      for (final noise in const [
        'https://example.com',
        'WIFI:S:CampGuest;T:WPA;P:12345;;',
        '5901234123457',
        'n-7',
        '',
        'hajjops://something-else?m=m-1',
        'http://check-in?m=m-1',
      ]) {
        expect(
          CheckInCode.parse(noise),
          isNull,
          reason: '"$noise" should not read as a check-in',
        );
      }
    });

    test('a code with no file names nothing and is refused', () {
      expect(CheckInCode.parse('hajjops://check-in?n=n-7'), isNull);
      expect(CheckInCode.parse('hajjops://check-in'), isNull);
    });

    test('surrounding whitespace from a scanner is tolerated', () {
      expect(
        CheckInCode.parse('  hajjops://check-in?m=m-1&n=n-7\n'),
        const CheckInCode(moduleId: 'm-1', nodeId: 'n-7'),
      );
    });

    test('null is not a crash', () {
      expect(CheckInCode.parse(null), isNull);
    });
  });

  group('how far off it counts as', () {
    // The distance alone never decides anything. A phone that admits it may be
    // half a kilometre wrong has not caught anybody out.

    test('a close fix is not suspect', () {
      expect(line(distance: 30, accuracy: 8).isFarFromPlace, isFalse);
    });

    test('a distant fix from a confident phone IS suspect', () {
      expect(line(distance: 900, accuracy: 8).isFarFromPlace, isTrue);
    });

    test('a distant fix from a doubtful phone is NOT', () {
      // 400 m away, but the phone will only vouch for 500 m. That is not
      // evidence anybody was in the wrong place.
      expect(line(distance: 400, accuracy: 500).isFarFromPlace, isFalse);
      expect(line(distance: 400, accuracy: 500).worstCaseDistanceM, 0);
    });

    test('the doubt is subtracted, not ignored', () {
      expect(line(distance: 900, accuracy: 100).worstCaseDistanceM, 800);
    });

    test('no distance recorded is not zero distance', () {
      // A node with no coordinates, or a phone that gave none. Showing that as
      // "0 m from the place" would invent a confirmation nobody made.
      final unknown = line();

      expect(unknown.distanceM, isNull);
      expect(unknown.worstCaseDistanceM, isNull);
      expect(unknown.isFarFromPlace, isFalse);
    });

    test('a phone that reported no accuracy is taken at its word', () {
      expect(line(distance: 900).worstCaseDistanceM, 900);
      expect(line(distance: 900).isFarFromPlace, isTrue);
    });
  });

  group('an arrival that arrives nowhere', () {
    // The case a real log turned up: location services off, no code scanned,
    // and the sheet opened from the file page rather than from a tower. What
    // reached the server was a check-in naming neither a place nor a position,
    // and it was accepted — a row saying "somebody reports arriving at the
    // file", which cannot be drawn on the map and is uncounted on the board.
    //
    // It is worse than an empty record. The man is told he was counted, and
    // the operations room looking for him sees a camp with nobody in it. The
    // server refuses it now (0094); this is the half that turns the refusal
    // into something he can act on.
    late AppLocalizations ar;

    setUpAll(() async {
      WidgetsFlutterBinding.ensureInitialized();
      ar = await AppLocalizations.delegate.load(const Locale('ar'));
    });

    test('the refusal reaches him as a sentence, not as English', () {
      final said = friendlyErrorL(
        ar,
        'PostgrestException(message: check_in_needs_a_place, code: 23514)',
      );

      expect(said, ar.checkInNeedsAPlace);
      expect(
        said,
        isNot(contains('check_in_needs_a_place')),
        reason: 'a raw error code is not an answer to a man at a gate',
      );
    });

    test('and it says what to DO, not merely what failed', () {
      // Three ways out, because which one is open depends on where he is
      // standing: a printed code, a place he can name, or the location he can
      // switch on.
      expect(ar.checkInNeedsAPlace, contains('حدّد المكان'));
      expect(ar.checkInNeedsAPlace, contains('امسح'));
      expect(ar.checkInNeedsAPlace, contains('الموقع'));
    });

    test('a code from another file is named for what it is', () {
      expect(
        friendlyErrorL(ar, 'check_in_node_mismatch'),
        ar.checkInWrongFile,
      );
    });
  });

  group('what the sheet offers as "here"', () {
    Map<String, dynamic> node(
      String id, {
      required int depth,
      bool isPlace = false,
      String? label,
      String? referenceName,
    }) => {
      'id': id,
      'label': label,
      if (referenceName != null) 'reference_items': {'name_ar': referenceName},
      'module_type_levels': {'depth': depth, 'is_place': isPlace},
    };

    test('places, when the file has them', () {
      // مكة: قطاع(1) → برج(2) → تكتل(3). Only the tower is a place — the sector
      // is an arrangement on paper and the تكتل is a bloc of pilgrims inside a
      // building that already has its own code.
      final offered = checkInTargetsFrom([
        node('sector-1', depth: 1, label: 'القطاع الأول'),
        node('tower-1', depth: 2, isPlace: true, referenceName: 'فيلفيت ان'),
        node('bloc-1', depth: 3, referenceName: 'التكتل ٤'),
      ]);

      expect(offered.map((t) => t.name), ['فيلفيت ان']);
    });

    test('the innermost level, when it has none', () {
      // المدينة is organised by service company. No level there is a place —
      // rightly, since a code screwed to a company names nothing — and asking
      // `is_place` alone came back empty, which left the picker hidden and the
      // button dead-ending on the server's refusal with nothing to do about it.
      //
      // "With the fourth company" is less than a building and far more than
      // nothing, and it is enough for the room to find the man.
      final offered = checkInTargetsFrom([
        node('co-1', depth: 1, referenceName: 'شركة الخدمة الأولى'),
        node('co-2', depth: 1, referenceName: 'شركة الخدمة الرابعة'),
      ]);

      expect(offered.map((t) => t.name), [
        'شركة الخدمة الأولى',
        'شركة الخدمة الرابعة',
      ]);
    });

    test('the innermost, not the outermost', () {
      final offered = checkInTargetsFrom([
        node('sector-1', depth: 1, label: 'قطاع المشاعر'),
        node('team-1', depth: 2, label: 'الفريق الأول'),
      ]);

      expect(
        offered.map((t) => t.id),
        ['team-1'],
        reason: 'the narrower claim tells the operations room more',
      );
    });

    test('a file with no tree at all offers nothing, and says so by being empty',
        () {
      // Not a failure. Such a file has nothing to name, and the position is the
      // only thing that can carry the check-in — which is why the button stays
      // live for it rather than going dead.
      expect(checkInTargetsFrom(const []), isEmpty);
    });

    test('each is named the way its level names things', () {
      // منى names its camps by hand; عرفات and مكة draw them from a list.
      final offered = checkInTargetsFrom([
        node('camp-1', depth: 2, isPlace: true, label: 'المخيم ١١'),
        node('camp-2', depth: 2, isPlace: true, referenceName: 'مخيم ٢٤'),
      ]);

      expect(offered.map((t) => t.name), ['المخيم ١١', 'مخيم ٢٤']);
    });
  });

  group('the method', () {
    test('the database spellings round-trip', () {
      for (final method in CheckInMethod.values) {
        expect(CheckInMethod.fromDb(method.dbName), method);
      }
    });

    test('a spelling this build does not know is the weakest, not a crash', () {
      // An older app reading a method a newer migration added must not throw in
      // somebody's hand in Mina; reading it as the weakest claim is honest.
      expect(CheckInMethod.fromDb('face_scan'), CheckInMethod.manual);
      expect(CheckInMethod.fromDb(null), CheckInMethod.manual);
    });
  });
}
