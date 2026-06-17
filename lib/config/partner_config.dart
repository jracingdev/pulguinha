import 'package:pulguinha/config/supabase_config.dart';
import 'package:pulguinha/models/partner_access.dart';
import 'package:pulguinha/services/partner_config_storage.dart';

class PartnerConfig {
  PartnerConfig._();

  static const edgeFunctionName = 'validate-partner-access';

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

  static bool get totalpassConfigured =>
      _stored.totalpassApiKey.trim().isNotEmpty && _stored.totalpassServiceProviderCode.trim().isNotEmpty;

  static bool get isAnyConfigured => wellhubConfigured || totalpassConfigured;

  /// Gym ID / código da academia salvos no aparelho (Edge Function usa secrets do Supabase).
  static bool get wellhubHasPublicConfig => _stored.wellhubGymId.trim().isNotEmpty;

  static bool get totalpassHasPublicConfig => _stored.totalpassServiceProviderCode.trim().isNotEmpty;

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
    if (!_stored.totalpassApiKey.trim().isNotEmpty) {
      missing.add('API Key (app ou secret TOTALPASS_API_KEY)');
    }
    if (!_stored.totalpassServiceProviderCode.trim().isNotEmpty) {
      missing.add('Código da academia (app ou secret TOTALPASS_SERVICE_PROVIDER_CODE)');
    }
    return missing;
  }

  static String integrationLabel() {
    final parts = <String>[];
    if (wellhubConfigured) {
      parts.add(_stored.wellhubUseSandbox ? 'GymPass (sandbox)' : 'GymPass');
    }
    if (totalpassConfigured) {
      parts.add(_stored.totalpassUseSandbox ? 'TotalPass (sandbox)' : 'TotalPass');
    }
    if (parts.isEmpty) return 'Configure GymPass e/ou TotalPass no painel admin';
    return parts.join(' · ');
  }

  static Map<String, dynamic> publicPayload() => {
        'wellhub_gym_id': _stored.wellhubGymId.trim(),
        'wellhub_sandbox': _stored.wellhubUseSandbox,
        'totalpass_service_provider_code': _stored.totalpassServiceProviderCode.trim(),
        'totalpass_plan_code': _stored.totalpassPlanCode.trim(),
        'totalpass_sandbox': _stored.totalpassUseSandbox,
      };
}
