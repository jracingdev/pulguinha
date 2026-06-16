import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pulguinha/services/notifications/notification_payload.dart';
import 'package:pulguinha/services/notifications/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  @override
  Future<void> initialize() async {
    if (_ready || kIsWeb) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    const channel = AndroidNotificationChannel(
      'pulguinha_main',
      'Pulguinha',
      description: 'Lembretes e avisos do Funcional do Pulguinha',
      importance: Importance.high,
      playSound: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return false;
  }

  NotificationDetails _details({bool playSound = true}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'pulguinha_main',
        'Pulguinha',
        channelDescription: 'Lembretes e avisos',
        importance: Importance.high,
        priority: Priority.high,
        playSound: playSound,
      ),
      iOS: DarwinNotificationDetails(presentSound: playSound),
    );
  }

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    NotificationPayload? payload,
    bool playSound = true,
  }) async {
    if (!_ready) return;
    await _plugin.show(id, title, body, _details(playSound: playSound), payload: payload?.encode());
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    NotificationPayload? payload,
  }) async {
    if (!_ready || when.isBefore(DateTime.now())) return;
    final scheduled = tz.TZDateTime.from(when, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload?.encode(),
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> registerPushToken() async {}
}
