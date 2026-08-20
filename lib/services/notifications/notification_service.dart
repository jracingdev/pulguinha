import 'package:flutter/foundation.dart';
import 'package:pulguinha/services/notifications/fcm_notification_service.dart';
import 'package:pulguinha/services/notifications/local_notification_service.dart';
import 'package:pulguinha/services/notifications/notification_payload.dart';

/// Fachada de notificações — local + FCM quando Firebase estiver configurado.
abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    NotificationPayload? payload,
    bool playSound = true,
  });
  Future<void> schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    NotificationPayload? payload,
  });
  Future<void> cancel(int id);
  Future<void> cancelAll();

  /// Registra o token FCM (quando disponível) e retorna o valor.
  Future<String?> registerPushToken();

  static NotificationService instance = _create();

  static NotificationService _create() {
    if (kIsWeb) return _NoopNotificationService();
    return LocalNotificationService();
  }

  /// Troca a implementação para FCM (mantém o local como fallback de agenda).
  static FcmNotificationService useFcmWhenReady() {
    final fcm = FcmNotificationService(delegate: LocalNotificationService());
    instance = fcm;
    return fcm;
  }
}

class _NoopNotificationService implements NotificationService {
  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<String?> registerPushToken() async => null;

  @override
  Future<void> schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    NotificationPayload? payload,
  }) async {}

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    NotificationPayload? payload,
    bool playSound = true,
  }) async {}
}
