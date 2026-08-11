import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/settings/settings_cubit.dart';
import '../../auth/application/session_cubit.dart';
import '../../prayer_times/application/prayer_times_cubit.dart';
import '../../prayer_times/data/prayer_times_repository.dart';
import 'home_grid_view.dart';
import 'home_sidebar_view.dart';

/// The home page, in whichever of its two shapes this device was set to.
///
/// The screen itself is now only the things both arrangements need and neither
/// can own: the prayer cubit, which the pull-to-refresh gesture has to reach
/// from above whatever the card could provide, and the choice between the two.
/// See [HomeGridView] and [HomeSidebarView].
///
/// The two are one screen rather than two routes on purpose. `/` is where the
/// redirect sends everybody, where a notification tap builds its stack from,
/// and where every guarded route bounces a reader who should not be somewhere;
/// a preference about layout must not be able to make any of those land on a
/// page that does not exist for this account.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Owned by the screen rather than created inside the card, so that the
  /// pull-to-refresh gesture — which is handled up here, above anything the
  /// card could provide — can reach it.
  late final _prayer = PrayerTimesCubit(PrayerTimesRepository());

  // No season is fetched here. This screen used to ask the server for the
  // current season on every open and every pull, to print one Hijri year on a
  // badge; the badge now shows today's date, which the device knows, and the
  // request went with it.

  @override
  void dispose() {
    _prayer.close();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      // Worth pulling on either arrangement, and MOST worth it on the rail: a
      // permission granted a minute ago arrives with this, and a door appears
      // in the column and a section in the guide without the app being closed
      // and opened again.
      context.read<SessionCubit>().reload(),
      // Never prompts. A drag on a list is a request for newer numbers, not a
      // gesture anybody would expect to raise a permission dialog.
      _prayer.refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    final settings = context.watch<SettingsCubit>().state;

    // Provided here rather than inside the card, so that `_refresh` — which
    // lives above anything the card could provide — can reach the same cubit.
    return BlocProvider.value(
      value: _prayer,
      child: switch (settings.homeLayout) {
        HomeLayout.grid => HomeGridView(session: session, onRefresh: _refresh),
        // The rail is not built here. It belongs to [AppShell], above the
        // router's navigator, so that it survives every page rather than being
        // rebuilt whenever somebody returns to this one.
        HomeLayout.sidebar => HomeSidebarView(
          session: session,
          onRefresh: _refresh,
        ),
      },
    );
  }
}
