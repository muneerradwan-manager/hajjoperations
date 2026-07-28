import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/supabase/supabase_client.dart';
import 'notifications_repository.dart';

/// Registers this device's FCM token for the signed-in user and surfaces
/// foreground push messages as local notifications.
class PushService {
  PushService._();
  static final instance = PushService._();

  final _local = FlutterLocalNotificationsPlugin();
  bool _started = false;

  static const _channel = AndroidNotificationChannel(
    'general',
    'General',
    description: 'General notifications',
    importance: Importance.high,
  );

  /// Whether there is a Firebase to talk to at all.
  ///
  /// False on a platform this project was never configured for — the app runs
  /// there, it simply cannot be told anything while closed. Asked of Firebase
  /// itself rather than kept as a flag, so it cannot fall out of step with what
  /// [bootstrap] actually managed to start.
  bool get _available => Firebase.apps.isNotEmpty;

  /// Call once the user is approved. Safe to call repeatedly.
  Future<void> start() async {
    if (!_available) return;
    if (_started) {
      await _upsertToken();
      return;
    }
    _started = true;

    await FirebaseMessaging.instance.requestPermission();

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.instance.onTokenRefresh.listen((_) => _upsertToken());

    await _upsertToken();
    await syncTopics();
  }

  static const _prefsKey = 'fcm_topics';

  /// Brings this device's subscriptions in line with what the user is actually
  /// part of: the whole mission, plus every file they hold a role in.
  ///
  /// The previous set is remembered on the device because FCM will not tell us
  /// what it is subscribed to — without that record, a member removed from a
  /// file would go on receiving that file's messages forever.
  Future<void> syncTopics() async {
    if (!_available) return;
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final previous = prefs.getStringList(_prefsKey)?.toSet() ?? <String>{};

      final wanted = <String>{PushTopics.all};
      for (final id in await _myModuleIds(uid)) {
        wanted.add(PushTopics.module(id));
      }

      for (final topic in wanted.difference(previous)) {
        await FirebaseMessaging.instance.subscribeToTopic(topic);
      }
      for (final topic in previous.difference(wanted)) {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      }

      await prefs.setStringList(_prefsKey, wanted.toList());
      AppLogger.info('push', 'topics: ${wanted.join(', ')}');
    } catch (e) {
      AppLogger.warn('push', 'topic sync failed: $e');
    }
  }

  /// Every file this person holds a role in — on the file itself or anywhere in
  /// its tree. RLS already limits both tables to what they may see.
  Future<Set<String>> _myModuleIds(String uid) async {
    final direct = await supabase
        .from('module_members')
        .select('module_id')
        .eq('profile_id', uid);
    final viaNodes = await supabase
        .from('module_node_members')
        .select('module_nodes(module_id)')
        .eq('profile_id', uid);

    return {
      for (final r in (direct as List).cast<Map<String, dynamic>>())
        r['module_id'] as String,
      for (final r in (viaNodes as List).cast<Map<String, dynamic>>())
        if (r['module_nodes'] case final Map node) node['module_id'] as String,
    };
  }

  /// Stops delivery to this device: no topics, and no token to send to. The
  /// inbox is untouched — the messages still arrive, the phone just stays quiet.
  Future<void> mute() async {
    if (!_available) return;
    await forgetTopics();
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await supabase
          .from('device_tokens')
          .delete()
          .eq('user_id', uid)
          .eq('token', token);
    } catch (_) {
      // Best effort; the topics are already gone, which is most of it.
    }
  }

  /// Drops every subscription. Called on sign-out, so the next person to use
  /// this device does not receive the last one's files.
  Future<void> forgetTopics() async {
    if (!_available) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final topic in prefs.getStringList(_prefsKey) ?? const <String>[]) {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      }
      await prefs.remove(_prefsKey);
    } catch (_) {
      // Best effort: a stale subscription is not worth blocking sign-out.
    }
  }

  Future<void> _upsertToken() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await supabase.from('device_tokens').upsert({
        'user_id': uid,
        'token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,token');
    } catch (_) {
      // Non-fatal — the in-app inbox still works without push.
    }
  }

  void _showForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _local.show(
      id: n.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'general',
          'General',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
