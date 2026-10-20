/// Regras puras do sync TotalPass. A Edge Function repete a mesma decisão
/// em `supabase/functions/_shared/totalpass_policy.ts`.
class TotalpassPolicy {
  TotalpassPolicy._();

  /// FUNCIONAL DO PULGUINHA.
  static const productionPlaceId = 203438;

  /// Unidade de teste do portal de desenvolvedores (J Racing).
  static const portalTestPlaceId = 66691;

  /// TotalPass: 0 = domingo … 6 = sábado. ISO 7 (domingo) vira 0.
  static int tpWeekday(int isoWeekday) => isoWeekday % 7;

  /// A chave autenticada decide o destino. O placeId pedido pelo app não
  /// troca a unidade: a de teste nunca recebe a grade real, e a real só
  /// publica quando o place autenticado é 203438.
  static TotalpassPublishMode decidePublish(int? authenticatedPlaceId) {
    if (authenticatedPlaceId == portalTestPlaceId) return TotalpassPublishMode.portalTest;
    if (authenticatedPlaceId == productionPlaceId) return TotalpassPublishMode.production;
    return TotalpassPublishMode.refuse;
  }
}

enum TotalpassPublishMode { portalTest, production, refuse }
