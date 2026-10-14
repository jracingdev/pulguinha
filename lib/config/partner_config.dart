import 'package:pulguinha/config/supabase_config.dart';
import 'package:pulguinha/models/partner_access.dart';
import 'package:pulguinha/services/partner_config_storage.dart';

class PartnerConfig {
  PartnerConfig._();

  static const edgeFunctionName = 'validate-partner-access';
  static const syncFunctionName = 'wellhub-sync';
  static const webhookFunctionName = 'wellhub-webhook';
  static const totalpassSyncFunctionName = 'totalpass-sync';
  static const totalpassWebhookFunctionName = 'totalpass-webhook';

  /// Unidade de produção no Wellhub.
  static const productionUnitName = 'Funcional do Pulguinha';
  static const productionGymId = '824346';
  static const sandboxGymId = '683';

  /// placeId numérico da unidade real na Booking API TotalPass.
  /// Não é place_api_key (UUID) nem service_provider_code (8 caracteres).
  static const totalpassProductionUnitName = 'FUNCIONAL DO PULGUINHA';
  static const totalpassProductionPlaceId = '203438';

  static String get webhookUrl => '${SupabaseConfig.url}/functions/v1/$webhookFunctionName';

  static String get totalpassWebhookUrl => '${SupabaseConfig.url}/functions/v1/$totalpassWebhookFunctionName';

  static const testGympassIds = ['1000000000001', '1000000000003'];

  static PartnerStoredConfig _stored = const PartnerStoredConfig();

  static Future<void> initialize() async {
    _stored = await PartnerConfigStorage.instance.load();
  }

  static Future<void> reload() async {
    _stored = await PartnerConfigStorage.instance.load();
  }

  static PartnerStoredConfig get stored => _stored;

  static bool get wellhubConfigured =>
      _stored.wellhubGymId.trim().isNotEmpty && _stored.wellhubBearerToken.trim().isNotEmpty;

  static bool get totalpassLegacyConfigured =>
      _stored.totalpassApiKey.trim().isNotEmpty && _stored.totalpassServiceProviderCode.trim().isNotEmpty;

  static bool get totalpassBookingConfigured => _stored.totalpassPlaceApiKey.trim().isNotEmpty;

  static bool get totalpassConfigured => totalpassBookingConfigured || totalpassLegacyConfigured;

  static bool get isAnyConfigured => wellhubConfigured || totalpassConfigured;

  /// Gym ID / código da academia salvos no aparelho (Edge Function usa secrets do Supabase).
  static bool get wellhubHasPublicConfig => _stored.wellhubGymId.trim().isNotEmpty;

  static bool get totalpassHasPublicConfig =>
      totalpassBookingConfigured || _stored.totalpassServiceProviderCode.trim().isNotEmpty;

  /// Pode tentar login por benefício (falha graciosamente se secrets ainda não existirem).
  static bool canAttemptBeneficioLogin(PartnerProvider provider) {
    if (provider == PartnerProvider.wellhub) {
      return wellhubConfigured || wellhubHasPublicConfig || SupabaseConfig.isConfigured;
    }
    return totalpassConfigured || totalpassHasPublicConfig || SupabaseConfig.isConfigured;
  }

  static List<String> missingWellhubItems() {
    final missing = <String>[];
    if (!_stored.wellhubBearerToken.trim().isNotEmpty) {
      missing.add('Token Bearer GymPass (app ou secret WELLHUB_BEARER_TOKEN)');
    }
    if (!_stored.wellhubGymId.trim().isNotEmpty) {
      missing.add('Gym ID (app ou secret WELLHUB_GYM_ID)');
    }
    return missing;
  }

  static List<String> missingTotalpassItems() {
    final missing = <String>[];
    if (!_stored.totalpassPlaceApiKey.trim().isNotEmpty) {
      missing.add('place_api_key da academia (a partner_api_key fica no Supabase)');
    }
    return missing;
  }

  static String integrationLabel() {
    final parts = <String>[];
    if (wellhubConfigured || wellhubHasPublicConfig) {
      parts.add(_stored.wellhubUseSandbox ? 'Wellhub (sandbox)' : 'Wellhub ativo');
    } else {
      parts.add('Wellhub ativo');
    }
    if (totalpassBookingConfigured) {
      parts.add(_stored.totalpassUseSandbox ? 'TotalPass (sandbox)' : 'TotalPass ativo');
    } else if (totalpassLegacyConfigured) {
      parts.add('TotalPass (catraca legada)');
    } else {
      parts.add('TotalPass (informe a place API key)');
    }
    return parts.join(' · ');
  }

  static Map<String, dynamic> publicPayload() => {
        'wellhub_gym_id': _stored.wellhubGymId.trim().isNotEmpty
            ? _stored.wellhubGymId.trim()
            : (_stored.wellhubUseSandbox ? sandboxGymId : productionGymId),
        'wellhub_sandbox': _stored.wellhubUseSandbox,
        'totalpass_service_provider_code': _stored.totalpassServiceProviderCode.trim(),
        'totalpass_plan_code': _stored.totalpassPlanCode.trim(),
        'totalpass_place_id': _stored.totalpassPlaceId.trim().isNotEmpty
            ? _stored.totalpassPlaceId.trim()
            : totalpassProductionPlaceId,
        'totalpass_sandbox': _stored.totalpassUseSandbox,
        if (_stored.totalpassPlaceApiKey.trim().isNotEmpty)
          'totalpass_place_api_key': _stored.totalpassPlaceApiKey.trim(),
      };
}
