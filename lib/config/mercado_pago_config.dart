import 'package:pulguinha/config/supabase_config.dart';

/// Configuração do Mercado Pago via `--dart-define` e Supabase Edge Function.
///
/// O **access token** nunca deve ir para o app — configure `MP_ACCESS_TOKEN`
/// apenas como secret da Edge Function `create-mp-preference`.
class MercadoPagoConfig {
  static const publicKey = String.fromEnvironment('MP_PUBLIC_KEY');

  /// Links estáticos de pagamento (Payment Links do painel MP), por produto.
  static const linkPlanoMensal = String.fromEnvironment('MP_LINK_PLANO_MENSAL');
  static const linkPlanoTrimestral = String.fromEnvironment('MP_LINK_PLANO_TRIMESTRAL');
  static const linkPlanoSemestral = String.fromEnvironment('MP_LINK_PLANO_SEMESTRAL');
  static const linkPlanoAnual = String.fromEnvironment('MP_LINK_PLANO_ANUAL');
  static const linkCamiseta = String.fromEnvironment('MP_LINK_CAMISETA');
  static const linkSqueeze = String.fromEnvironment('MP_LINK_SQUEEZE');
  static const linkAulaAvulsa = String.fromEnvironment('MP_LINK_AULA_AVULSA');

  /// URL de retorno após checkout (deep link / web callback).
  static const backUrl = String.fromEnvironment(
    'MP_BACK_URL',
    defaultValue: 'pulguinha://payment/success',
  );

  static const edgeFunctionName = 'create-mp-preference';

  static bool get hasPublicKey => publicKey.isNotEmpty;

  static bool get canUseEdgeFunction => SupabaseConfig.isConfigured;

  static bool get hasStaticPaymentLinks => paymentLinkForProduct(1).isNotEmpty ||
      paymentLinkForProduct(2).isNotEmpty ||
      paymentLinkForProduct(3).isNotEmpty ||
      paymentLinkForProduct(4).isNotEmpty ||
      paymentLinkForProduct(5).isNotEmpty ||
      paymentLinkForProduct(6).isNotEmpty ||
      paymentLinkForProduct(7).isNotEmpty;

  /// Checkout real disponível quando há links estáticos ou Supabase + Edge Function.
  static bool get isRealCheckoutAvailable => hasStaticPaymentLinks || canUseEdgeFunction;

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

  static String integrationLabel() {
    if (!isRealCheckoutAvailable) return 'Modo demonstração';
    if (hasStaticPaymentLinks && canUseEdgeFunction) {
      return 'Checkout Pro (links + Edge Function)';
    }
    if (canUseEdgeFunction) return 'Checkout Pro (Edge Function)';
    return 'Payment Links Mercado Pago';
  }
}
