import 'package:pulguinha/config/app_links.dart';
import 'package:pulguinha/config/supabase_config.dart';
import 'package:pulguinha/services/pagbank_config_storage.dart';

class PagBankConfig {
  static const _envSandbox = bool.fromEnvironment('PAGBANK_SANDBOX');
  static const _envRedirectUrl = String.fromEnvironment('PAGBANK_REDIRECT_URL');

  static PagBankStoredConfig _stored = const PagBankStoredConfig();

  /// Liga o PagBank no app. O token fica só nos secrets do Supabase
  /// (`PAGBANK_TOKEN`, `PAGBANK_SANDBOX`) e o checkout é criado pela Edge
  /// Function `create-pagbank-checkout`. Build: `--dart-define=PAGBANK_SERVIDOR=true`.
  static const servidorHabilitado = bool.fromEnvironment('PAGBANK_SERVIDOR');
  static const edgeFunctionName = 'create-pagbank-checkout';

  static Future<void> initialize() async {
    _stored = await PagBankConfigStorage.instance.load();
    // Versões antigas guardavam o token no aparelho: apaga a cópia local.
    if (_stored.token.trim().isNotEmpty) {
      _stored = PagBankStoredConfig(redirectUrl: _stored.redirectUrl);
      await PagBankConfigStorage.instance.save(_stored);
    }
  }

  static Future<void> reload() async {
    _stored = await PagBankConfigStorage.instance.load();
  }

  /// O app não guarda nem envia token do PagBank (fica no servidor).
  static String get token => '';
  static bool get useSandbox => _envSandbox;
  static String get redirectUrl {
    final stored = _stored.redirectUrl.trim();
    if (stored.isNotEmpty) return stored;
    if (_envRedirectUrl.trim().isNotEmpty) return _envRedirectUrl.trim();
    return AppLinks.lojaPublicUrl;
  }

  static String get apiBaseUrl =>
      useSandbox ? 'https://sandbox.api.pagseguro.com' : 'https://api.pagseguro.com';

  static bool get hasToken => false;
  static bool get isRealCheckoutAvailable => servidorHabilitado && SupabaseConfig.isConfigured;

  static bool isValidTokenFormat(String value) => value.trim().length >= 16;

  static String checkoutModeLabel() {
    if (!isRealCheckoutAvailable) return 'Não configurado';
    return useSandbox ? 'Checkout PagBank (Sandbox)' : 'Checkout PagBank (Produção)';
  }

  static String integrationLabel() {
    if (!isRealCheckoutAvailable) return 'Configure PAGBANK_TOKEN nos secrets do Supabase';
    return checkoutModeLabel();
  }
}
