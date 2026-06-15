import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Credenciais Mercado Pago configuráveis pelo admin (armazenamento local por academia).
class MpConfigStorage {
  MpConfigStorage._();
  static final instance = MpConfigStorage._();

  static const publicKeyKey = 'mp_public_key';
  static const accessTokenKey = 'mp_access_token_enc';
  static const linkPlanoMensalKey = 'mp_link_plano_mensal';
  static const linkPlanoTrimestralKey = 'mp_link_plano_trimestral';
  static const linkPlanoSemestralKey = 'mp_link_plano_semestral';
  static const linkPlanoAnualKey = 'mp_link_plano_anual';

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

  Future<MpStoredConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return MpStoredConfig(
      publicKey: prefs.getString(publicKeyKey) ?? '',
      accessToken: _decodeSecret(prefs.getString(accessTokenKey) ?? ''),
      linkPlanoMensal: prefs.getString(linkPlanoMensalKey) ?? '',
      linkPlanoTrimestral: prefs.getString(linkPlanoTrimestralKey) ?? '',
      linkPlanoSemestral: prefs.getString(linkPlanoSemestralKey) ?? '',
      linkPlanoAnual: prefs.getString(linkPlanoAnualKey) ?? '',
    );
  }

  Future<void> save(MpStoredConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(publicKeyKey, config.publicKey.trim());
    await prefs.setString(accessTokenKey, _encodeSecret(config.accessToken.trim()));
    await prefs.setString(linkPlanoMensalKey, config.linkPlanoMensal.trim());
    await prefs.setString(linkPlanoTrimestralKey, config.linkPlanoTrimestral.trim());
    await prefs.setString(linkPlanoSemestralKey, config.linkPlanoSemestral.trim());
    await prefs.setString(linkPlanoAnualKey, config.linkPlanoAnual.trim());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(publicKeyKey);
    await prefs.remove(accessTokenKey);
    await prefs.remove(linkPlanoMensalKey);
    await prefs.remove(linkPlanoTrimestralKey);
    await prefs.remove(linkPlanoSemestralKey);
    await prefs.remove(linkPlanoAnualKey);
  }
}

class MpStoredConfig {
  const MpStoredConfig({
    this.publicKey = '',
    this.accessToken = '',
    this.linkPlanoMensal = '',
    this.linkPlanoTrimestral = '',
    this.linkPlanoSemestral = '',
    this.linkPlanoAnual = '',
  });

  final String publicKey;
  final String accessToken;
  final String linkPlanoMensal;
  final String linkPlanoTrimestral;
  final String linkPlanoSemestral;
  final String linkPlanoAnual;

  MpStoredConfig copyWith({
    String? publicKey,
    String? accessToken,
    String? linkPlanoMensal,
    String? linkPlanoTrimestral,
    String? linkPlanoSemestral,
    String? linkPlanoAnual,
  }) {
    return MpStoredConfig(
      publicKey: publicKey ?? this.publicKey,
      accessToken: accessToken ?? this.accessToken,
      linkPlanoMensal: linkPlanoMensal ?? this.linkPlanoMensal,
      linkPlanoTrimestral: linkPlanoTrimestral ?? this.linkPlanoTrimestral,
      linkPlanoSemestral: linkPlanoSemestral ?? this.linkPlanoSemestral,
      linkPlanoAnual: linkPlanoAnual ?? this.linkPlanoAnual,
    );
  }

  bool get hasAnyPlanLink =>
      linkPlanoMensal.isNotEmpty ||
      linkPlanoTrimestral.isNotEmpty ||
      linkPlanoSemestral.isNotEmpty ||
      linkPlanoAnual.isNotEmpty;
}
