import 'package:pulguinha/config/app_links.dart';
import 'package:pulguinha/services/pagbank_config_storage.dart';

class PagBankConfig {
  static const _envToken = String.fromEnvironment('PAGBANK_TOKEN');
  static const _envSandbox = bool.fromEnvironment('PAGBANK_SANDBOX');
  static const _envRedirectUrl = String.fromEnvironment('PAGBANK_REDIRECT_URL');

  static PagBankStoredConfig _stored = const PagBankStoredConfig();

  static Future<void> initialize() async {
    _stored = await PagBankConfigStorage.instance.load();
  }

  static Future<void> reload() async {
    _stored = await PagBankConfigStorage.instance.load();
  }

  static String get token => _stored.token.trim().isNotEmpty ? _stored.token.trim() : _envToken.trim();
  static bool get useSandbox => _stored.token.trim().isNotEmpty ? _stored.useSandbox : _envSandbox;
  static String get redirectUrl {
    final stored = _stored.redirectUrl.trim();
    if (stored.isNotEmpty) return stored;
    if (_envRedirectUrl.trim().isNotEmpty) return _envRedirectUrl.trim();
    return AppLinks.lojaPublicUrl;
  }

  static String get apiBaseUrl =>
      useSandbox ? 'https://sandbox.api.pagseguro.com' : 'https://api.pagseguro.com';

  static bool get hasToken => token.isNotEmpty;
  static bool get isRealCheckoutAvailable => hasToken;

  static bool isValidTokenFormat(String value) => value.trim().length >= 16;

  static String checkoutModeLabel() {
    if (!isRealCheckoutAvailable) return 'Não configurado';
    return useSandbox ? 'Checkout PagBank (Sandbox)' : 'Checkout PagBank (Produção)';
  }

  static String integrationLabel() {
    if (!isRealCheckoutAvailable) return 'Configure o token no painel admin';
    return checkoutModeLabel();
  }
}
