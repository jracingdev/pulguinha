/** Espelho de lib/utils/totalpass_policy.dart. Manter as duas iguais. */

export const TOTALPASS_PRODUCTION_PLACE_ID = 203438;
export const TOTALPASS_PORTAL_TEST_PLACE_ID = 66691;

export type TotalpassPublishMode = "portal_test" | "production" | "refuse";

/** TotalPass: 0 = domingo … 6 = sábado. ISO 7 (domingo) vira 0. */
export function tpWeekday(isoWeekday: number): number {
  return isoWeekday % 7;
}

/**
 * A chave autenticada decide o destino. placeId pedido pelo app não troca
 * a unidade: teste (J Racing / 66691) publica só aula de portal; a grade
 * real só sai se o place autenticado for 203438.
 */
export function decideTotalpassPublish(authenticatedPlaceId: number | null): TotalpassPublishMode {
  if (authenticatedPlaceId === TOTALPASS_PORTAL_TEST_PLACE_ID) return "portal_test";
  if (authenticatedPlaceId === TOTALPASS_PRODUCTION_PLACE_ID) return "production";
  return "refuse";
}
