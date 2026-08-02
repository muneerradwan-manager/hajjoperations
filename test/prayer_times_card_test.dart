import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajjoperations/core/theme/app_theme.dart';
import 'package:hajjoperations/features/prayer_times/application/prayer_times_cubit.dart';
import 'package:hajjoperations/features/prayer_times/data/prayer_times_repository.dart';
import 'package:hajjoperations/features/prayer_times/domain/prayer_day.dart';
import 'package:hajjoperations/features/prayer_times/domain/prayer_fix.dart';
import 'package:hajjoperations/features/prayer_times/presentation/widgets/prayer_times_card.dart';
import 'package:hajjoperations/l10n/app_localizations.dart';

/// What the card SAYS, in the three states a reader can actually catch it in.
///
/// The arithmetic behind them is walked minute by minute in
/// `prayer_times_test.dart`; this file is about whether the right sentence
/// reaches the screen, and whether six names and six clocks fit across a phone
/// and across a 320-wide side panel without a letter going missing.
///
/// The repository is stubbed rather than mocked at the channel: under
/// `flutter test` the location plugin never answers at all — the future simply
/// does not complete — so a card built on the real one is frozen on "جارٍ
/// تحديد موقعك…" forever and there is nothing to assert about it.
void main() {
  /// Answers where the platform would, and hands back whichever day the test
  /// needs to put the clock inside a particular window.
  ///
  /// [dayBuilder] is given the real `now`, so a day it builds is arranged
  /// around whatever hour the suite happens to run at. Nothing here depends on
  /// the wall clock; everything is placed relative to it.
  PrayerTimesCubit stubbed({
    PrayerFix? fix,
    LocationOutcome outcome = LocationOutcome.needsPermission,
    PrayerDay Function(DateTime now)? dayBuilder,
  }) {
    return PrayerTimesCubit(
      _StubRepository(fix: fix, outcome: outcome, dayBuilder: dayBuilder),
    );
  }

  Widget harness(
    PrayerTimesCubit cubit, {
    required double width,
    required Locale locale,
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.dark(),
      home: Scaffold(
        // Unbounded height, which is what the card gets in the app: a ListView
        // on a phone, a scrolling panel on a monitor. A bounded box would let a
        // stretching Column hide behind the test's own 600 pixels.
        body: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: width,
              child: BlocProvider.value(
                value: cubit,
                child: const PrayerTimesCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the card and lets the boot chain settle.
  ///
  /// Not `pumpAndSettle`: the card holds a one-second ticker that schedules a
  /// frame forever, and settling would wait for an end that never comes.
  Future<void> show(
    WidgetTester tester,
    PrayerTimesCubit cubit, {
    required double width,
    Locale locale = const Locale('ar'),
  }) async {
    await tester.pumpWidget(harness(cubit, width: width, locale: locale));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
  }

  /// Takes the tree down before the test ends, so the ticker and the cubit's
  /// boundary timer are cancelled rather than reported as still pending.
  Future<void> dismiss(WidgetTester tester, PrayerTimesCubit cubit) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
  }

  const arabicNames = ['الفجر', 'الشروق', 'الظهر', 'العصر', 'المغرب', 'العشاء'];

  group('the strip', () {
    testWidgets('a phone gets all six marks, and none of them elide', (
      tester,
    ) async {
      final cubit = stubbed(fix: _mina);
      await show(tester, cubit, width: 360);

      expect(tester.takeException(), isNull);
      for (final name in arabicNames) {
        // Once each: the strip. The headline names the coming mark too, but as
        // "العصر · 3:42 م" — one Text, and never an exact match for this.
        expect(find.text(name), findsOneWidget, reason: name);
      }

      await dismiss(tester, cubit);
    });

    testWidgets('a 320 panel folds the six into two rows of three', (
      tester,
    ) async {
      final narrow = stubbed(fix: _mina);
      await show(tester, narrow, width: 320);
      expect(tester.takeException(), isNull);
      for (final name in arabicNames) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      final folded = tester.getSize(find.byType(PrayerTimesCard)).height;
      await dismiss(tester, narrow);

      final wide = stubbed(fix: _mina);
      await show(tester, wide, width: 440);
      final flat = tester.getSize(find.byType(PrayerTimesCard)).height;
      await dismiss(tester, wide);

      // The fold is the only observable difference, and it is the point of it:
      // a second row rather than المغرب losing its last two letters.
      expect(folded, greaterThan(flat));
    });

    testWidgets('English fits the same columns', (tester) async {
      final cubit = stubbed(fix: _mina);
      await show(tester, cubit, width: 360, locale: const Locale('en'));

      expect(tester.takeException(), isNull);
      for (final name in [
        'Fajr',
        'Sunrise',
        'Dhuhr',
        'Asr',
        'Maghrib',
        'Isha',
      ]) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      expect(find.text('Prayer times'), findsOneWidget);

      await dismiss(tester, cubit);
    });
  });

  group('what it says about where it is', () {
    testWidgets('with no position of its own it says so rather than pretending', (
      tester,
    ) async {
      // The times on screen are مكة's. Saying "موقعك" over them would be a lie,
      // and saying nothing would leave a reader in Damascus with a Fajr an hour
      // out and no way to tell.
      final cubit = stubbed();
      await show(tester, cubit, width: 360);

      expect(find.text('موقع تقريبي'), findsOneWidget);
      expect(cubit.state.approximate, isTrue);
      // And there is something to be done about it, so the chip takes a tap.
      expect(cubit.state.canAskForLocation, isTrue);

      await dismiss(tester, cubit);
    });

    testWidgets('a fix inside the مشاعر is named, not spelled in degrees', (
      tester,
    ) async {
      final cubit = stubbed(fix: _mina, outcome: LocationOutcome.located);
      await show(tester, cubit, width: 360);

      expect(find.text('منى'), findsOneWidget);
      expect(find.text('موقع تقريبي'), findsNothing);

      await dismiss(tester, cubit);
    });

    testWidgets('a fix outside every named place falls back to "موقعك"', (
      tester,
    ) async {
      // Damascus, where the mission comes from.
      final cubit = stubbed(
        fix: PrayerFix(
          latitude: 33.5138,
          longitude: 36.2765,
          capturedAt: DateTime.now(),
        ),
        outcome: LocationOutcome.located,
      );
      await show(tester, cubit, width: 360);

      expect(find.text('موقعك'), findsOneWidget);

      await dismiss(tester, cubit);
    });
  });

  group('the window it is standing in', () {
    testWidgets('between الشروق and الظهر it says no prayer is due', (
      tester,
    ) async {
      // The whole reason this card exists in the shape it does. Six hours of
      // every day have no prayer in them, and a card that fills its "الصلاة
      // الحالية" slot with الشروق tells a reader there is one.
      final cubit = stubbed(fix: _mina, dayBuilder: _dayInSunriseGap);
      await show(tester, cubit, width: 360);

      expect(find.text('وقت الشروق — لا صلاة حتى الظهر'), findsOneWidget);
      // And what it counts down to is الظهر, which IS a prayer.
      expect(find.textContaining('الظهر ·'), findsOneWidget);
      expect(cubit.state.window!.inSunriseGap, isTrue);

      await dismiss(tester, cubit);
    });

    testWidgets('inside الفجر it counts to the end of the prayer, not to one', (
      tester,
    ) async {
      final cubit = stubbed(fix: _mina, dayBuilder: _dayInFajr);
      await show(tester, cubit, width: 360);

      // Not "الصلاة القادمة: الشروق" — الشروق is not a prayer and is never
      // announced as the next one.
      expect(find.text('ينتهي وقت الفجر'), findsOneWidget);
      expect(find.text('الصلاة القادمة'), findsNothing);
      expect(find.textContaining('الشروق ·'), findsOneWidget);
      // No gap note here: الفجر is open, and something IS due.
      expect(find.text('وقت الشروق — لا صلاة حتى الظهر'), findsNothing);

      await dismiss(tester, cubit);
    });

    testWidgets('in an ordinary window it announces the next prayer', (
      tester,
    ) async {
      final cubit = stubbed(fix: _mina, dayBuilder: _dayInAsr);
      await show(tester, cubit, width: 360);

      expect(find.text('الصلاة القادمة'), findsOneWidget);
      expect(find.textContaining('المغرب ·'), findsOneWidget);
      expect(find.text('ينتهي وقت الفجر'), findsNothing);

      await dismiss(tester, cubit);
    });
  });
}

final _mina = PrayerFix(
  latitude: 21.4133,
  longitude: 39.8933,
  capturedAt: DateTime.now(),
);

/// Days built around the real `now`, so that whichever hour the suite runs at,
/// the clock lands in the window under test.
///
/// The marks outside that window are placed only far enough away to keep the
/// order; nothing reads them.
PrayerDay _dayAround(
  DateTime now, {
  required Duration fajr,
  required Duration sunrise,
  required Duration dhuhr,
  required Duration asr,
  required Duration maghrib,
  required Duration isha,
}) {
  return PrayerDay(
    day: DateTime(now.year, now.month, now.day),
    fajr: now.add(fajr),
    sunrise: now.add(sunrise),
    dhuhr: now.add(dhuhr),
    asr: now.add(asr),
    maghrib: now.add(maghrib),
    isha: now.add(isha),
    previousIsha: now.add(fajr - const Duration(hours: 8)),
    nextFajr: now.add(isha + const Duration(hours: 8)),
  );
}

PrayerDay _dayInSunriseGap(DateTime now) => _dayAround(
  now,
  fajr: const Duration(hours: -4),
  sunrise: const Duration(hours: -3),
  dhuhr: const Duration(hours: 1),
  asr: const Duration(hours: 4),
  maghrib: const Duration(hours: 7),
  isha: const Duration(hours: 8),
);

PrayerDay _dayInFajr(DateTime now) => _dayAround(
  now,
  fajr: const Duration(minutes: -30),
  sunrise: const Duration(minutes: 55),
  dhuhr: const Duration(hours: 7),
  asr: const Duration(hours: 10),
  maghrib: const Duration(hours: 13),
  isha: const Duration(hours: 14),
);

PrayerDay _dayInAsr(DateTime now) => _dayAround(
  now,
  fajr: const Duration(hours: -11),
  sunrise: const Duration(hours: -10),
  dhuhr: const Duration(hours: -3),
  asr: const Duration(minutes: -40),
  maghrib: const Duration(hours: 2),
  isha: const Duration(hours: 3),
);

/// Everything the platform would answer, answered.
///
/// Only the two calls that cross a boundary are overridden. [dayFor] is left
/// alone unless a test needs the clock in a particular window — the astronomy
/// is the same code the app runs.
class _StubRepository extends PrayerTimesRepository {
  _StubRepository({
    required this.fix,
    required this.outcome,
    required this.dayBuilder,
  });

  final PrayerFix? fix;
  final LocationOutcome outcome;
  final PrayerDay Function(DateTime now)? dayBuilder;

  @override
  Future<PrayerFix?> lastKnownFix() async => fix;

  @override
  Future<LocationResult> locate({required bool prompt}) async =>
      LocationResult(outcome, outcome == LocationOutcome.located ? fix : null);

  @override
  PrayerDay dayFor({
    required double latitude,
    required double longitude,
    DateTime? at,
  }) {
    final builder = dayBuilder;
    if (builder == null) {
      return super.dayFor(latitude: latitude, longitude: longitude, at: at);
    }
    return builder(at ?? DateTime.now());
  }
}
