import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Inicializa ou reinicializa o cliente Supabase (útil após salvar credenciais).
class SupabaseBootstrap {
  static String? _activeUrl;
  static String? _activeKey;
  static bool _clientReady = false;

  static Future<void> ensureInitialized({
    required String url,
    required String anonKey,
  }) async {
    final trimmedUrl = url.trim();
    final trimmedKey = anonKey.trim();
    if (trimmedUrl.isEmpty || trimmedKey.isEmpty) {
      throw StateError('URL ou chave anon do Supabase vazias.');
    }

    if (_clientReady && _activeUrl == trimmedUrl && _activeKey == trimmedKey) {
      return;
    }

    if (_clientReady) {
      try {
        await Supabase.instance.dispose();
      } catch (e) {
        debugPrint('Supabase dispose: $e');
      }
      _clientReady = false;
    }

    await Supabase.initialize(
      url: trimmedUrl,
      anonKey: trimmedKey, // ignore: deprecated_member_use
    );
    _activeUrl = trimmedUrl;
    _activeKey = trimmedKey;
    _clientReady = true;
  }
}
