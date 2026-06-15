import 'package:flutter/foundation.dart';

/// URLs públicas do app (web / compartilhamento).
class AppLinks {
  AppLinks._();

  static const String productionHost = 'funcionaldopulguinha.com.br';
  static const String lojaSubdomainHost = 'loja.funcionaldopulguinha.com.br';
  static const String lojaPath = '/loja';

  /// Link principal da loja pública (planos e produtos sem login).
  static String get lojaPublicUrl => 'https://$productionHost$lojaPath';

  /// Atalho curto — requer redirecionamento no Registro.br para [lojaPublicUrl].
  static String get lojaShortUrl => 'https://$lojaSubdomainHost';

  /// Passo inicial da tela pública conforme URL de entrada (somente web).
  static String get publicInitialStep => isLojaEntry ? 'loja' : 'home';

  static bool get isLojaEntry {
    if (!kIsWeb) return false;
    final uri = Uri.base;
    final host = uri.host.toLowerCase();
    final path = _normalizePath(uri.path);
    return host == lojaSubdomainHost || path == lojaPath;
  }

  static String _normalizePath(String path) {
    if (path.isEmpty) return '/';
    var normalized = path.toLowerCase();
    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}
