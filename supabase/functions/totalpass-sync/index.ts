import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  nextDays,
  padHora,
  weekdaysFromDias,
} from "../_shared/wellhub.ts";
import {
  asArray,
  envPlaceKey,
  envSandbox,
  extractAuthenticatedPlace,
  extractPlans,
  serviceClient,
  setTotalpassSandboxOverride,
  totalpassFetch,
  type TotalpassPlan,
} from "../_shared/totalpass.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const DURATION = Number(Deno.env.get("TOTALPASS_CLASS_DURATION_MINUTES") ?? "60") || 60;
const HORIZON_DAYS = Number(Deno.env.get("TOTALPASS_EVENT_HORIZON_DAYS") ?? "14") || 14;
const RESPONSIBLE = "Funcional do Pulguinha";
const DEFAULT_PLAN_CODE = "2IK805HV";

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function placeFrom(body: Record<string, unknown>) {
  const fromBody = String(body.totalpass_place_api_key ?? "").trim();
  return fromBody || envPlaceKey();
}

function webhookUrl() {
  const base = (Deno.env.get("SUPABASE_URL") ?? "").replace(/\/$/, "");
  return `${base}/functions/v1/totalpass-webhook`;
}

/** TotalPass weekday: 0 = domingo … 6 = sábado. */
function tpWeekday(isoWeekday: number) {
  return isoWeekday % 7;
}

function toAmPm(hora: string) {
  const [hStr, mStr] = padHora(hora).split(":");
  let h = Number(hStr);
  const suffix = h >= 12 ? "PM" : "AM";
  h = h % 12;
  if (h === 0) h = 12;
  return `${String(h).padStart(2, "0")}:${mStr} ${suffix}`;
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const body = req.method === "GET"
      ? { action: "meta" }
      : ((await req.json().catch(() => ({}))) as Record<string, unknown>);
    const action = String(body.action ?? "sync_schedule");
    if (typeof body.totalpass_sandbox === "boolean") {
      setTotalpassSandboxOverride(body.totalpass_sandbox);
    }
    const placeApiKey = placeFrom(body);
    const sandbox = typeof body.totalpass_sandbox === "boolean" ? body.totalpass_sandbox : envSandbox();
    if (action === "meta") return jsonResponse(await meta(placeApiKey, sandbox));
    if (action === "sync_schedule" || action === "full_sync") {
      return jsonResponse(await syncSchedule(placeApiKey, sandbox, body));
    }
    return jsonResponse({ ok: false, message: "action inválida" }, 400);
  } catch (error) {
    return jsonResponse({ ok: false, message: String(error) }, 500);
  }
});

async function meta(placeApiKey: string, sandbox: boolean) {
  const plans = await totalpassFetch("booking", "/partner/plans", { placeApiKey, sandbox });
  const hook = await totalpassFetch("booking", "/partner/webhook", { placeApiKey, sandbox });
  const events = await totalpassFetch("booking", "/partner/events", { placeApiKey, sandbox });
  const checkinHook = await totalpassFetch("checkin", "/partner/webhook/get", { placeApiKey, sandbox });
  const planList = extractPlans(plans.json);
  return {
    ok: plans.ok,
    sandbox,
    webhook_url: webhookUrl(),
    plans: planList.map((p) => ({ id: p.id, code: p.code, name: p.name })),
    plans_status: plans.status,
    booking_webhook_status: hook.status,
    booking_webhook_set: Boolean(asRecordUrl(hook.json)),
    events_status: events.status,
    events_count: asArray(events.json, ["events"]).length,
    checkin_webhook_status: checkinHook.status,
    checkin_webhook_count: asArray(checkinHook.json, ["webhooks", "data"]).length,
  };
}

function asRecordUrl(payload: unknown) {
  if (!payload || typeof payload !== "object") return "";
  return String((payload as Record<string, unknown>).placeWebhookUrl ?? "");
}

function pickPlan(plans: TotalpassPlan[], preferredCode: string, preferredId: number) {
  if (preferredId && plans.some((p) => p.id === preferredId)) {
    return plans.find((p) => p.id === preferredId) ?? null;
  }
  const code = preferredCode.trim().toUpperCase();
  const byCode = plans.find((p) => p.code.toUpperCase() === code);
  if (byCode) return byCode;
  return plans[0] ?? null;
}

function frequencyFor(dias: string, hora: string) {
  const days = weekdaysFromDias(dias);
  const use = days.size ? days : new Set([1, 2, 3, 4, 5, 6, 7]);
  const startAmPm = toAmPm(hora);
  const start24 = padHora(hora);
  const options = [...use].sort().map((iso) => ({
    weekday: tpWeekday(iso),
    startTime: [startAmPm],
  }));
  const options24 = [...use].sort().map((iso) => ({
    weekday: tpWeekday(iso),
    startTime: [start24],
  }));
  return { options, options24 };
}

function errorText(json: unknown, text: string) {
  if (json && typeof json === "object") return JSON.stringify(json);
  return text;
}

async function syncSchedule(
  placeApiKey: string,
  sandbox: boolean,
  body: Record<string, unknown>,
) {
  const db = serviceClient();
  const logs: string[] = [];
  const titles: string[] = [];

  const plansRes = await totalpassFetch("booking", "/partner/plans", { placeApiKey, sandbox });
  const authenticated = extractAuthenticatedPlace(plansRes.json);
  const expectedId = Number(body.totalpass_place_id ?? Deno.env.get("TOTALPASS_PLACE_ID") ?? "203438") || 203438;
  const expectedName = String(Deno.env.get("TOTALPASS_UNIT_NAME") ?? "FUNCIONAL DO PULGUINHA");
  if (!authenticated.placeId || authenticated.placeId !== expectedId) {
    logs.push(
      `unidade autenticada placeId=${authenticated.placeId ?? "?"} nome=${authenticated.name.trim() || "?"} · esperada ${expectedId} ${expectedName}`,
    );
    return {
      ok: false,
      skipped: true,
      message:
        `A place_api_key autenticada é da unidade "${authenticated.name.trim() || "desconhecida"}" (placeId ${authenticated.placeId ?? "?"}). ` +
        `A unidade real é ${expectedName}, placeId ${expectedId}. ` +
        "Falta a place_api_key (UUID) gerada no portal de parceiros dessa unidade. A grade não foi publicada na unidade de teste.",
      authenticated_place_id: authenticated.placeId,
      authenticated_place_name: authenticated.name.trim(),
      expected_place_id: expectedId,
      expected_place_name: expectedName,
      plans_status: plansRes.status,
      logs,
    };
  }

  const hooks = await ensureWebhooks(placeApiKey, sandbox, logs);
  const plans = extractPlans(plansRes.json);
  const preferredCode = String(body.totalpass_plan_code ?? Deno.env.get("TOTALPASS_PLAN_CODE") ?? DEFAULT_PLAN_CODE);
  const preferredId = Number(body.totalpass_plan_id ?? Deno.env.get("TOTALPASS_PLAN_ID") ?? 0) || 0;
  const plan = pickPlan(plans, preferredCode, preferredId);
  if (!plan) {
    return {
      ok: false,
      message: "Nenhum plano na Booking API. Confira GET /partner/plans.",
      plans_status: plansRes.status,
      logs,
      ...hooks,
    };
  }
  logs.push(`plano id=${plan.id} code=${plan.code} name=${plan.name}`);

  const days = nextDays(HORIZON_DAYS);
  const startDate = days[0];
  const endDate = days[days.length - 1];

  const { data: horarios, error: horErr } = await db
    .from("horarios")
    .select("id, hora, dias, capacidade")
    .order("id");
  if (horErr) return { ok: false, message: horErr.message, logs };

  const remoteRes = await totalpassFetch("booking", "/partner/events", { placeApiKey, sandbox });
  const remote = asArray(remoteRes.json, ["events"]);
  logs.push(`eventos remotos status=${remoteRes.status} n=${remote.length}`);
  const byRef = new Map<string, Record<string, unknown>>();
  for (const ev of remote) {
    const ref = String(ev.externalReference ?? ev.external_reference ?? "");
    const desc = String(ev.description ?? "");
    const fromDesc = desc.match(/horario:(\d+|teste)/);
    const key = ref || (fromDesc ? `horario:${fromDesc[1]}` : "");
    if (key) byRef.set(key, ev);
  }

  const rows = horarios ?? [];
  const specs = rows.length
    ? rows.map((h) => ({
      horarioId: Number(h.id),
      reference: `horario:${h.id}`,
      title: `Pulguinha ${padHora(String(h.hora))}`,
      description: `horario:${h.id} · ${h.dias} · Funcional do Pulguinha`,
      hora: String(h.hora),
      dias: String(h.dias ?? ""),
      slots: Math.max(1, Number(h.capacidade ?? 12) || 12),
    }))
    : [{
      horarioId: null as number | null,
      reference: "horario:teste",
      title: "Pulguinha — aula teste",
      description: "horario:teste · grade ainda vazia · Funcional do Pulguinha",
      hora: "07:00",
      dias: "Seg a Sex",
      slots: 12,
    }];

  if (!rows.length) logs.push("sem horários locais — publicando 1 evento de teste (seg–sex 07:00)");

  let created = 0;
  let updated = 0;
  for (const spec of specs) {
    const freq = frequencyFor(spec.dias, spec.hora);
    const existing = byRef.get(spec.reference);
    const remoteSlots = Number(existing?.slots ?? 0) || 0;
    const slots = Math.max(spec.slots, remoteSlots, 1);
    const payload: Record<string, unknown> = {
      title: spec.title,
      responsible: RESPONSIBLE,
      duration: DURATION,
      slots,
      timezone: "pt-BR",
      startDate,
      endDate,
      planId: plan.id,
      status: "ACTIVE",
      description: spec.description,
      externalReference: spec.reference,
      frequencyOptions: freq.options,
    };

    let eventId = Number(existing?.id ?? 0) || 0;
    if (eventId) {
      const put = await putEvent(eventId, payload, freq.options24, placeApiKey, sandbox);
      logs.push(`PUT event ${eventId} (${spec.reference}) → ${put.status}`);
      if (put.ok) updated++;
      else {
        logs.push(`PUT event ${eventId} falhou: ${errorText(put.json, put.text).slice(0, 280)}`);
        eventId = 0;
      }
    }
    if (!eventId) {
      const post = await postEvent(payload, freq.options24, placeApiKey, sandbox);
      const bodyJson = post.json && typeof post.json === "object" ? post.json as Record<string, unknown> : {};
      eventId = Number(bodyJson.id ?? 0) || 0;
      logs.push(`POST event (${spec.reference}) → ${post.status} id=${eventId || "?"}`);
      if (!eventId) {
        logs.push(`falha criar: ${errorText(post.json, post.text).slice(0, 280)}`);
        continue;
      }
      created++;
    }

    titles.push(spec.title);
    await db.from("totalpass_events").upsert({
      horario_id: spec.horarioId,
      totalpass_event_id: eventId,
      external_reference: spec.reference,
      title: spec.title,
      plan_id: plan.id,
      slots,
      synced_at: new Date().toISOString(),
    }, { onConflict: "external_reference" });
  }

  const listed = await totalpassFetch("booking", "/partner/events", { placeApiKey, sandbox });
  const list = asArray(listed.json, ["events"]);
  return {
    ok: created + updated > 0 || list.length > 0,
    sandbox,
    plan: { id: plan.id, code: plan.code, name: plan.name },
    events_created: created,
    events_updated: updated,
    events_remote: list.length,
    titles,
    horizon_days: HORIZON_DAYS,
    start_date: startDate,
    end_date: endDate,
    webhook_url: webhookUrl(),
    ...hooks,
    logs,
  };
}

async function postEvent(
  payload: Record<string, unknown>,
  options24: unknown,
  placeApiKey: string,
  sandbox: boolean,
) {
  let res = await totalpassFetch("booking", "/partner/events", {
    method: "POST",
    placeApiKey,
    sandbox,
    body: JSON.stringify(payload),
  });
  if (res.status === 400) {
    const msg = errorText(res.json, res.text);
    const next = { ...payload };
    let changed = false;
    if (/externalReference/i.test(msg) && /should not exist|not allowed/i.test(msg)) {
      delete next.externalReference;
      changed = true;
    }
    if (/startTime/i.test(msg)) {
      next.frequencyOptions = options24;
      changed = true;
    }
    if (changed) {
      res = await totalpassFetch("booking", "/partner/events", {
        method: "POST",
        placeApiKey,
        sandbox,
        body: JSON.stringify(next),
      });
    }
  }
  return res;
}

async function putEvent(
  eventId: number,
  payload: Record<string, unknown>,
  options24: unknown,
  placeApiKey: string,
  sandbox: boolean,
) {
  let res = await totalpassFetch("booking", `/partner/events/${eventId}`, {
    method: "PUT",
    placeApiKey,
    sandbox,
    body: JSON.stringify(payload),
  });
  if (res.status === 400) {
    const msg = errorText(res.json, res.text);
    if (/should not exist|not allowed/i.test(msg) || /startTime/i.test(msg)) {
      const minimal: Record<string, unknown> = {
        title: payload.title,
        responsible: payload.responsible,
        duration: payload.duration,
        slots: payload.slots,
        description: payload.description,
      };
      if (/startTime/i.test(msg)) {
        minimal.frequencyOptions = options24;
        minimal.timezone = payload.timezone;
        minimal.startDate = payload.startDate;
        minimal.endDate = payload.endDate;
        minimal.planId = payload.planId;
        minimal.status = payload.status;
      }
      res = await totalpassFetch("booking", `/partner/events/${eventId}`, {
        method: "PUT",
        placeApiKey,
        sandbox,
        body: JSON.stringify(/should not exist/i.test(msg) ? {
          title: payload.title,
          responsible: payload.responsible,
          duration: payload.duration,
          slots: payload.slots,
          description: payload.description,
        } : minimal),
      });
    }
  }
  return res;
}

async function ensureWebhooks(placeApiKey: string, sandbox: boolean, logs: string[]) {
  const url = webhookUrl();
  const booking = await totalpassFetch("booking", "/partner/webhook", { placeApiKey, sandbox });
  const current = asRecordUrl(booking.json);
  let bookingStatus = booking.status;
  if (current === url) {
    logs.push("webhook booking já aponta para a function");
  } else {
    const sub = await totalpassFetch("booking", "/partner/webhook/subscribe", {
      method: "POST",
      placeApiKey,
      sandbox,
      body: JSON.stringify({ webhook_url: url }),
    });
    bookingStatus = sub.status;
    logs.push(`POST /partner/webhook/subscribe → ${sub.status}`);
    if (!(sub.ok || sub.status === 200 || sub.status === 201)) {
      logs.push(errorText(sub.json, sub.text).slice(0, 240));
    }
  }

  const list = await totalpassFetch("checkin", "/partner/webhook/get", { placeApiKey, sandbox });
  const hooks = asArray(list.json, ["webhooks", "data"]);
  const has = hooks.some((h) => {
    const hookUrl = String(h.webhook_url ?? h.url ?? h.webhookUrl ?? "");
    return hookUrl === url;
  });
  let checkinStatus = list.status;
  if (has) {
    logs.push("webhook check-in já registrado");
  } else {
    const created = await totalpassFetch("checkin", "/partner/webhook/create", {
      method: "POST",
      placeApiKey,
      sandbox,
      body: JSON.stringify({ webhook_url: url, webhook_type: "CHECKIN" }),
    });
    checkinStatus = created.status;
    logs.push(`POST /partner/webhook/create CHECKIN → ${created.status}`);
    if (!(created.ok || created.status === 200 || created.status === 201)) {
      logs.push(errorText(created.json, created.text).slice(0, 240));
    }
  }
  return {
    booking_webhook_status: bookingStatus,
    checkin_webhook_status: checkinStatus,
  };
}
