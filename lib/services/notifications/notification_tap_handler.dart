import 'package:pulguinha/services/notifications/notification_payload.dart';

/// Encaminha o toque em notificação local/FCM para o AppState.
///
/// O tap pode chegar antes do AppState existir (app aberto pela bandeja),
/// então o payload fica retido até [bind].
class NotificationTapHandler {
  NotificationTapHandler._();

  static final NotificationTapHandler instance = NotificationTapHandler._();

  NotificationPayload? _pendente;
  void Function(NotificationPayload payload)? _listener;

  void handleRaw(String? raw) => handle(NotificationPayload.decode(raw));

  void handle(NotificationPayload? payload) {
    if (payload == null) return;
    final listener = _listener;
    if (listener != null) {
      listener(payload);
    } else {
      _pendente = payload;
    }
  }

  void bind(void Function(NotificationPayload payload) listener) {
    _listener = listener;
    final pendente = _pendente;
    _pendente = null;
    if (pendente != null) listener(pendente);
  }

  void unbind() {
    _listener = null;
    _pendente = null;
  }
}
