import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SupabaseSettingsStorage {
  SupabaseSettingsStorage._();
  static final instance = SupabaseSettingsStorage._();

  static const urlKey = 'supabase_url';
  static const anonKeyKey = 'supabase_anon_key_enc';

  String _encode(String value) {
    if (value.isEmpty) return '';
    return base64Encode(utf8.encode(value));
  }

  String _decode(String encoded) {
    if (encoded.isEmpty) return '';
    try {
      return utf8.decode(base64Decode(encoded));
    } catch (_) {
      return '';
    }
  }

  Future<SupabaseStoredSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SupabaseStoredSettings(
      url: prefs.getString(urlKey) ?? '',
      anonKey: _decode(prefs.getString(anonKeyKey) ?? ''),
    );
  }

  Future<void> save(SupabaseStoredSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(urlKey, settings.url.trim());
    await prefs.setString(anonKeyKey, _encode(settings.anonKey.trim()));
  }
}

class SupabaseStoredSettings {
  const SupabaseStoredSettings({this.url = '', this.anonKey = ''});

  final String url;
  final String anonKey;

  bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
