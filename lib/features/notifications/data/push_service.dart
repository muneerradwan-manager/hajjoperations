import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/supabase/supabase_client.dart';

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

  /// Call once the user is approved. Safe to call repeatedly.
  Future<void> start() async {
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
