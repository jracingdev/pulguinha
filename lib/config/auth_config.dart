import 'package:flutter/foundation.dart';

/// Parâmetros da autenticação via Supabase Auth (login, reset de senha, deep links).
class AuthConfig {
  AuthConfig._();

  /// Mínimo exigido pelo Supabase Auth. Não reduza sem alterar o painel.
  static const int senhaMinima = 6;

  /// Esquema/host do deep link usado no retorno do e-mail de recuperação.
  static const String deepLinkScheme = 'pulguinha';
  static const String deepLinkHost = 'reset-password';

  /// Deep link mobile/desktop — precisa estar na allow-list do painel Supabase.
  static const String mobileRedirect = '$deepLinkScheme://$deepLinkHost';

  /// Caminho web que recebe o retorno do link (fragment `#access_token`/`?code`).
  static const String webPath = '/reset-password';

  /// Enquanto `true`, o login aceita as senhas antigas gravadas em `alunos`/`admins`
  /// caso a conta ainda não exista no Supabase Auth. Desligue com
  /// `--dart-define=PULG_LOGIN_LEGADO=false` depois de provisionar todos os usuários.
  static const bool loginLegadoHabilitado =
      bool.fromEnvironment('PULG_LOGIN_LEGADO', defaultValue: true);

  /// Sobrescreve o `redirectTo` (útil para ambientes de teste/preview).
  static const String _redirectOverride = String.fromEnvironment('PULG_RESET_REDIRECT');

  /// URL que o Supabase deve chamar após o usuário clicar no link do e-mail.
  ///
  /// Web usa a origem atual para funcionar em produção e em `flutter run -d chrome`;
  /// as demais plataformas usam o deep link registrado no Android/iOS.
  static String get resetRedirectUrl {
    if (_redirectOverride.trim().isNotEmpty) return _redirectOverride.trim();
    if (kIsWeb) return '${_webOrigin()}$webPath';
    return mobileRedirect;
  }

  static String _webOrigin() {
    final uri = Uri.base;
    final porta = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$porta';
  }
}
