import 'package:bloc/bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/logging/app_bloc_observer.dart';
import 'core/logging/app_logger.dart';
import 'core/logging/logging_http_client.dart';
import 'core/logging/error_reporting.dart';
import 'firebase_options.dart';

/// Result of app initialization, passed into the widget tree.
class AppDependencies {
  const AppDependencies({required this.prefs});
  final SharedPreferences prefs;
}

/// Initializes env, Supabase, Firebase (messaging only) and shared prefs.
Future<AppDependencies> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Logging goes in first, so that a failure in everything below it is itself
  // logged rather than lost.
  installErrorLogging();
  Bloc.observer = const AppBlocObserver();
  AppLogger.info('app', 'starting — debug logging on');

  // Edge-to-edge with transparent system bars: the aurora backdrop runs behind
  // the status and navigation bars instead of stopping at a grey strip.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0x00000000),
      systemNavigationBarColor: Color(0x00000000),
      systemNavigationBarDividerColor: Color(0x00000000),
    ),
  );

  await dotenv.load();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
    // Every query, auth call, upload and function invocation goes through this
    // one client, so the log covers them without a line at each call site. In
    // release the wrapper is not built at all.
    httpClient: kDebugMode ? LoggingHttpClient() : null,
    // Supabase's own chatter — token refreshes, realtime socket state — which
    // is not HTTP and would otherwise go unseen.
    debug: kDebugMode,
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();

  return AppDependencies(prefs: prefs);
}
