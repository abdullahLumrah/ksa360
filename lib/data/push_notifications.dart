import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../firebase_options.dart';
import 'app_api.dart';
import 'auth_session.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Requests permission after the UI is up, keeps the FCM token on the API,
/// and surfaces foreground messages as a system notification on Android.
class PushNotifications {
  PushNotifications._();
  static final PushNotifications instance = PushNotifications._();

  static const _native = MethodChannel('ksa360/push');
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  String? _token;
  var _listening = false;
  Future<void>? _start;

  Future<void> start() {
    if (_listening) return syncToken();
    return _start ??= _startOnce().catchError((Object e) {
      _start = null;
      debugPrint('push start failed: $e');
    });
  }

  Future<void> _startOnce() async {
    await AuthSession.instance.load();
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      _start = null;
      debugPrint('push permission denied');
      return;
    }
    if (!_listening) {
      _listening = true;
      FirebaseMessaging.onMessage.listen(_showForeground);
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        _token = token;
        unawaited(syncToken());
      });
      AuthSession.instance.addListener(syncToken);
    }
    await syncToken();
  }

  Future<void> syncToken() async {
    await AuthSession.instance.load();
    Object? last;
    const pauses = <Duration>[
      Duration.zero,
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
    ];
    for (final pause in pauses) {
      if (pause > Duration.zero) await Future<void>.delayed(pause);
      try {
        await _syncTokenOnce();
        return;
      } catch (e) {
        last = e;
        debugPrint('push token sync failed: $e');
      }
    }
    if (last != null) debugPrint('push token sync gave up: $last');
  }

  Future<void> _syncTokenOnce() async {
    _token ??= await FirebaseMessaging.instance.getToken();
    final token = _token;
    if (token == null || token.isEmpty) {
      throw StateError('push token missing');
    }
    final platform = Platform.isIOS ? 'ios' : 'android';
    final res = await AppApi.post(
      AppApi.uri('/me/push-token'),
      body: jsonEncode({'token': token, 'platform': platform}),
    );
    if (res.statusCode >= 400) {
      throw HttpException(
        'HTTP ${res.statusCode} ${res.body}',
        uri: res.request?.url,
      );
    }
  }

  void _showForeground(RemoteMessage message) {
    final title = _text(
      message.notification?.title,
      message.data['title'],
      'KSA 360',
    );
    final body = _text(message.notification?.body, message.data['body'], '');
    debugPrint('push foreground: $title');
    unawaited(_present(title, body));
  }

  static String _text(String? notification, String? data, String fallback) {
    final fromNotification = notification?.trim() ?? '';
    if (fromNotification.isNotEmpty) return fromNotification;
    final fromData = data?.trim() ?? '';
    if (fromData.isNotEmpty) return fromData;
    return fallback;
  }

  Future<void> _present(String title, String body) async {
    if (Platform.isAndroid) {
      try {
        await _native.invokeMethod('show', {'title': title, 'body': body});
        return;
      } catch (e) {
        debugPrint('push native banner failed: $e');
      }
    }
    final messenger = messengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(body.isEmpty ? title : '$title\n$body'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
