import 'package:pulguinha/services/supabase_settings_storage.dart';

class SupabaseConfig {
  static const _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const _envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static SupabaseStoredSettings _stored = const SupabaseStoredSettings();

  static Future<void> initialize() async {
    _stored = await SupabaseSettingsStorage.instance.load();
  }

  static Future<void> reload() async {
    _stored = await SupabaseSettingsStorage.instance.load();
  }

  static String get url => _pick(_stored.url, _envUrl);
  static String get anonKey => _pick(_stored.anonKey, _envAnonKey);

  static bool get hasStoredSettings => _stored.isConfigured;
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static String _pick(String stored, String env) =>
      stored.trim().isNotEmpty ? stored.trim() : env.trim();
}
