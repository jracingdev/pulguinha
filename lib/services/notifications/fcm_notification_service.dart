import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:pulguinha/services/notifications/local_notification_service.dart';
import 'package:pulguinha/services/notifications/notification_payload.dart';
import 'package:pulguinha/services/notifications/notification_service.dart';

/// Handler de mensagens em background (precisa ser top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Mantém o isolate vivo; a notificação de sistema é exibida pelo FCM no Android.
  debugPrint('FCM background: ${message.messageId} ${message.notification?.title}');
}

/// FCM real com fallback local para agendamentos/agendas.
///
/// Só funciona após `Firebase.initializeApp()` e `google-services.json` (Android).
/// Ver `docs/fcm-setup.md`.
class FcmNotificationService implements NotificationService {
  FcmNotificationService({LocalNotificationService? delegate})
      : _delegate = delegate ?? LocalNotificationService();

  final LocalNotificationService _delegate;
  StreamSubscription<String>? _tokenRefreshSub;
  String? lastToken;

  /// Callback opcional para persistir o token (ex.: Supabase).
  Future<void> Function(String token)? onToken;

  @override
  Future<void> initialize() async {
    await _delegate.initialize();
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      final messaging = FirebaseMessaging.instance;
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onMessage.listen((msg) async {
        final n = msg.notification;
        if (n == null) return;
        await _delegate.showNow(
          id: msg.hashCode & 0x7fffffff,
          title: n.title ?? 'Pulguinha',
          body: n.body ?? '',
          playSound: true,
        );
      });
    } catch (e) {
      debugPrint('FCM initialize parcial: $e');
    }
  }

  @override
  Future<bool> requestPermission() async {
    final local = await _delegate.requestPermission();
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return local ||
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('FCM permission: $e');
      return local;
    }
  }

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    NotificationPayload? payload,
    bool playSound = true,
  }) =>
      _delegate.showNow(id: id, title: title, body: body, payload: payload, playSound: playSound);

  @override
  Future<void> schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    NotificationPayload? payload,
  }) =>
      _delegate.schedule(id: id, when: when, title: title, body: body, payload: payload);

  @override
  Future<void> cancel(int id) => _delegate.cancel(id);

  @override
  Future<void> cancelAll() => _delegate.cancelAll();

  @override
  Future<String?> registerPushToken() async {
    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('FCM: Firebase não inicializado — token ignorado.');
        return null;
      }
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      lastToken = token;
      if (token != null && onToken != null) {
        await onToken!(token);
      }
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = messaging.onTokenRefresh.listen((t) async {
        lastToken = t;
        if (onToken != null) await onToken!(t);
      });
      debugPrint('FCM token registrado (${token?.substring(0, 12)}…)');
      return token;
    } catch (e) {
      debugPrint('FCM registerPushToken: $e');
      return null;
    }
  }
}
