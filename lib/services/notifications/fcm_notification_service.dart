import 'package:flutter/foundation.dart';
import 'package:pulguinha/services/notifications/local_notification_service.dart';
import 'package:pulguinha/services/notifications/notification_payload.dart';
import 'package:pulguinha/services/notifications/notification_service.dart';

/// Stub para Firebase Cloud Messaging — delega ao local até FCM ser configurado.
class FcmNotificationService implements NotificationService {
  FcmNotificationService({LocalNotificationService? delegate})
      : _delegate = delegate ?? LocalNotificationService();

  final LocalNotificationService _delegate;

  @override
  Future<void> initialize() => _delegate.initialize();

  @override
  Future<bool> requestPermission() => _delegate.requestPermission();

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
  Future<void> registerPushToken() async {
    debugPrint('FCM: registerPushToken — configure Firebase Messaging no futuro.');
  }
}
