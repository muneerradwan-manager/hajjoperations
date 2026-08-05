import 'package:flutter_test/flutter_test.dart';
import 'package:hajjoperations/features/checkin/domain/check_in.dart';

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
