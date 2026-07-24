import 'package:flutter/foundation.dart';
import 'package:pulguinha/services/supabase_settings_storage.dart';

/// Credenciais do projeto Pulguinha (chave anon é pública no modelo Supabase; RLS protege os dados).
class SupabaseConfig {
  static const defaultUrl = 'https://tvztfgjmhxmwjzsnugic.supabase.co';
  static const defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR2enRmZ2ptaHhtd2p6c251Z2ljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzMzI2MzMsImV4cCI6MjA5NjkwODYzM30.8Vylia_S63jWgK-mBNCSXevlOrdZGvYYsHRbkAkg2X8';

  static const _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const _envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static SupabaseStoredSettings _stored = const SupabaseStoredSettings();
  static bool _desabilitado = false;

  static Future<void> initialize() async {
    _stored = await SupabaseSettingsStorage.instance.load();
  }

  /// Mantém o app em modo local nos testes (sem rede nem timers do Supabase).
  @visibleForTesting
  static void desabilitarParaTestes() {
    _stored = const SupabaseStoredSettings();
    _desabilitado = true;
  }

  static Future<void> reload() async {
    _stored = await SupabaseSettingsStorage.instance.load();
  }

  /// Prioridade: `--dart-define` → prefs salvas no aparelho → defaults commitados.
  static String get url => _resolve(_envUrl, _stored.url, defaultUrl);
  static String get anonKey => _resolve(_envAnonKey, _stored.anonKey, defaultAnonKey);

  static bool get hasStoredSettings => _stored.isConfigured;
  static bool get hasEmbeddedDefaults => defaultUrl.isNotEmpty && defaultAnonKey.isNotEmpty;
  static bool get isConfigured => !_desabilitado && url.isNotEmpty && anonKey.isNotEmpty;

  /// Verdadeiro quando o admin sobrescreveu as credenciais embutidas no aparelho.
  static bool get usesStoredOverride => _stored.isConfigured;

  static String _resolve(String env, String stored, String fallback) {
    final fromEnv = env.trim();
    if (fromEnv.isNotEmpty) return fromEnv;
    final fromStored = stored.trim();
    if (fromStored.isNotEmpty) return fromStored;
    return fallback.trim();
  }
}
