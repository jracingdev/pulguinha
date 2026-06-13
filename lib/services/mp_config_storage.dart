import 'package:shared_preferences/shared_preferences.dart';

/// Persistência local das credenciais Mercado Pago configuráveis pelo admin.
///
/// O **Access Token** nunca é armazenado aqui — apenas public key e payment links.
class MpConfigStorage {
  MpConfigStorage._();
  static final instance = MpConfigStorage._();

  static const publicKeyKey = 'mp_public_key';
  static const linkPlanoMensalKey = 'mp_link_plano_mensal';
  static const linkPlanoTrimestralKey = 'mp_link_plano_trimestral';
  static const linkPlanoSemestralKey = 'mp_link_plano_semestral';
  static const linkPlanoAnualKey = 'mp_link_plano_anual';

  Future<MpStoredConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return MpStoredConfig(
      publicKey: prefs.getString(publicKeyKey) ?? '',
      linkPlanoMensal: prefs.getString(linkPlanoMensalKey) ?? '',
      linkPlanoTrimestral: prefs.getString(linkPlanoTrimestralKey) ?? '',
      linkPlanoSemestral: prefs.getString(linkPlanoSemestralKey) ?? '',
      linkPlanoAnual: prefs.getString(linkPlanoAnualKey) ?? '',
    );
  }

  Future<void> save(MpStoredConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(publicKeyKey, config.publicKey.trim());
    await prefs.setString(linkPlanoMensalKey, config.linkPlanoMensal.trim());
    await prefs.setString(linkPlanoTrimestralKey, config.linkPlanoTrimestral.trim());
    await prefs.setString(linkPlanoSemestralKey, config.linkPlanoSemestral.trim());
    await prefs.setString(linkPlanoAnualKey, config.linkPlanoAnual.trim());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(publicKeyKey);
    await prefs.remove(linkPlanoMensalKey);
    await prefs.remove(linkPlanoTrimestralKey);
    await prefs.remove(linkPlanoSemestralKey);
    await prefs.remove(linkPlanoAnualKey);
  }
}

class MpStoredConfig {
  const MpStoredConfig({
    this.publicKey = '',
    this.linkPlanoMensal = '',
    this.linkPlanoTrimestral = '',
    this.linkPlanoSemestral = '',
    this.linkPlanoAnual = '',
  });

  final String publicKey;
  final String linkPlanoMensal;
  final String linkPlanoTrimestral;
  final String linkPlanoSemestral;
  final String linkPlanoAnual;

  MpStoredConfig copyWith({
    String? publicKey,
    String? linkPlanoMensal,
    String? linkPlanoTrimestral,
    String? linkPlanoSemestral,
    String? linkPlanoAnual,
  }) {
    return MpStoredConfig(
      publicKey: publicKey ?? this.publicKey,
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
