import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PartnerConfigStorage {
  PartnerConfigStorage._();
  static final instance = PartnerConfigStorage._();

  static const wellhubTokenKey = 'partner_wellhub_token_enc';
  static const wellhubGymIdKey = 'partner_wellhub_gym_id';
  static const wellhubSandboxKey = 'partner_wellhub_sandbox';
  static const totalpassApiKeyKey = 'partner_totalpass_api_key_enc';
  static const totalpassServiceCodeKey = 'partner_totalpass_service_code';
  static const totalpassPlanCodeKey = 'partner_totalpass_plan_code';
  static const totalpassSandboxKey = 'partner_totalpass_sandbox';

  String _encodeSecret(String value) {
    if (value.isEmpty) return '';
    return base64Encode(utf8.encode(value));
  }

  String _decodeSecret(String encoded) {
    if (encoded.isEmpty) return '';
    try {
      return utf8.decode(base64Decode(encoded));
    } catch (_) {
      return '';
    }
  }

  Future<PartnerStoredConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PartnerStoredConfig(
      wellhubBearerToken: _decodeSecret(prefs.getString(wellhubTokenKey) ?? ''),
      wellhubGymId: prefs.getString(wellhubGymIdKey) ?? '',
      wellhubUseSandbox: prefs.getBool(wellhubSandboxKey) ?? false,
      totalpassApiKey: _decodeSecret(prefs.getString(totalpassApiKeyKey) ?? ''),
      totalpassServiceProviderCode: prefs.getString(totalpassServiceCodeKey) ?? '',
      totalpassPlanCode: prefs.getString(totalpassPlanCodeKey) ?? '',
      totalpassUseSandbox: prefs.getBool(totalpassSandboxKey) ?? false,
    );
  }

  Future<void> save(PartnerStoredConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(wellhubTokenKey, _encodeSecret(config.wellhubBearerToken.trim()));
    await prefs.setString(wellhubGymIdKey, config.wellhubGymId.trim());
    await prefs.setBool(wellhubSandboxKey, config.wellhubUseSandbox);
    await prefs.setString(totalpassApiKeyKey, _encodeSecret(config.totalpassApiKey.trim()));
    await prefs.setString(totalpassServiceCodeKey, config.totalpassServiceProviderCode.trim());
    await prefs.setString(totalpassPlanCodeKey, config.totalpassPlanCode.trim());
    await prefs.setBool(totalpassSandboxKey, config.totalpassUseSandbox);
  }
}

class PartnerStoredConfig {
  const PartnerStoredConfig({
    this.wellhubBearerToken = '',
    this.wellhubGymId = '',
    this.wellhubUseSandbox = false,
    this.totalpassApiKey = '',
    this.totalpassServiceProviderCode = '',
    this.totalpassPlanCode = '',
    this.totalpassUseSandbox = false,
  });

  final String wellhubBearerToken;
  final String wellhubGymId;
  final bool wellhubUseSandbox;
  final String totalpassApiKey;
  final String totalpassServiceProviderCode;
  final String totalpassPlanCode;
  final bool totalpassUseSandbox;
}
