import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

type Provider = "wellhub" | "totalpass";
type TotalpassIdType = "cpf" | "token" | "code" | "curp";
type Mode = "validate" | "use";

interface ValidateRequest {
  provider: Provider;
  identifier: string;
  identifier_type?: TotalpassIdType;
  mode?: Mode;
  wellhub_gym_id?: string;
  wellhub_sandbox?: boolean;
  totalpass_service_provider_code?: string;
  totalpass_plan_code?: string;
  totalpass_sandbox?: boolean;
}

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function onlyDigits(value: string) {
  return value.replace(/\D/g, "");
}

function parseErrorMessage(payload: unknown, fallback: string) {
  if (!payload || typeof payload !== "object") return fallback;
  const data = payload as Record<string, unknown>;
  if (typeof data.message === "string" && data.message) return data.message;
  if (typeof data.detail === "string" && data.detail) return data.detail;
  const errors = data.errors;
  if (Array.isArray(errors) && errors.length > 0) {
    const first = errors[0] as Record<string, unknown>;
    if (typeof first.detail === "string") return first.detail;
    const source = first.source;
    if (Array.isArray(source) && source.length > 0) {
      const src = source[0] as Record<string, unknown>;
      if (typeof src.message === "string") return src.message;
    }
    if (typeof source === "string") return source;
  }
  return fallback;
}

async function validateWellhub(
  gympassId: string,
  gymId: string,
  token: string,
  sandbox: boolean,
) {
  const base = sandbox
    ? "https://apitesting.partners.gympass.com"
    : "https://api.partners.gympass.com";
  const res = await fetch(`${base}/access/v1/validate`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "X-Gym-Id": gymId,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ gympass_id: gympassId }),
  });

  if (res.ok) {
    return { ok: true as const };
  }

  let message = "Check-in Wellhub inválido ou expirado. Faça o check-in no app Wellhub e tente de novo.";
  try {
    const data = await res.json();
    message = parseErrorMessage(data, message);
  } catch {
    // ignore
  }
  return { ok: false as const, status: res.status, message };
}

async function validateTotalpass(
  identifier: string,
  idType: TotalpassIdType,
  apiKey: string,
  serviceCode: string,
  planCode: string | undefined,
  sandbox: boolean,
  mode: Mode,
) {
  const base = sandbox
    ? "https://staging.totalpass.com/api"
    : "https://api.totalpass.com/service";
  const path = mode === "use" ? "/v1/track_usages" : "/v1/track_usages/validate";
  const attributes: Record<string, string> = {
    type: idType,
    identifier,
    service_provider_code: serviceCode,
  };
  if (planCode) {
    attributes.service_provider_plan_code = planCode;
  }

  const res = await fetch(`${base}${path}`, {
    method: "POST",
    headers: {
      "x-api-key": apiKey,
      "Content-Type": "application/json",
      Accept: "application/json",
    },
    body: JSON.stringify({
      data: {
        type: "track_usage",
        attributes,
      },
    }),
  });

  if (res.status === 204 || res.ok) {
    return { ok: true as const };
  }

  let message = mode === "use"
    ? "Token TotalPass inválido ou check-in expirado. Abra o app TotalPass, selecione a academia e faça o check-in."
    : "Assinatura TotalPass inválida para esta academia.";
  try {
    const data = await res.json();
    message = parseErrorMessage(data, message);
  } catch {
    // ignore
  }
  return { ok: false as const, status: res.status, message };
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = (await req.json()) as ValidateRequest;
    const provider = body.provider;
    const identifier = (body.identifier ?? "").trim();
    const mode: Mode = body.mode === "use" ? "use" : "validate";

    if (!provider || !identifier) {
      return jsonResponse({ ok: false, message: "provider e identifier são obrigatórios" }, 400);
    }

    if (provider === "wellhub") {
      const token = Deno.env.get("WELLHUB_BEARER_TOKEN") ?? "";
      const gymId = (body.wellhub_gym_id ?? Deno.env.get("WELLHUB_GYM_ID") ?? "").trim();
      const sandbox = body.wellhub_sandbox ?? Deno.env.get("WELLHUB_SANDBOX") === "true";

      if (!token || !gymId) {
        return jsonResponse({
          ok: false,
          message: "Configure WELLHUB_BEARER_TOKEN e WELLHUB_GYM_ID nos secrets do Supabase (ou gym ID no app).",
        }, 500);
      }

      const gympassId = onlyDigits(identifier).padStart(13, "0").slice(-13);
      if (gympassId.length !== 13) {
        return jsonResponse({ ok: false, message: "ID Wellhub deve ter 13 dígitos." }, 422);
      }

      const result = await validateWellhub(gympassId, gymId, token, sandbox);
      if (!result.ok) {
        return jsonResponse({ ok: false, message: result.message, status: result.status }, 422);
      }
      return jsonResponse({ ok: true, provider, identifier: gympassId, mode });
    }

    if (provider === "totalpass") {
      const apiKey = Deno.env.get("TOTALPASS_API_KEY") ?? "";
      const serviceCode = (body.totalpass_service_provider_code ??
        Deno.env.get("TOTALPASS_SERVICE_PROVIDER_CODE") ?? "").trim();
      const planCode = (body.totalpass_plan_code ?? Deno.env.get("TOTALPASS_PLAN_CODE") ?? "").trim() ||
        undefined;
      const sandbox = body.totalpass_sandbox ?? Deno.env.get("TOTALPASS_SANDBOX") === "true";

      if (!apiKey || !serviceCode) {
        return jsonResponse({
          ok: false,
          message: "Configure TOTALPASS_API_KEY e código da academia nos secrets do Supabase.",
        }, 500);
      }

      let idType: TotalpassIdType = body.identifier_type ?? "token";
      let normalized = identifier.trim();

      if (idType === "cpf") {
        normalized = onlyDigits(identifier);
        if (normalized.length !== 11) {
          return jsonResponse({ ok: false, message: "CPF inválido." }, 422);
        }
      }

      const result = await validateTotalpass(
        normalized,
        idType,
        apiKey,
        serviceCode,
        planCode,
        sandbox,
        mode,
      );
      if (!result.ok) {
        return jsonResponse({ ok: false, message: result.message, status: result.status }, 422);
      }
      return jsonResponse({ ok: true, provider, identifier: normalized, identifier_type: idType, mode });
    }

    return jsonResponse({ ok: false, message: "provider inválido" }, 400);
  } catch (error) {
    return jsonResponse({ ok: false, message: String(error) }, 500);
  }
});
