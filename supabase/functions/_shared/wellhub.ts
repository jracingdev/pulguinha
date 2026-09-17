import { createClient, type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

export const TZ = "America/Sao_Paulo";
export const SLOT_STATUS_ACTIVE = 1;
export const SLOT_STATUS_INACTIVE = 0;

/** PATCH /booking/v1/.../bookings — docs oficiais: 2 reserved, 3 rejected, 5 cancelled by gym */
export const BOOKING_STATUS_V1 = {
  RESERVED: 2,
  REJECTED: 3,
  CANCELLED_BY_GYM: 5,
} as const;

/** PATCH /booking/v2/.../bookings */
export const BOOKING_STATUS_V2 = {
  RESERVED: "RESERVED",
  REJECTED: "REJECTED",
  CANCELLED_BY_GYM: "CANCELLED_BY_GYM",
} as const;

export type RejectCategory =
  | "CLASS_IS_FULL"
  | "USAGE_RESTRICTION"
  | "USER_IS_ALREADY_BOOKED"
  | "SPOT_NOT_AVAILABLE"
  | "USER_DOES_NOT_EXIST"
  | "CHECK_IN_AND_CANCELATION_WINDOWS_CLOSED"
  | "CLASS_HAS_BEEN_CANCELED"
  | "CLASS_NOT_FOUND"
  | "USER_PROFILE_CMS"
  | "PREREQUISITES"
  | "GENERAL_ERROR"
  | "TECHNICAL_ERROR";

export const TEST_USERS = [
  { gympass_id: "1000000000001", note: "Validate (coleção Postman / resposta 200)" },
  { gympass_id: "1000000000003", note: "Patty Cork — simulate check-in / booking cancel" },
] as const;

export const TEST_BOOKING_NUMBERS = ["BK_VLZNUIJ", "BK_JOMZ4JL", "BK_A1B2C3"] as const;

export function wellhubBase(sandbox: boolean) {
  return sandbox
    ? "https://apitesting.partners.gympass.com"
    : "https://api.partners.gympass.com";
}

let sandboxOverride: boolean | undefined;

/** Override por request (ex.: gym sandbox 683 sem mudar secrets de produção). */
export function setSandboxOverride(value: boolean | undefined) {
  sandboxOverride = value;
}

export function envSandbox() {
  if (sandboxOverride !== undefined) return sandboxOverride;
  return (Deno.env.get("WELLHUB_SANDBOX") ?? "false").toLowerCase() === "true";
}

export function envGymId() {
  return (Deno.env.get("WELLHUB_GYM_ID") ?? "").trim();
}

/** gym_id do payload do webhook, se for um id real; senão o da unidade no secret. */
export function resolveGymId(...candidates: unknown[]) {
  for (const raw of candidates) {
    if (raw == null || raw === "") continue;
    const s = String(raw).trim();
    if (!s || s === "0" || s === "undefined" || s === "null") continue;
    return s;
  }
  return envGymId();
}

export function envToken() {
  return (Deno.env.get("WELLHUB_BEARER_TOKEN") ?? "").trim();
}

export function envProductId() {
  const raw = (Deno.env.get("WELLHUB_PRODUCT_ID") ?? "").trim();
  if (!raw) return null;
  const n = Number(raw);
  return Number.isFinite(n) ? n : null;
}

export function envWebhookSecret() {
  return (Deno.env.get("WELLHUB_WEBHOOK_SECRET") ?? "").trim();
}

export function serviceClient(): SupabaseClient {
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  return createClient(url, key, { auth: { persistSession: false } });
}

export function onlyDigits(value: string) {
  return value.replace(/\D/g, "");
}

export function normalizeGympassId(value: string) {
  const digits = onlyDigits(value).padStart(13, "0");
  return digits.slice(-13);
}

export function saoPauloDateISO(d = new Date()): string {
  const fmt = new Intl.DateTimeFormat("en-CA", {
    timeZone: TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });
  return fmt.format(d);
}

export function padHora(hora: string) {
  const m = hora.trim().match(/^(\d{1,2})\s*[:hH]\s*(\d{0,2})/);
  if (!m) {
    const n = parseInt(hora.replace(/\D/g, ""), 10);
    if (Number.isFinite(n)) return `${String(n).padStart(2, "0")}:00`;
    return "00:00";
  }
  const h = String(Math.min(23, parseInt(m[1], 10))).padStart(2, "0");
  const min = String(Math.min(59, parseInt(m[2] || "0", 10))).padStart(2, "0");
  return `${h}:${min}`;
}

/** `YYYY-MM-DDTHH:mm:ss-03:00` (Brasil sem DST desde 2019). */
export function occurDateIso(dataIso: string, hora: string) {
  return `${dataIso}T${padHora(hora)}:00-03:00`;
}

export function shiftIso(iso: string, ms: number) {
  const t = Date.parse(iso);
  const d = new Date(t + ms);
  return formatOffsetMinus3(d, iso.includes("-03:00") ? -3 : undefined);
}

function formatOffsetMinus3(d: Date, _hint?: number) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  }).formatToParts(d);
  const get = (t: string) => parts.find((p) => p.type === t)?.value ?? "00";
  return `${get("year")}-${get("month")}-${get("day")}T${get("hour")}:${get("minute")}:${get("second")}-03:00`;
}

export function bookingWindowFor(occurIso: string) {
  const t = Date.parse(occurIso);
  const opens = formatOffsetMinus3(new Date(t - 24 * 60 * 60 * 1000));
  const closes = formatOffsetMinus3(new Date(t - 60 * 60 * 1000));
  return { opens_at: opens, closes_at: closes, cancellable_until: closes };
}

export function semAcento(s: string) {
  return s.normalize("NFD").replace(/\p{M}/gu, "").toLowerCase();
}

export function weekdaysFromDias(raw: string): Set<number> {
  const t = semAcento(raw.trim());
  if (!t || t.includes("todos") || t === "diario" || t === "diariamente") {
    return new Set([1, 2, 3, 4, 5, 6, 7]);
  }
  if (/seg(?:unda)?\s*a\s*sex(?:ta)?/.test(t) || /seg(?:unda)?\s*[-–]\s*sex(?:ta)?/.test(t) || t.includes("uteis")) {
    return new Set([1, 2, 3, 4, 5]);
  }
  const out = new Set<number>();
  for (const part of t.split(/[/|,;]+|\se\s+/)) {
    const p = part.trim();
    if (p.startsWith("seg") || p === "mon") out.add(1);
    else if (p.startsWith("ter") || p === "tue") out.add(2);
    else if (p.startsWith("qua") || p === "wed") out.add(3);
    else if (p.startsWith("qui") || p === "thu") out.add(4);
    else if (p.startsWith("sex") || p === "fri") out.add(5);
    else if (p.startsWith("sab") || p === "sat") out.add(6);
    else if (p.startsWith("dom") || p === "sun") out.add(7);
  }
  return out;
}

export function weekdayIso(dataIso: string): number {
  const [y, m, d] = dataIso.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, d, 12)).getUTCDay() === 0
    ? 7
    : new Date(Date.UTC(y, m - 1, d, 12)).getUTCDay();
}

export function nextDays(n: number, from = new Date()): string[] {
  const start = saoPauloDateISO(from);
  const [y, mo, d] = start.split("-").map(Number);
  const out: string[] = [];
  for (let i = 0; i < n; i++) {
    const dt = new Date(Date.UTC(y, mo - 1, d + i, 12));
    out.push(dt.toISOString().slice(0, 10));
  }
  return out;
}

export async function hmacSha1HexUpper(secret: string, body: string) {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-1" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(body));
  return [...new Uint8Array(sig)].map((b) => b.toString(16).padStart(2, "0")).join("").toUpperCase();
}

export function timingSafeEqual(a: string, b: string) {
  const aa = a.toUpperCase().replace(/^0X/, "");
  const bb = b.toUpperCase().replace(/^0X/, "");
  if (aa.length !== bb.length) return false;
  let diff = 0;
  for (let i = 0; i < aa.length; i++) diff |= aa.charCodeAt(i) ^ bb.charCodeAt(i);
  return diff === 0;
}

export async function verifySignature(rawBody: string, header: string | null) {
  const secret = envWebhookSecret();
  if (!secret) {
    console.warn("[wellhub] WELLHUB_WEBHOOK_SECRET vazio — assinatura não verificada");
    return true;
  }
  if (!header) return false;
  const expected = await hmacSha1HexUpper(secret, rawBody);
  return timingSafeEqual(expected, header.trim());
}

export async function wellhubFetch(
  path: string,
  init: RequestInit & { gymId?: string; sandbox?: boolean } = {},
) {
  const token = envToken();
  const gymId = init.gymId ?? envGymId();
  const sandbox =
    init.sandbox ??
    (gymId === "683" || /(^|\/)gyms\/683(\/|$)/.test(path) ? true : envSandbox());
  const headers = new Headers(init.headers);
  headers.set("Authorization", `Bearer ${token}`);
  headers.set("Accept", "application/json");
  if (init.body && !headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }
  const url = `${wellhubBase(sandbox)}${path.startsWith("/") ? path : `/${path}`}`;
  const method = (init.method ?? "GET").toUpperCase();
  const res = await fetch(url, { ...init, headers });
  const text = await res.text();
  let json: unknown = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    json = text;
  }
  if (method !== "GET") {
    console.log(`[wellhub] ${method} ${path} gym=${gymId} sandbox=${sandbox} → HTTP ${res.status}`);
  }
  return { ok: res.ok, status: res.status, json, text, gymId, sandbox, path };
}

export async function validateAccess(gympassId: string) {
  return wellhubFetch("/access/v1/validate", {
    method: "POST",
    headers: { "X-Gym-Id": envGymId() },
    body: JSON.stringify({ gympass_id: gympassId }),
  });
}

export async function patchBookingV1(
  gymId: string,
  bookingNumber: string,
  classId: number,
  status: number,
  reason?: string,
) {
  const body: Record<string, unknown> = { class_id: classId, status };
  if (reason) body.reason = reason;
  return wellhubFetch(`/booking/v1/gyms/${gymId}/bookings/${encodeURIComponent(bookingNumber)}`, {
    method: "PATCH",
    gymId,
    body: JSON.stringify(body),
  });
}

export async function patchBookingV2(
  gymId: string,
  bookingNumber: string,
  status: string,
  reason?: string,
  reasonCategory?: RejectCategory,
) {
  const body: Record<string, unknown> = { status };
  if (reason) body.reason = reason;
  if (reasonCategory) body.reason_category = reasonCategory;
  return wellhubFetch(`/booking/v2/gyms/${gymId}/bookings/${encodeURIComponent(bookingNumber)}`, {
    method: "PATCH",
    gymId,
    body: JSON.stringify(body),
  });
}

/** Sempre chama PATCH (15 min). Tenta v1 (class_id + status numérico) e cai para v2. */
export async function patchBookingAlways(opts: {
  gymId: string;
  bookingNumber: string;
  classId: number;
  accept: boolean;
  reason?: string;
  reasonCategory?: RejectCategory;
  cancelledByGym?: boolean;
}) {
  const v1Status = opts.cancelledByGym
    ? BOOKING_STATUS_V1.CANCELLED_BY_GYM
    : opts.accept
    ? BOOKING_STATUS_V1.RESERVED
    : BOOKING_STATUS_V1.REJECTED;
  const v1 = await patchBookingV1(opts.gymId, opts.bookingNumber, opts.classId, v1Status, opts.reason);
  console.log(
    `[wellhub] PATCH booking/v1 gym=${opts.gymId} booking=${opts.bookingNumber} class_id=${opts.classId} status=${v1Status} → HTTP ${v1.status}`,
  );
  if (v1.ok || v1.status === 204) {
    return { ...v1, version: "v1" as const };
  }
  console.warn(`[wellhub] PATCH booking/v1 falhou: ${String(v1.text).slice(0, 300)}`);
  const v2Status = opts.cancelledByGym
    ? BOOKING_STATUS_V2.CANCELLED_BY_GYM
    : opts.accept
    ? BOOKING_STATUS_V2.RESERVED
    : BOOKING_STATUS_V2.REJECTED;
  const v2 = await patchBookingV2(
    opts.gymId,
    opts.bookingNumber,
    v2Status,
    opts.reason,
    opts.accept ? undefined : (opts.reasonCategory ?? "GENERAL_ERROR"),
  );
  console.log(
    `[wellhub] PATCH booking/v2 gym=${opts.gymId} booking=${opts.bookingNumber} status=${v2Status} → HTTP ${v2.status}`,
  );
  if (!(v2.ok || v2.status === 204)) {
    console.warn(`[wellhub] PATCH booking/v2 falhou: ${String(v2.text).slice(0, 300)}`);
  }
  return { ...v2, version: "v2" as const, v1 };
}

export async function patchSlotOccupancy(
  gymId: string,
  classId: number,
  slotId: number,
  totalBooked: number,
  totalCapacity: number,
) {
  const booked = Math.max(0, Math.min(32000, Math.floor(totalBooked)));
  const capacity = Math.max(booked, Math.min(32000, Math.floor(totalCapacity)));
  const res = await wellhubFetch(
    `/booking/v1/gyms/${gymId}/classes/${classId}/slots/${slotId}`,
    {
      method: "PATCH",
      gymId,
      body: JSON.stringify({
        total_booked: booked,
        total_capacity: capacity,
      }),
    },
  );
  const ok = res.ok || res.status === 204;
  console.log(
    `[wellhub] PATCH occupancy gym=${gymId} class=${classId} slot=${slotId} total_booked=${booked} total_capacity=${capacity} → HTTP ${res.status}${ok ? "" : ` ${String(res.text).slice(0, 300)}`}`,
  );
  return { ...res, ok, booked, capacity };
}

export async function listProducts(gymId: string) {
  return wellhubFetch(`/setup/v1/gyms/${gymId}/products`);
}

export async function listCategories(gymId: string, locale = "pt-BR") {
  return wellhubFetch(`/booking/v1/gyms/${gymId}/categories?locale=${encodeURIComponent(locale)}`);
}

export async function listClasses(gymId: string) {
  return wellhubFetch(`/booking/v1/gyms/${gymId}/classes`);
}

export async function createClasses(gymId: string, classes: unknown[]) {
  return wellhubFetch(`/booking/v1/gyms/${gymId}/classes`, {
    method: "POST",
    body: JSON.stringify({ classes }),
  });
}

export async function putClass(gymId: string, classId: number, payload: Record<string, unknown>) {
  return wellhubFetch(`/booking/v1/gyms/${gymId}/classes/${classId}`, {
    method: "PUT",
    body: JSON.stringify(payload),
  });
}

export async function createSlot(gymId: string, classId: number, payload: Record<string, unknown>) {
  return wellhubFetch(`/booking/v1/gyms/${gymId}/classes/${classId}/slots`, {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export async function putSlot(
  gymId: string,
  classId: number,
  slotId: number,
  payload: Record<string, unknown>,
) {
  return wellhubFetch(`/booking/v1/gyms/${gymId}/classes/${classId}/slots/${slotId}`, {
    method: "PUT",
    body: JSON.stringify(payload),
  });
}

export async function listSlots(gymId: string, classId: number, fromIso: string, toIso: string) {
  const qs = `from=${encodeURIComponent(fromIso)}&to=${encodeURIComponent(toIso)}`;
  return wellhubFetch(`/booking/v1/gyms/${gymId}/classes/${classId}/slots?${qs}`);
}

export async function getSlot(gymId: string, classId: number, slotId: number) {
  return wellhubFetch(`/booking/v1/gyms/${gymId}/classes/${classId}/slots/${slotId}`, { gymId });
}

export async function alreadyCheckedInToday(db: SupabaseClient, gympassId: string) {
  const day = saoPauloDateISO();
  const { data } = await db
    .from("wellhub_daily_checkins")
    .select("id")
    .eq("gympass_id", gympassId)
    .eq("checkin_date", day)
    .maybeSingle();
  return !!data;
}

export async function markCheckedInToday(
  db: SupabaseClient,
  gympassId: string,
  source: string,
  extra?: { booking_number?: string; product_id?: number },
) {
  const day = saoPauloDateISO();
  const { error } = await db.from("wellhub_daily_checkins").upsert(
    {
      gympass_id: gympassId,
      checkin_date: day,
      source,
      booking_number: extra?.booking_number ?? null,
      product_id: extra?.product_id ?? null,
      validated_at: new Date().toISOString(),
    },
    { onConflict: "gympass_id,checkin_date" },
  );
  if (error) console.error("[wellhub] markCheckedInToday", error.message);
}

export async function countBooked(db: SupabaseClient, horarioId: number, data: string) {
  const { count, error } = await db
    .from("agendamentos")
    .select("id", { count: "exact", head: true })
    .eq("horario_id", horarioId)
    .eq("data", data)
    .ilike("status", "confirmado");
  if (error) {
    console.error("[wellhub] countBooked", error.message);
    return 0;
  }
  return count ?? 0;
}

export type OccupancySyncOpts = {
  gymId?: string;
  horarioId?: number;
  data?: string;
  classId?: number;
  slotId?: number;
  /** Sem mapa local: aplica sobre total_booked remoto (+1 requested, -1 canceled). */
  delta?: number;
};

export type OccupancySyncResult = {
  ok: boolean;
  status?: number;
  booked?: number;
  capacity?: number;
  classId?: number;
  slotId?: number;
  gymId?: string;
  message?: string;
  skipped?: boolean;
};

function asSlotRecord(json: unknown): Record<string, unknown> | null {
  if (!json || typeof json !== "object") return null;
  const obj = json as Record<string, unknown>;
  if (obj.total_booked != null || obj.total_capacity != null || obj.id != null) return obj;
  const nested = obj.slot;
  if (nested && typeof nested === "object") return nested as Record<string, unknown>;
  return obj;
}

export async function syncOccupancyFor(
  db: SupabaseClient,
  horarioIdOrOpts: number | OccupancySyncOpts,
  data?: string,
  gymIdArg?: string,
): Promise<OccupancySyncResult> {
  const opts: OccupancySyncOpts = typeof horarioIdOrOpts === "object"
    ? horarioIdOrOpts
    : { horarioId: horarioIdOrOpts, data, gymId: gymIdArg };

  const gymId = resolveGymId(opts.gymId, gymIdArg);
  let classId = Number(opts.classId ?? 0) || 0;
  let slotId = Number(opts.slotId ?? 0) || 0;
  let horarioId = Number(opts.horarioId ?? 0) || 0;
  let day = String(opts.data ?? "").slice(0, 10);
  let capacity = 12;

  if (horarioId && day) {
    const { data: mapped } = await db
      .from("wellhub_slots")
      .select("wellhub_slot_id, wellhub_class_id, total_capacity, horario_id, data")
      .eq("horario_id", horarioId)
      .eq("data", day)
      .maybeSingle();
    if (mapped) {
      classId = classId || Number(mapped.wellhub_class_id);
      slotId = slotId || Number(mapped.wellhub_slot_id);
      capacity = Number(mapped.total_capacity ?? capacity) || capacity;
    }
  }

  if ((!classId || !slotId) && slotId) {
    const { data: bySlot } = await db
      .from("wellhub_slots")
      .select("wellhub_slot_id, wellhub_class_id, total_capacity, horario_id, data")
      .eq("wellhub_slot_id", slotId)
      .maybeSingle();
    if (bySlot) {
      classId = classId || Number(bySlot.wellhub_class_id);
      horarioId = horarioId || Number(bySlot.horario_id);
      day = day || String(bySlot.data ?? "").slice(0, 10);
      capacity = Number(bySlot.total_capacity ?? capacity) || capacity;
    }
  }

  if ((!classId || !slotId) && classId && day) {
    const { data: byClass } = await db
      .from("wellhub_slots")
      .select("wellhub_slot_id, wellhub_class_id, total_capacity, horario_id, data")
      .eq("wellhub_class_id", classId)
      .eq("data", day)
      .maybeSingle();
    if (byClass) {
      slotId = slotId || Number(byClass.wellhub_slot_id);
      horarioId = horarioId || Number(byClass.horario_id);
      capacity = Number(byClass.total_capacity ?? capacity) || capacity;
    }
  }

  if (!classId || !slotId) {
    console.warn(
      `[wellhub] occupancy SKIP sem class_id/slot_id gym=${gymId} class=${classId} slot=${slotId} horario=${horarioId} data=${day}`,
    );
    return { ok: false, skipped: true, message: "slot não mapeado", gymId, classId, slotId };
  }

  const remote = await getSlot(gymId, classId, slotId);
  const remoteSlot = asSlotRecord(remote.json);
  const remoteBooked = Number(remoteSlot?.total_booked ?? 0);
  const remoteCap = Number(remoteSlot?.total_capacity ?? 0);
  if (remoteCap > 0) capacity = remoteCap;

  let booked: number;
  if (horarioId && day) {
    booked = await countBooked(db, horarioId, day);
  } else {
    const delta = Number(opts.delta ?? 0);
    booked = Math.max(0, remoteBooked + delta);
  }
  booked = Math.max(0, Math.min(capacity, booked));

  const res = await patchSlotOccupancy(gymId, classId, slotId, booked, capacity);

  await db
    .from("wellhub_slots")
    .update({ total_booked: booked, synced_at: new Date().toISOString() })
    .eq("wellhub_slot_id", slotId);

  return {
    ok: res.ok || res.status === 204,
    status: res.status,
    booked,
    capacity,
    classId,
    slotId,
    gymId,
    message: res.ok || res.status === 204 ? undefined : String(res.text).slice(0, 300),
  };
}

export async function upsertAlunoFromWellhub(
  db: SupabaseClient,
  user: {
    unique_token?: string;
    first_name?: string;
    last_name?: string;
    name?: string;
    email?: string;
    phone_number?: string;
  },
) {
  const gympassId = normalizeGympassId(user.unique_token ?? "");
  if (gympassId.length !== 13) return null;

  const { data: existing } = await db
    .from("alunos")
    .select("id, email, nome, telefone, wellhub_id, beneficio_origem")
    .eq("wellhub_id", gympassId)
    .maybeSingle();

  const nome =
    (user.name ?? `${user.first_name ?? ""} ${user.last_name ?? ""}`.trim()) ||
    `Aluno Wellhub ${gympassId.slice(-4)}`;
  const email = (user.email ?? "").trim().toLowerCase() || `wellhub.${gympassId}@pulguinha.invalid`;
  const telefone = (user.phone_number ?? "").trim();

  if (existing) {
    const patch: Record<string, unknown> = {
      beneficio_origem: "wellhub",
      wellhub_id: gympassId,
    };
    if (!existing.nome) patch.nome = nome;
    if (telefone && !existing.telefone) patch.telefone = telefone;
    await db.from("alunos").update(patch).eq("id", existing.id);
    return { id: existing.id as number, created: false, gympassId };
  }

  const vencimento = new Date();
  vencimento.setFullYear(vencimento.getFullYear() + 2);
  const insert = {
    nome,
    email,
    senha: crypto.randomUUID(),
    telefone,
    plano: "Wellhub",
    vencimento: vencimento.toISOString().slice(0, 10),
    status: "Ativo",
    avatar: nome.split(" ").map((n) => n[0]).slice(0, 2).join("").toUpperCase(),
    wellhub_id: gympassId,
    beneficio_origem: "wellhub",
  };

  const { data: created, error } = await db.from("alunos").insert(insert).select("id").single();
  if (error) {
    if (String(error.message).toLowerCase().includes("email") || error.code === "23505") {
      insert.email = `wellhub.${gympassId}@pulguinha.invalid`;
      const retry = await db.from("alunos").insert(insert).select("id").single();
      if (retry.error) {
        console.error("[wellhub] upsert aluno", retry.error.message);
        return null;
      }
      return { id: retry.data.id as number, created: true, gympassId };
    }
    console.error("[wellhub] upsert aluno", error.message);
    return null;
  }
  return { id: created.id as number, created: true, gympassId };
}

export function extractEvent(payload: Record<string, unknown>) {
  const raw = String(payload.event_type ?? payload.event ?? "").trim();
  const eventType = raw.replace(/\./g, "-");
  const eventData = (payload.event_data ?? payload) as Record<string, unknown>;
  const eventId = String(eventData.event_id ?? payload.event_id ?? "").trim();
  return { eventType, eventData, eventId };
}

export function slotFromEvent(eventData: Record<string, unknown>) {
  const slot = (eventData.slot ?? {}) as Record<string, unknown>;
  const gym = (eventData.gym ?? {}) as Record<string, unknown>;
  const booking = (eventData.booking ?? {}) as Record<string, unknown>;
  return {
    id: Number(slot.id ?? eventData.slot_id ?? 0) || 0,
    gym_id: resolveGymId(slot.gym_id, gym.id, eventData.gym_id),
    class_id: Number(slot.class_id ?? eventData.class_id ?? 0) || 0,
    booking_number: String(
      slot.booking_number ?? booking.booking_number ?? eventData.booking_number ?? "",
    ).trim(),
  };
}

export function userFromEvent(eventData: Record<string, unknown>) {
  return (eventData.user ?? {}) as {
    unique_token?: string;
    first_name?: string;
    last_name?: string;
    name?: string;
    email?: string;
    phone_number?: string;
  };
}

declare const EdgeRuntime: { waitUntil(p: Promise<unknown>): void } | undefined;

export function background(p: Promise<unknown>) {
  if (typeof EdgeRuntime !== "undefined" && EdgeRuntime?.waitUntil) {
    EdgeRuntime.waitUntil(p);
    return;
  }
  p.catch((err) => console.error("[wellhub] background", err));
}
