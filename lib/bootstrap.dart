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
import 'core/supabase/secure_session_storage.dart';
import 'features/notifications/data/push_service.dart';
import 'firebase_options.dart';

/// Result of app initialization, passed into the widget tree.
class AppDependencies {
  const AppDependencies({required this.prefs});
  final SharedPreferences prefs;
}

/// Brings Firebase up where there is a Firebase to bring up.
///
/// `firebase_options.dart` is generated per platform, and this project was
/// configured for Android — which is where the app ships and where push is
/// wanted. Every other platform's getter THROWS rather than returning null, so
/// running the same code on Chrome or Windows died at startup, before a single
/// screen: the whole app unavailable for want of notifications.
///
/// The app does not need Firebase to work. It needs it to be TOLD things while
/// closed. So a platform without options starts without it, and push is simply
/// off there — which [PushService] is told by there being no Firebase app at
/// all, rather than by a flag somebody has to remember to set.
///
/// Add a platform with `flutterfire configure`, and this starts working there
/// with nothing here to change.
Future<void> _initFirebaseIfConfigured() async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } on UnsupportedError {
    AppLogger.info('app', 'no Firebase for this platform — push is off');
  }
}

/// Reads a required key out of `.env`, failing with a sentence that names the
/// key instead of the bare null-check error the `!` operator used to die with.
String _requireEnv(String key) {
  final value = dotenv.env[key];
  if (value == null || value.isEmpty) {
    throw StateError(
      '.env is missing $key — copy .env.example (or ask the team for the '
      'values) and rebuild; the file ships as a bundled asset.',
    );
  }
  return value;
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
  final supabaseUrl = _requireEnv('SUPABASE_URL');
  final supabaseKey = _requireEnv('SUPABASE_ANON_KEY');

  // Prefs alongside Supabase: neither needs the other, and both are on the
  // path to the first frame.
  final prefsFuture = SharedPreferences.getInstance();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseKey,
    // The session — a live refresh token — goes to the platform keystore, not
    // the plaintext SharedPreferences file the library defaults to. Same key
    // name as the default so the first run migrates the existing session
    // instead of signing everyone out.
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureSessionStorage(
        persistSessionKey:
            'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token',
      ),
    ),
    // Every query, auth call, upload and function invocation goes through this
    // one client, so the log covers them without a line at each call site. In
    // release the wrapper is not built at all.
    httpClient: kDebugMode ? LoggingHttpClient() : null,
    // Supabase's own chatter — token refreshes, realtime socket state — which
    // is not HTTP and would otherwise go unseen.
    debug: kDebugMode,
  );

  // Off the critical path on purpose: push is explicitly non-critical (see
  // _initFirebaseIfConfigured), yet its platform-channel init was holding the
  // first frame hostage. PushService awaits this future before it talks to
  // Firebase, so nothing races it.
  PushService.firebaseInit = _initFirebaseIfConfigured();

  final prefs = await prefsFuture;

  return AppDependencies(prefs: prefs);
}
