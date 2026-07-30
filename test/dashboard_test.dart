import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajjoperations/core/theme/chart_palette.dart';
import 'package:hajjoperations/features/dashboard/domain/dashboard_stats.dart';
import 'package:hajjoperations/features/dashboard/presentation/widgets/charts.dart';

void main() {
  group('what the reader is allowed to ask', () {
    // The function drops a section the reader holds no permission for rather
    // than zeroing it, and the difference is the whole point: a zero is a claim
    // about the mission ("no employees"), and a missing section is "you may not
    // ask". Drawing a zero for the second would be the page telling a lie.
    test('a section that was withheld is absent, not zero', () {
      final stats = DashboardStats.fromMap({
        'season': {'id': 's1', 'hijri_year': 1447, 'is_current': true},
        'approvals': {
          'pending': 0,
          'approved': 0,
          'rejected': 0,
          'incomplete': 0,
        },
      });

      expect(stats.people, isNull);
      expect(stats.modules, isNull);
      expect(stats.reports, isNull);
      expect(stats.ratings, isNull);

      // Present and genuinely all-zero — an empty queue, which IS a fact.
      expect(stats.approvals, isNotNull);
      expect(stats.approvals!.pending, 0);
      expect(stats.isEmpty, isFalse);
    });

    test(
      'a reader with no permission at all gets a season and nothing else',
      () {
        final stats = DashboardStats.fromMap({
          'season': {'id': 's1', 'hijri_year': 1447, 'is_current': false},
        });

        expect(stats.season, isNotNull);
        expect(stats.isEmpty, isTrue);
      },
    );
  });

  group('reading what the database sent', () {
    test('a star distribution fills in the stars nobody gave', () {
      final r = RatingStats.fromMap({
        'count': 7,
        'rated_people': 3,
        'average': 4.33,
        // Nobody gave one or two stars, so those rows are simply absent.
        'distribution': [
          {'stars': 3, 'count': 1},
          {'stars': 4, 'count': 2},
          {'stars': 5, 'count': 4},
        ],
      });

      // Five entries, ones first — a missing star is a zero-height bar, not a
      // missing bar, or the axis stops being a scale.
      expect(r.distribution, [0, 0, 1, 2, 4]);
      expect(r.average, 4.33);
    });

    test('a file type carries its total and its active count', () {
      final m = ModuleStats.fromMap({
        'total': 5,
        'active': 3,
        'draft': 2,
        'by_type': [
          {
            'label_ar': 'قطاعات وأبراج',
            'label_en': 'Sectors',
            'total': 3,
            'active': 2,
            'draft': 1,
          },
        ],
      });

      expect(m.byType.single.count, 3);
      expect(m.byType.single.secondary, 2);
      expect(m.byType.single.labelEn, 'Sectors');
    });

    test('a report day is read as the period it accounts for', () {
      final r = ReportStats.fromMap({
        'total': 4,
        'authors': 2,
        'series': [
          {'day': '2026-07-20', 'n': 3},
          {'day': '2026-07-21', 'n': 1},
        ],
      });

      expect(r.series.first.day, DateTime(2026, 7, 20));
      expect(r.series.last.count, 1);
    });
  });

  group('the palette', () {
    // These exact values were run through the six checks against both
    // backdrops — lightness band, chroma floor, CVD separation, the
    // normal-vision floor and contrast — and pass all five in each mode. The
    // app's own brand green and gold do NOT: measured, they sit ΔE 10 apart in
    // normal vision and 5.4 under protanopia, against thresholds of 15 and 8.
    //
    // So this is not decoration being pinned down. Changing a value here means
    // re-running scripts/validate_palette.js and changing this test with the
    // result — not adjusting it until it looks nicer.
    test('is the validated one, and has exactly three slots', () {
      expect(ChartPalette.series, hasLength(3));
      expect(ChartPalette.series.map((c) => c.onLight.toARGB32()).toList(), [
        0xFF00897B,
        0xFFA8801A,
        0xFF8C2A55,
      ]);
      expect(ChartPalette.series.map((c) => c.onDark.toARGB32()).toList(), [
        0xFF009485,
        0xFFB08B37,
        0xFFB85C86,
      ]);
    });
  });

  group('SplitBar', () {
    Widget wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SizedBox(width: 400, child: child)),
    );

    testWidgets('a category falling to zero does not repaint the survivors', (
      tester,
    ) async {
      // Colour follows the entity, never its rank. If "external" drops to zero
      // and "internal" takes its colour, every chart on the page has silently
      // changed what teal means.
      Color colourOfFirstLegendDot(WidgetTester t) {
        final dot = t
            .widgetList<Container>(find.byType(Container))
            .firstWhere((c) => (c.constraints?.maxWidth ?? 0) == 10);
        return (dot.decoration! as BoxDecoration).color!;
      }

      await tester.pumpWidget(
        wrap(
          const SplitBar(
            slices: [
              ChartSlice(label: 'Internal', value: 30),
              ChartSlice(label: 'External', value: 12),
            ],
          ),
        ),
      );
      final withBoth = colourOfFirstLegendDot(tester);

      await tester.pumpWidget(
        wrap(
          const SplitBar(
            slices: [
              ChartSlice(label: 'Internal', value: 30),
              ChartSlice(label: 'External', value: 0),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(colourOfFirstLegendDot(tester), withBoth);
      // And the empty one is gone from the legend rather than sitting there
      // claiming a colour for nothing.
      expect(find.text('External'), findsNothing);
    });

    testWidgets('every segment carries its name and its number', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const SplitBar(
            slices: [
              ChartSlice(label: 'Administrative', value: 8),
              ChartSlice(label: 'Religious', value: 5),
              ChartSlice(label: 'Medical', value: 2),
            ],
          ),
        ),
      );

      // Never colour alone: the chart survives a photocopier.
      for (final label in ['Administrative', 'Religious', 'Medical']) {
        expect(find.text(label), findsOneWidget);
      }
      for (final n in ['8', '5', '2']) {
        expect(find.text(n), findsOneWidget);
      }
    });
  });

  group('RankedBars', () {
    testWidgets('ranks by size and stops where a reader stops', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: RankedBars(
                maxRows: 3,
                slices: const [
                  ChartSlice(label: 'Third', value: 3),
                  ChartSlice(label: 'First', value: 30),
                  ChartSlice(label: 'Fourth', value: 1),
                  ChartSlice(label: 'Second', value: 12),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final first = tester.getTopLeft(find.text('First')).dy;
      final second = tester.getTopLeft(find.text('Second')).dy;
      final third = tester.getTopLeft(find.text('Third')).dy;
      expect(first, lessThan(second));
      expect(second, lessThan(third));
      expect(find.text('Fourth'), findsNothing);
    });
  });
}
