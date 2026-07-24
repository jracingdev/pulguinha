import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pulguinha/services/password_recovery_notifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Inicializa ou reinicializa o cliente Supabase (útil após salvar credenciais).
class SupabaseBootstrap {
  static String? _activeUrl;
  static String? _activeKey;
  static bool _clientReady = false;
  static StreamSubscription<AuthState>? _authSub;

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
      await _authSub?.cancel();
      _authSub = null;
      try {
        await Supabase.instance.dispose();
      } catch (e) {
        debugPrint('Supabase dispose: $e');
      }
      _clientReady = false;
    }

    // O Supabase limpa o fragment da URL ao processar o link; registramos antes.
    PasswordRecoveryNotifier.instance.capturarLinkWeb();

    await Supabase.initialize(
      url: trimmedUrl,
      anonKey: trimmedKey, // ignore: deprecated_member_use
    );
    _activeUrl = trimmedUrl;
    _activeKey = trimmedKey;
    _clientReady = true;
    _escutarAuth();
  }

  static void _escutarAuth() {
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
      (estado) {
        if (estado.event == AuthChangeEvent.passwordRecovery) {
          PasswordRecoveryNotifier.instance.ativarComSessao();
        }
      },
      onError: (Object e) => debugPrint('onAuthStateChange: $e'),
    );
  }
}
