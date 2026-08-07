import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// When a home card carries a raised button, and when it must not.
///
/// The rule, and it is worth writing down because it is what stops the pattern
/// spreading until it means nothing:
///
///   **the button appears exactly where the card lists something you can add
///   to, and does nothing else.**
///
/// Check-in, tasks and complaints qualify — each card is a list the reader
/// writes into. Operational files do not: they are created by administration,
/// not from here. Decisions do not: they are published TO the reader. And
/// evaluations do not, which is the sharpest case — they arrive by NAME, so
/// there is no "new evaluation" for anybody to press. A button there would be
/// offering an act that does not exist.
///
/// Three of six is not the ceiling and not the target; it is however many cards
/// happen to satisfy the rule. What this test guards is that the ones which do
/// not satisfy it stay bare.
void main() {
  late String home;

  setUpAll(() {
    final file = File('lib/features/home/presentation/home_screen.dart');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'run from the project root — ${file.absolute.path}',
    );
    home = file.readAsStringSync().replaceAll('\r\n', '\n');
  });

  /// The DashboardCard block that routes to [route].
  String cardFor(String route) {
    final at = home.indexOf('onTap: () => context.push($route)');
    expect(at, isNot(-1), reason: 'no card routes to $route any more');
    final start = home.lastIndexOf('DashboardCard(', at);
    final end = home.indexOf('\n      ),', at);
    return home.substring(start, end);
  }

  group('cards you can add to carry the button', () {
    test('my attendance — the act that writes the record', () {
      expect(cardFor('Routes.myCheckIns'), contains('action:'));
    });

    test('my tasks — a list the reader writes into', () {
      expect(cardFor('Routes.tasks'), contains('action:'));
      expect(cardFor('Routes.tasks'), contains('compose=1'));
    });

    test('my complaints — anyone approved may file, by design (0079 rule 1)', () {
      expect(cardFor('Routes.complaints'), contains('action:'));
      expect(cardFor('Routes.complaints'), contains('compose=1'));
    });
  });

  group('cards with nothing to add stay bare', () {
    test('operational files — assignment puts them there, not the reader', () {
      expect(cardFor('Routes.modules'), isNot(contains('action:')));
    });

    test('decisions — published TO the reader', () {
      expect(cardFor('Routes.reports'), isNot(contains('action:')));
    });

    test('evaluations — they arrive by name; there is no new one to press', () {
      expect(cardFor('Routes.evaluations'), isNot(contains('action:')));
    });
  });

  test('a compose request is a query parameter the router actually reads', () {
    // The cards ask for `?compose=1`. If the router stops reading it the
    // buttons keep working — they still navigate — and silently stop opening
    // anything, which is the shape of bug that survives a demo.
    final router = File(
      'lib/core/router/app_router.dart',
    ).readAsStringSync();

    final listens = RegExp(
      RegExp.escape("compose: s.uri.queryParameters['compose'] == '1'"),
    ).allMatches(router).length;

    expect(
      listens,
      greaterThanOrEqualTo(2),
      reason: 'both cards that ask to compose need a route that listens',
    );
  });
}
