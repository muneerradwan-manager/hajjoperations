import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';

/// Result of app initialization, passed into the widget tree.
class AppDependencies {
  const AppDependencies({required this.prefs});
  final SharedPreferences prefs;
}

/// Initializes env, Supabase, Firebase (messaging only) and shared prefs.
Future<AppDependencies> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();

  return AppDependencies(prefs: prefs);
}
