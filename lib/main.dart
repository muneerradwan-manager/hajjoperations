import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'core/logging/app_logger.dart';

Future<void> main() async {
  // The third error channel: anything thrown outside the framework and outside
  // an awaited Future lands here. `bootstrap` and `runApp` are both inside the
  // zone deliberately — the binding has to be initialised in the same zone the
  // app runs in, or Flutter complains at every frame.
  runZonedGuarded(
    () async {
      final deps = await bootstrap();
      runApp(HajjOperationsApp(deps: deps));
    },
    (error, stack) => AppLogger.error('zone', 'uncaught', error, stack),
  );
}
