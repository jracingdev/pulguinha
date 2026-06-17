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
