import 'package:pulguinha/config/supabase_config.dart';
import 'package:pulguinha/services/mp_config_storage.dart';

/// Configuração Mercado Pago por academia — salva localmente pelo admin.
class MercadoPagoConfig {
  static const _envPublicKey = String.fromEnvironment('MP_PUBLIC_KEY');
  static const _envAccessToken = String.fromEnvironment('MP_ACCESS_TOKEN');

  static const _envLinkPlanoMensal = String.fromEnvironment('MP_LINK_PLANO_MENSAL');
  static const _envLinkPlanoTrimestral = String.fromEnvironment('MP_LINK_PLANO_TRIMESTRAL');
  static const _envLinkPlanoSemestral = String.fromEnvironment('MP_LINK_PLANO_SEMESTRAL');
  static const _envLinkPlanoAnual = String.fromEnvironment('MP_LINK_PLANO_ANUAL');
  static const linkCamiseta = String.fromEnvironment('MP_LINK_CAMISETA');
  static const linkSqueeze = String.fromEnvironment('MP_LINK_SQUEEZE');
  static const linkAulaAvulsa = String.fromEnvironment('MP_LINK_AULA_AVULSA');

  static const backUrl = String.fromEnvironment(
    'MP_BACK_URL',
    defaultValue: 'pulguinha://payment/success',
  );

  static const edgeFunctionName = 'create-mp-preference';

  static MpStoredConfig _stored = const MpStoredConfig();

  static Future<void> initialize() async {
    _stored = await MpConfigStorage.instance.load();
  }

  static Future<void> reload() async {
    _stored = await MpConfigStorage.instance.load();
  }

  static String _effective(String stored, String env) =>
      stored.trim().isNotEmpty ? stored.trim() : env.trim();

  static String get publicKey => _effective(_stored.publicKey, _envPublicKey);
  static String get accessToken => _effective(_stored.accessToken, _envAccessToken);

  static String get linkPlanoMensal => _effective(_stored.linkPlanoMensal, _envLinkPlanoMensal);
  static String get linkPlanoTrimestral => _effective(_stored.linkPlanoTrimestral, _envLinkPlanoTrimestral);
  static String get linkPlanoSemestral => _effective(_stored.linkPlanoSemestral, _envLinkPlanoSemestral);
  static String get linkPlanoAnual => _effective(_stored.linkPlanoAnual, _envLinkPlanoAnual);

  static bool get hasPublicKey => publicKey.isNotEmpty;
  static bool get hasAccessToken => accessToken.isNotEmpty;
  static bool get hasStoredAccessToken => _stored.accessToken.trim().isNotEmpty;
  static bool get hasStoredPublicKey => _stored.publicKey.trim().isNotEmpty;
  static bool get hasStoredPlanLinks => _stored.hasAnyPlanLink;
  static bool get canUseEdgeFunction => SupabaseConfig.isConfigured;

  static bool get hasStaticPaymentLinks =>
      paymentLinkForProduct(1).isNotEmpty ||
      paymentLinkForProduct(2).isNotEmpty ||
      paymentLinkForProduct(3).isNotEmpty ||
      paymentLinkForProduct(4).isNotEmpty ||
      paymentLinkForProduct(5).isNotEmpty ||
      paymentLinkForProduct(6).isNotEmpty ||
      paymentLinkForProduct(7).isNotEmpty;

  static bool get isRealCheckoutAvailable => hasAccessToken || hasStaticPaymentLinks || canUseEdgeFunction;

  static String paymentLinkForProduct(int productId) {
    return switch (productId) {
      1 => linkPlanoMensal,
      2 => linkPlanoTrimestral,
      3 => linkPlanoSemestral,
      4 => linkPlanoAnual,
      5 => linkCamiseta,
      6 => linkSqueeze,
      7 => linkAulaAvulsa,
      _ => '',
    };
  }

  static bool isValidPublicKeyFormat(String key) {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return false;
    return trimmed.startsWith('TEST-') || trimmed.startsWith('APP_USR-');
  }

  static bool isValidAccessTokenFormat(String token) {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return false;
    return trimmed.startsWith('TEST-') || trimmed.startsWith('APP_USR-');
  }

  static String checkoutModeLabel() {
    if (!isRealCheckoutAvailable) return 'Não configurado';
    if (hasAccessToken) return 'Checkout Pro (Access Token)';
    if (hasStaticPaymentLinks) return 'Payment Links';
    if (canUseEdgeFunction) return 'Edge Function Supabase';
    return 'Não configurado';
  }

  static String statusIndicatorLabel() {
    if (isRealCheckoutAvailable) return '✅ Pagamentos ativos';
    return '⚠️ Configure Mercado Pago';
  }

  static String integrationLabel() {
    if (!isRealCheckoutAvailable) return 'Configure credenciais no painel admin';
    if (hasAccessToken) return 'Checkout Pro — token no app';
    if (hasStaticPaymentLinks) return 'Payment Links Mercado Pago';
    return 'Checkout Pro via Supabase';
  }
}
