import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajjoperations/core/theme/glass_tokens.dart';
import 'package:hajjoperations/core/widgets/glass.dart';

/// Screens that extend behind the glass app bar rely on
/// [GlassThemeX.scrollPadding] to keep their first row clear of it. The value
/// comes from the MediaQuery that Scaffold rewrites for its *body* — read it
/// from a context above the Scaffold and the list silently slides underneath
/// the bar, which is exactly the regression these tests guard.
void main() {
  const statusBarHeight = 40.0;
  final expectedTopInset = statusBarHeight + kToolbarHeight;

  Widget harness({required Widget Function(BuildContext) bodyBuilder}) {
    return MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.only(top: statusBarHeight),
        ),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: const GlassAppBar(title: Text('t')),
          body: Builder(builder: bodyBuilder),
        ),
      ),
    );
  }

  testWidgets('scrollPadding clears the app bar inside the body', (
    tester,
  ) async {
    late EdgeInsets padding;
    await tester.pumpWidget(
      harness(
        bodyBuilder: (context) {
          padding = context.scrollPadding();
          return const SizedBox.shrink();
        },
      ),
    );

    expect(padding.top, expectedTopInset + AppSpacing.md);
    expect(padding.left, AppSpacing.lg);
    expect(padding.right, AppSpacing.lg);
  });

  testWidgets('a list using it starts below the app bar', (tester) async {
    await tester.pumpWidget(
      harness(
        bodyBuilder: (context) => ListView(
          padding: context.scrollPadding(),
          children: const [
            SizedBox(height: 40, child: Text('first', key: Key('first'))),
          ],
        ),
      ),
    );

    final top = tester.getTopLeft(find.byKey(const Key('first'))).dy;
    expect(
      top,
      greaterThanOrEqualTo(expectedTopInset),
      reason: 'first row must not be hidden behind the glass app bar',
    );
  });
}
