enum PartnerProvider { wellhub, totalpass }

enum TotalpassIdentifierType { cpf, token, code }

enum PartnerAccessMode { validate, use }

class PartnerAccessResult {
  const PartnerAccessResult({
    required this.ok,
    this.message,
    this.provider,
    this.identifier,
    this.identifierType,
    this.mode,
  });

  final bool ok;
  final String? message;
  final PartnerProvider? provider;
  final String? identifier;
  final TotalpassIdentifierType? identifierType;
  final PartnerAccessMode? mode;

  factory PartnerAccessResult.success({
    required PartnerProvider provider,
    required String identifier,
    TotalpassIdentifierType? identifierType,
    PartnerAccessMode? mode,
  }) =>
      PartnerAccessResult(
        ok: true,
        provider: provider,
        identifier: identifier,
        identifierType: identifierType,
        mode: mode,
      );

  factory PartnerAccessResult.failure(String message) => PartnerAccessResult(ok: false, message: message);
}

extension PartnerProviderX on PartnerProvider {
  String get label => this == PartnerProvider.wellhub ? 'GymPass' : 'TotalPass';

  String get dbValue => name;

  static PartnerProvider? fromDb(String? value) {
    switch (value?.toLowerCase()) {
      case 'wellhub':
        return PartnerProvider.wellhub;
      case 'totalpass':
        return PartnerProvider.totalpass;
      default:
        return null;
    }
  }
}

extension TotalpassIdentifierTypeX on TotalpassIdentifierType {
  String get apiValue => name;
}
