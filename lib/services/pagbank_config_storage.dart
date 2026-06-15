import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PagBankConfigStorage {
  PagBankConfigStorage._();
  static final instance = PagBankConfigStorage._();

  static const tokenKey = 'pagbank_token_enc';
  static const sandboxKey = 'pagbank_sandbox';
  static const redirectUrlKey = 'pagbank_redirect_url';

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

  Future<PagBankStoredConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PagBankStoredConfig(
      token: _decodeSecret(prefs.getString(tokenKey) ?? ''),
      useSandbox: prefs.getBool(sandboxKey) ?? false,
      redirectUrl: prefs.getString(redirectUrlKey) ?? '',
    );
  }

  Future<void> save(PagBankStoredConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, _encodeSecret(config.token.trim()));
    await prefs.setBool(sandboxKey, config.useSandbox);
    await prefs.setString(redirectUrlKey, config.redirectUrl.trim());
  }
}

class PagBankStoredConfig {
  const PagBankStoredConfig({
    this.token = '',
    this.useSandbox = false,
    this.redirectUrl = '',
  });

  final String token;
  final bool useSandbox;
  final String redirectUrl;
}
