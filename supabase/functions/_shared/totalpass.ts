import {
  onlyDigits,
  saoPauloDateISO,
  serviceClient,
  type SupabaseClient,
} from "./wellhub.ts";

export { onlyDigits, saoPauloDateISO, serviceClient };
export type { SupabaseClient };

export const RENEW_SKEW_MS = 20_000;

export type TotalpassHost = "booking" | "checkin";

type CacheEntry = { token: string; expMs: number; fetchedAt: number };
const tokenCache = new Map<string, CacheEntry>();

let sandboxOverride: boolean | undefined;

export function setTotalpassSandboxOverride(value: boolean | undefined) {
  sandboxOverride = value;
}

export function envSandbox() {
  if (sandboxOverride !== undefined) return sandboxOverride;
  return (Deno.env.get("TOTALPASS_SANDBOX") ?? "false").toLowerCase() === "true";
}

export function envPartnerKey() {
  return (Deno.env.get("TOTALPASS_PARTNER_API_KEY") ?? "").trim();
}

export function envPlaceKey() {
  return (Deno.env.get("TOTALPASS_PLACE_API_KEY") ?? "").trim();
}

export function bookingBase(sandbox: boolean) {
  return sandbox
    ? "https://booking-api.staging.totalpass.com"
    : "https://booking-api.totalpass.com";
}

export function checkinBase(sandbox: boolean) {
  return sandbox
    ? "https://gym-service-api.staging.totalpass.com"
    : "https://gym-service-api.totalpass.com";
}

export function hostBase(host: TotalpassHost, sandbox: boolean) {
  return host === "booking" ? bookingBase(sandbox) : checkinBase(sandbox);
}

export function decodeJwtPayload(token: string): Record<string, unknown> | null {
  const part = token.split(".")[1];
  if (!part) return null;
  const b64 = part.replace(/-/g, "+").replace(/_/g, "/");
  const pad = b64.length % 4 === 0 ? "" : "=".repeat(4 - (b64.length % 4));
  try {
    return JSON.parse(atob(b64 + pad)) as Record<string, unknown>;
  } catch {
    return null;
  }
}

/** exp em ms. Booking manda segundos; o check-in deste parceiro mandou milissegundos. */
export function jwtExpMs(token: string): number | null {
  const payload = decodeJwtPayload(token);
  const exp = Number(payload?.exp);
  if (!Number.isFinite(exp) || exp <= 0) return null;
  return exp >= 1e12 ? exp : exp * 1000;
}

export function isTotalpassUrl(raw: string) {
  try {
    const url = new URL(raw);
    if (url.protocol !== "https:") return false;
    const host = url.hostname.toLowerCase();
    return host === "totalpass.com" || host.endsWith(".totalpass.com");
  } catch {
    return false;
  }
}

export function redactUrl(raw: string) {
  try {
    const url = new URL(raw);
    const parts = url.pathname.split("/");
    if (parts.length > 1) parts[parts.length - 1] = "***";
    return `${url.origin}${parts.join("/")}`;
  } catch {
    return "url-invalida";
  }
}

function cacheKey(base: string, place: string) {
  return `${base}|${place}`;
}

export async function totalpassToken(opts: {
  host: TotalpassHost;
  placeApiKey?: string;
  sandbox?: boolean;
}) {
  const place = (opts.placeApiKey || envPlaceKey()).trim();
  const partner = envPartnerKey();
  if (!place || !partner) {
    throw new Error("Configure TOTALPASS_PLACE_API_KEY e TOTALPASS_PARTNER_API_KEY nos secrets.");
  }
  const sandbox = opts.sandbox ?? envSandbox();
  const base = hostBase(opts.host, sandbox);
  const key = cacheKey(base, place);
  const cached = tokenCache.get(key);
  const now = Date.now();
  if (cached && (cached.expMs - now > RENEW_SKEW_MS || now - cached.fetchedAt < 5000)) {
    return { token: cached.token, base, sandbox, expMs: cached.expMs };
  }

  const res = await fetch(`${base}/partner/auth`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Accept: "application/json" },
    body: JSON.stringify({ place_api_key: place, partner_api_key: partner }),
  });
  const text = await res.text();
  let json: Record<string, unknown> | null = null;
  try {
    json = text ? JSON.parse(text) as Record<string, unknown> : null;
  } catch {
    json = null;
  }
  const token = typeof json?.token === "string" ? json.token : "";
  if (res.status !== 201 || !token) {
    tokenCache.delete(key);
    throw new Error(`TotalPass auth ${opts.host} HTTP ${res.status}`);
  }
  const expMs = jwtExpMs(token) ?? now + 60_000;
  tokenCache.set(key, { token, expMs, fetchedAt: now });
  return { token, base, sandbox, expMs };
}

export async function totalpassFetch(
  host: TotalpassHost,
  path: string,
  init: RequestInit & { placeApiKey?: string; sandbox?: boolean; retry?: boolean } = {},
) {
  const auth = await totalpassToken({
    host,
    placeApiKey: init.placeApiKey,
    sandbox: init.sandbox,
  });
  const headers = new Headers(init.headers);
  headers.set("Authorization", `Bearer ${auth.token}`);
  headers.set("Accept", "application/json");
  if (init.body && !headers.has("Content-Type")) headers.set("Content-Type", "application/json");
  const urlPath = path.startsWith("/") ? path : `/${path}`;
  const method = (init.method ?? "GET").toUpperCase();
  const res = await fetch(`${auth.base}${urlPath}`, { method, headers, body: init.body });
  const text = await res.text();
  let json: unknown = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    json = text;
  }
  if (res.status === 401 && !init.retry) {
    const place = (init.placeApiKey || envPlaceKey()).trim();
    tokenCache.delete(cacheKey(auth.base, place));
    return totalpassFetch(host, path, { ...init, retry: true });
  }
  console.log(`[totalpass] ${method} ${host} ${urlPath} → HTTP ${res.status}`);
  return { ok: res.ok || res.status === 201, status: res.status, json, text, sandbox: auth.sandbox };
}

export function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : {};
}

export function asArray(payload: unknown, keys: string[]): Record<string, unknown>[] {
  if (Array.isArray(payload)) return payload as Record<string, unknown>[];
  if (payload && typeof payload === "object") {
    const obj = payload as Record<string, unknown>;
    for (const key of keys) {
      if (Array.isArray(obj[key])) return obj[key] as Record<string, unknown>[];
    }
  }
  return [];
}

export type TotalpassPlan = { id: number; code: string; name: string };

/** placeId numérico da Booking API. Não é place_api_key nem service_provider_code. */
export function extractAuthenticatedPlace(payload: unknown): { name: string; placeId: number | null } {
  const obj = asRecord(payload);
  const plans = asArray(payload, ["Plans", "plans", "data"]);
  const rawId = obj.placeId ?? plans[0]?.placeId;
  const placeId = Number(rawId);
  return {
    name: String(obj.name ?? ""),
    placeId: Number.isFinite(placeId) && placeId > 0 ? placeId : null,
  };
}

export function extractPlans(payload: unknown): TotalpassPlan[] {
  const lists = [
    ...asArray(payload, ["Plans", "plans", "data"]),
  ];
  const out: TotalpassPlan[] = [];
  for (const item of lists) {
    const id = Number(item.id);
    if (!Number.isFinite(id)) continue;
    out.push({
      id,
      code: String(item.code ?? ""),
      name: String(item.name ?? ""),
    });
  }
  return out;
}

export function cpfFromUser(user: Record<string, unknown>) {
  const type = String(user.document_type ?? user.documentType ?? "").toLowerCase();
  const raw = String(
    user.document_number ?? user.documentNumber ?? user.cpf ?? user.document ?? "",
  );
  const digits = onlyDigits(raw);
  if (digits.length === 11) return digits;
  if (type && type !== "cpf") return "";
  return "";
}

export async function hasTotalpassCheckinToday(db: SupabaseClient, cpf: string) {
  const day = saoPauloDateISO();
  const { data, error } = await db
    .from("totalpass_daily_checkins")
    .select("id")
    .eq("cpf", cpf)
    .eq("checkin_date", day)
    .maybeSingle();
  if (error) {
    console.warn("[totalpass] lookup check-in", error.message);
    return false;
  }
  return !!data;
}

export async function markTotalpassCheckinToday(
  db: SupabaseClient,
  cpf: string,
  source: string,
  extra?: { plan_code?: string; slot_id?: string },
) {
  const day = saoPauloDateISO();
  const { error } = await db.from("totalpass_daily_checkins").upsert(
    {
      cpf,
      checkin_date: day,
      source,
      plan_code: extra?.plan_code ?? null,
      slot_id: extra?.slot_id ?? null,
      validated_at: new Date().toISOString(),
    },
    { onConflict: "cpf,checkin_date" },
  );
  if (error) console.error("[totalpass] mark check-in", error.message);
  return !error;
}

export async function upsertAlunoFromTotalpass(
  db: SupabaseClient,
  user: Record<string, unknown>,
) {
  const cpf = cpfFromUser(user);
  if (cpf.length !== 11) return null;

  const nome = String(user.name ?? "").trim() || `Aluno TotalPass ${cpf.slice(-4)}`;
  const emailRaw = String(user.email ?? "").trim().toLowerCase();
  const telefone = String(user.phone ?? user.phone_number ?? "").trim();

  const { data: byCpf } = await db
    .from("alunos")
    .select("id, email, nome, telefone, totalpass_cpf, beneficio_origem")
    .eq("totalpass_cpf", cpf)
    .maybeSingle();

  let existing = byCpf;
  if (!existing && emailRaw) {
    const { data: byEmail } = await db
      .from("alunos")
      .select("id, email, nome, telefone, totalpass_cpf, beneficio_origem")
      .eq("email", emailRaw)
      .maybeSingle();
    existing = byEmail;
  }

  if (existing) {
    const patch: Record<string, unknown> = { totalpass_cpf: cpf };
    const origem = String(existing.beneficio_origem ?? "").trim();
    if (!origem || origem === "totalpass") patch.beneficio_origem = "totalpass";
    if (!existing.nome) patch.nome = nome;
    if (telefone && !existing.telefone) patch.telefone = telefone;
    await db.from("alunos").update(patch).eq("id", existing.id);
    return { id: existing.id as number, created: false, cpf };
  }

  const vencimento = new Date();
  vencimento.setFullYear(vencimento.getFullYear() + 2);
  const insert: Record<string, unknown> = {
    nome,
    email: emailRaw || `totalpass.${cpf}@pulguinha.invalid`,
    senha: crypto.randomUUID(),
    telefone,
    plano: "TotalPass",
    vencimento: vencimento.toISOString().slice(0, 10),
    status: "Ativo",
    avatar: nome.split(" ").map((n) => n[0]).filter(Boolean).slice(0, 2).join("").toUpperCase() || "TP",
    totalpass_cpf: cpf,
    beneficio_origem: "totalpass",
  };

  const { data: created, error } = await db.from("alunos").insert(insert).select("id").single();
  if (error) {
    const msg = String(error.message).toLowerCase();
    if (msg.includes("email") || error.code === "23505") {
      insert.email = `totalpass.${cpf}@pulguinha.invalid`;
      const retry = await db.from("alunos").insert(insert).select("id").single();
      if (retry.error) {
        console.error("[totalpass] upsert aluno", retry.error.message);
        return null;
      }
      return { id: retry.data.id as number, created: true, cpf };
    }
    console.error("[totalpass] upsert aluno", error.message);
    return null;
  }
  return { id: created.id as number, created: true, cpf };
}

export function parseCheckinError(text: string) {
  try {
    const data = JSON.parse(text) as Record<string, unknown>;
    const errors = data.errors;
    if (Array.isArray(errors) && errors.length) {
      const first = errors[0] as Record<string, unknown>;
      const source = first.source;
      if (typeof source === "string" && source) return source;
      if (Array.isArray(source) && source.length) {
        const src = source[0] as Record<string, unknown>;
        if (typeof src.message === "string") return src.message;
      }
    }
    if (typeof data.message === "string" && data.message) return data.message;
    if (typeof data.error === "string" && data.error) return data.error;
  } catch {
    // corpo texto
  }
  if (text.includes("check_in_not_available")) return "check_in_not_available";
  if (text.includes("check_in_expired_alert")) return "check_in_expired_alert";
  return text.slice(0, 180);
}

/** POST no endpoint do payload. 200 com body "1" confirma. 422 = indisponível ou expirado. */
export async function confirmCheckinEndpoint(endpoint: string) {
  if (!isTotalpassUrl(endpoint)) {
    return { ok: false, status: 0, message: "endpoint fora de totalpass.com" };
  }
  let target = endpoint;
  let res = await fetch(target, {
    method: "POST",
    redirect: "manual",
    headers: { Accept: "text/plain, application/json" },
  });
  if (res.status >= 300 && res.status < 400) {
    const location = res.headers.get("location") ?? "";
    if (location && isTotalpassUrl(location)) {
      target = location;
      res = await fetch(target, {
        method: "POST",
        redirect: "manual",
        headers: { Accept: "text/plain, application/json" },
      });
    }
  }
  const text = await res.text();
  console.log(`[totalpass] POST confirm check-in ${redactUrl(target)} → HTTP ${res.status}`);
  if (res.status === 200) {
    return { ok: true, status: 200, message: text.trim().slice(0, 40) };
  }
  if (res.status === 422) {
    return { ok: false, status: 422, message: parseCheckinError(text) };
  }
  return { ok: false, status: res.status, message: text.slice(0, 180) };
}

export async function confirmBookingSlot(opts: {
  slotId: string;
  state: "confirmed" | "denied";
  reason?: string;
  placeApiKey?: string;
  sandbox?: boolean;
}) {
  const body: Record<string, unknown> = { state: opts.state };
  if (opts.reason) body.reason = opts.reason;
  return totalpassFetch("booking", `/partner/slot/confirmSlot/${encodeURIComponent(opts.slotId)}`, {
    method: "PUT",
    placeApiKey: opts.placeApiKey,
    sandbox: opts.sandbox,
    body: JSON.stringify(body),
  });
}
