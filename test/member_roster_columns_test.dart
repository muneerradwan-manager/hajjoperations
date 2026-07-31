import 'package:flutter_test/flutter_test.dart';
import 'package:hajjoperations/core/theme/glass_tokens.dart';
import 'package:hajjoperations/core/widgets/responsive.dart';

/// Every roster of people on the module screen has to column alike.
///
/// There are three of them and they are laid out by different widgets: the
/// members held on a قطاع or مركز, the members held on a برج or مخيم inside
/// its card, and the members held on the FILE — فريق الكوسترات and every flat
/// roster file. When their thresholds drift apart the same screen shows two
/// columns in one section and one in the next, and files differ from each other
/// for no reason a reader can see: مخيمات عرفات is the only one of the three
/// tree files with no file-level team, so it alone looked right.
///
/// The numbers here are the ones module_detail_screen.dart uses. They are
/// restated rather than imported because they are private to that screen — and
/// because the point of the test is that changing one of them without the
/// others is the mistake.
const _member = 340.0; // _kMemberWidth — a file-level or node-level roster
const _nested = _member - AppSpacing.lg; // _kNestedMemberWidth — inside a card
const _cardPadding = AppSpacing.lg * 2; // the node card eats this before the grid
const _panelWidth = 380.0; // TwoPaneLayout on this screen

double _gutter(double w) => switch (WindowSize.fromWidth(w)) {
  WindowSize.compact => AppSpacing.lg,
  WindowSize.medium || WindowSize.expanded => AppSpacing.xl,
  WindowSize.large || WindowSize.extraLarge => AppSpacing.xxl,
};

/// The width the page hands to a section, panel taken out when there is one.
double _content(double window) {
  final g = _gutter(window);
  return WindowSize.fromWidth(window).hasSidePanel
      ? window - 3 * g - _panelWidth
      : window - 2 * g;
}

int _fileLevelRoster(double window) =>
    columnsFor(_content(window), minTileWidth: _member, maxColumns: 4);

int _nodeRoster(double window) =>
    columnsFor(_content(window), minTileWidth: _member, maxColumns: 4);

int _insideNodeCard(double window) => columnsFor(
  _content(window) - _cardPadding,
  minTileWidth: _nested,
  maxColumns: 4,
  spacing: AppSpacing.lg,
);

void main() {
  // The widths people actually work at: phones, tablets, the laptop lids this
  // mission carries, a half-screen window, and a desk monitor.
  const widths = <double>[
    360, 390, 412, 768, 800, 1024, 1200, 1280, 1366, 1440, 1536, 1600, 1920, 2560,
  ];

  group('member rosters column alike', () {
    for (final w in widths) {
      test('at ${w.toInt()} the three rosters agree', () {
        final file = _fileLevelRoster(w);
        final node = _nodeRoster(w);
        final nested = _insideNodeCard(w);
        expect(
          {file, node, nested},
          hasLength(1),
          reason:
              'at $w: file-level=$file, node-level=$node, inside-card=$nested — '
              'a file with a فريق would column differently from one without',
        );
      });
    }

    test('a desk monitor gets more than one column', () {
      expect(_fileLevelRoster(1440), greaterThan(1));
      expect(_insideNodeCard(1440), greaterThan(1));
    });

    test('1200 is not a hole: the panel arrives without costing a column', () {
      // The width the tree grid used to drop to one at, while the roster
      // beside it kept two.
      expect(_insideNodeCard(1200), _fileLevelRoster(1200));
      expect(_insideNodeCard(1200), 2);
    });

    test('a phone is one column everywhere, and honestly so', () {
      expect(_fileLevelRoster(390), 1);
      expect(_insideNodeCard(390), 1);
    });
  });
}
