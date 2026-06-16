import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsStorage {
  NotificationSettingsStorage._();
  static final instance = NotificationSettingsStorage._();

  static const _enabledKey = 'notif_enabled';
  static const _soundKey = 'notif_sound';
  static const _aulaKey = 'notif_aula';
  static const _vencKey = 'notif_vencimento';
  static const _comunicacaoKey = 'notif_comunicacao';

  Future<NotificationSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return NotificationSettings(
      enabled: p.getBool(_enabledKey) ?? true,
      sound: p.getBool(_soundKey) ?? true,
      lembreteAula: p.getBool(_aulaKey) ?? true,
      lembreteVencimento: p.getBool(_vencKey) ?? true,
      comunicacao: p.getBool(_comunicacaoKey) ?? true,
    );
  }

  Future<void> save(NotificationSettings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_enabledKey, s.enabled);
    await p.setBool(_soundKey, s.sound);
    await p.setBool(_aulaKey, s.lembreteAula);
    await p.setBool(_vencKey, s.lembreteVencimento);
    await p.setBool(_comunicacaoKey, s.comunicacao);
  }
}

class NotificationSettings {
  const NotificationSettings({
    this.enabled = true,
    this.sound = true,
    this.lembreteAula = true,
    this.lembreteVencimento = true,
    this.comunicacao = true,
  });

  final bool enabled;
  final bool sound;
  final bool lembreteAula;
  final bool lembreteVencimento;
  final bool comunicacao;

  NotificationSettings copyWith({
    bool? enabled,
    bool? sound,
    bool? lembreteAula,
    bool? lembreteVencimento,
    bool? comunicacao,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      sound: sound ?? this.sound,
      lembreteAula: lembreteAula ?? this.lembreteAula,
      lembreteVencimento: lembreteVencimento ?? this.lembreteVencimento,
      comunicacao: comunicacao ?? this.comunicacao,
    );
  }
}
