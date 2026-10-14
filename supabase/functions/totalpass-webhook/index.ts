import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  background,
  countBooked,
  padHora,
  saoPauloDateISO,
  weekdaysFromDias,
  weekdayIso,
} from "../_shared/wellhub.ts";
import {
  asRecord,
  confirmBookingSlot,
  confirmCheckinEndpoint,
  cpfFromUser,
  envPlaceKey,
  envSandbox,
  markTotalpassCheckinToday,
  serviceClient,
  upsertAlunoFromTotalpass,
} from "../_shared/totalpass.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function ack(body: Record<string, unknown> = { ok: true }, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function eventKey(payload: Record<string, unknown>) {
  const type = String(payload.type ?? "").toUpperCase();
  const checkIn = asRecord(payload.check_in);
  if (type === "CHECK_IN_CREATED" || Object.keys(checkIn).length > 0) {
    const endpoint = String(payload.endpoint ?? "");
    const token = endpoint.split("/").filter(Boolean).pop() ?? "";
    const cpf = cpfFromUser(asRecord(payload.user));
    const started = String(checkIn.started_at ?? "");
    const key = token ? `checkin:${token}` : `checkin:${cpf}:${started}`;
    return { key, kind: "checkin" as const, type: type || "CHECK_IN_CREATED" };
  }
  const slot = asRecord(payload.slot);
  if (slot.id != null || payload.event) {
    const status = String(slot.status ?? "received");
    const id = String(slot.id ?? "");
    const cpf = cpfFromUser(asRecord(payload.user));
    const date = String(slot.date ?? "");
    const key = id ? `slot:${id}:${status}` : `slot:${cpf}:${date}:${status}`;
    return { key, kind: "booking" as const, type: "booking" };
  }
  return { key: `raw:${JSON.stringify(payload).slice(0, 180)}`, kind: "other" as const, type: type || "unknown" };
}

function slotInstant(raw: string) {
  const t = Date.parse(raw);
  if (!Number.isFinite(t)) {
    const match = raw.match(/^(\d{4}-\d{2}-\d{2})[T ](\d{2}:\d{2})/);
    return { data: match?.[1] ?? raw.slice(0, 10), hora: match?.[2] ?? "" };
  }
  const data = saoPauloDateISO(new Date(t));
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone: "America/Sao_Paulo",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).formatToParts(new Date(t));
  const get = (kind: string) => parts.find((p) => p.type === kind)?.value ?? "00";
  return { data, hora: `${get("hour")}:${get("minute")}` };
}

function isCancelStatus(status: string) {
  return /cancel|denied|expired|removed|rejected/i.test(status);
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return ack({ ok: false, message: "Method not allowed" }, 405);

  const rawBody = await req.text();
  let payload: Record<string, unknown> = {};
  try {
    payload = rawBody ? JSON.parse(rawBody) as Record<string, unknown> : {};
  } catch {
    return ack({ ok: false, message: "invalid json" }, 400);
  }

  const { key, kind, type } = eventKey(payload);
  const db = serviceClient();
  const { data: inserted, error } = await db
    .from("totalpass_webhook_events")
    .insert({
      event_id: key,
      event_type: type,
      payload,
      status: "received",
    })
    .select("id")
    .maybeSingle();

  if (error && (error.code === "23505" || String(error.message).toLowerCase().includes("duplicate"))) {
    return ack({ ok: true, duplicate: true, event_id: key });
  }
  if (error) {
    console.error("[totalpass-webhook] persist", error.message);
  }

  const rowId = inserted?.id ?? null;
  if (kind === "checkin") {
    const result = await handleCheckin(rowId, payload);
    return ack({ ok: true, event_type: type, event_id: key, ...result });
  }

  background(handleBooking(rowId, payload));
  return ack({ ok: true, event_type: type, event_id: key });
});

async function finish(rowId: number | null, status: string, error?: string) {
  if (!rowId) return;
  const db = serviceClient();
  await db.from("totalpass_webhook_events").update({
    status,
    error: error ?? null,
    processed_at: new Date().toISOString(),
  }).eq("id", rowId);
}

async function handleCheckin(rowId: number | null, payload: Record<string, unknown>) {
  const db = serviceClient();
  try {
    const user = asRecord(payload.user);
    const checkIn = asRecord(payload.check_in);
    const cpf = cpfFromUser(user);
    const aluno = await upsertAlunoFromTotalpass(db, user);
    if (cpf) {
      await markTotalpassCheckinToday(db, cpf, "CHECK_IN_CREATED", {
        plan_code: String(checkIn.plan_code ?? "") || undefined,
      });
    }
    if (aluno) await markPresenca(db, aluno.id, String(user.name ?? ""));

    const endpoint = String(payload.endpoint ?? "").trim();
    let confirmStatus = 0;
    let confirmMessage = "sem endpoint";
    if (endpoint) {
      const confirmed = await confirmCheckinEndpoint(endpoint);
      confirmStatus = confirmed.status;
      confirmMessage = confirmed.message;
      if (!confirmed.ok) {
        console.warn(`[totalpass-webhook] confirmação check-in HTTP ${confirmed.status} ${confirmed.message}`);
      }
    }
    await finish(rowId, confirmStatus === 200 || confirmStatus === 0 ? "processed" : "confirm_failed", confirmMessage);
    return { confirm_status: confirmStatus, confirm_message: confirmMessage, cpf_ok: cpf.length === 11 };
  } catch (err) {
    console.error("[totalpass-webhook] check-in", err);
    await finish(rowId, "error", String(err));
    return { confirm_status: 0, confirm_message: "erro interno" };
  }
}

async function markPresenca(db: ReturnType<typeof serviceClient>, alunoId: number, nome: string) {
  const day = saoPauloDateISO();
  const { data: ag } = await db
    .from("agendamentos")
    .select("horario_id, horario")
    .eq("aluno_id", alunoId)
    .eq("data", day)
    .ilike("status", "confirmado")
    .limit(1)
    .maybeSingle();
  if (!ag) return;
  const { error } = await db.from("presencas").insert({
    aluno_id: alunoId,
    horario_id: ag.horario_id,
    data: day,
    horario: ag.horario ?? "",
    tipo: "totalpass_webhook",
    nome_aluno: nome || null,
  });
  if (error && error.code !== "23505" && !String(error.message).toLowerCase().includes("duplicate")) {
    console.warn("[totalpass-webhook] presença", error.message);
  }
}

async function handleBooking(rowId: number | null, payload: Record<string, unknown>) {
  const db = serviceClient();
  try {
    const slot = asRecord(payload.slot);
    const event = asRecord(payload.event);
    const user = asRecord(payload.user);
    const slotId = String(slot.id ?? "").trim();
    const status = String(slot.status ?? "");
    const when = slotInstant(String(slot.date ?? ""));
    const aluno = await upsertAlunoFromTotalpass(db, user);

    if (slotId && isCancelStatus(status)) {
      if (slotId) {
        await db.from("agendamentos").delete().eq("totalpass_slot_id", slotId);
      }
      await finish(rowId, "processed");
      return;
    }

    const { data: horarios } = await db.from("horarios").select("id, hora, dias, capacidade");
    const matched = matchHorario(horarios ?? [], event, when.data, when.hora);

    if (!matched || !aluno || !when.data) {
      console.log(
        `[totalpass-webhook] reserva sem casar horario slot=${slotId || "?"} data=${when.data} hora=${when.hora}`,
      );
      await maybeConfirm(slot, true);
      await finish(rowId, "processed", matched ? undefined : "sem horario correspondente");
      return;
    }

    const cap = Number(matched.capacidade ?? 12) || 12;
    const booked = await countBooked(db, Number(matched.id), when.data);
    if (booked >= cap) {
      await maybeConfirm(slot, false, "Aula lotada");
      await finish(rowId, "processed", "aula lotada");
      return;
    }

    const nome = String(user.name ?? "").trim() || "Aluno TotalPass";
    const eventId = Number(event.id ?? 0) || null;
    const { error: insertErr } = await db.from("agendamentos").insert({
      aluno_id: aluno.id,
      nome_aluno: nome,
      horario_id: matched.id,
      data: when.data,
      horario: padHora(String(matched.hora ?? when.hora)),
      status: "Confirmado",
      origem: "totalpass",
      totalpass_slot_id: slotId || null,
      totalpass_event_id: eventId,
    });
    if (insertErr) {
      const dup = insertErr.code === "23505" || String(insertErr.message).toLowerCase().includes("duplicate") ||
        String(insertErr.message).toLowerCase().includes("unique");
      if (!dup) {
        console.error("[totalpass-webhook] agendamento", insertErr.message);
        await maybeConfirm(slot, false, "Falha ao criar agendamento");
        await finish(rowId, "error", insertErr.message);
        return;
      }
    }
    await maybeConfirm(slot, true);
    await finish(rowId, "processed");
  } catch (err) {
    console.error("[totalpass-webhook] booking", err);
    await finish(rowId, "error", String(err));
  }
}

function matchHorario(
  horarios: Array<{ id: number; hora: string; dias: string; capacidade?: number }>,
  event: Record<string, unknown>,
  data: string,
  hora: string,
) {
  const ref = String(event.externalReference ?? event.external_reference ?? "");
  const desc = String(event.description ?? "");
  const refMatch = `${ref} ${desc}`.match(/horario:(\d+)/);
  if (refMatch) {
    const found = horarios.find((h) => Number(h.id) === Number(refMatch[1]));
    if (found) return found;
  }
  const alvo = padHora(hora);
  const title = String(event.title ?? "");
  const byTime = horarios.filter((h) => {
    const hHora = padHora(String(h.hora ?? ""));
    if (hHora !== alvo && !title.includes(hHora)) return false;
    const days = weekdaysFromDias(String(h.dias ?? ""));
    if (!data || days.size === 0) return hHora === alvo;
    return days.has(weekdayIso(data));
  });
  return byTime[0] ?? null;
}

async function maybeConfirm(slot: Record<string, unknown>, accept: boolean, reason?: string) {
  const confirmationUrl = String(slot.confirmation_url ?? "").trim();
  const slotId = String(slot.id ?? "").trim();
  if (!confirmationUrl || !slotId) return;
  const res = await confirmBookingSlot({
    slotId,
    state: accept ? "confirmed" : "denied",
    reason,
    placeApiKey: envPlaceKey(),
    sandbox: envSandbox(),
  });
  if (!(res.ok || res.status === 200 || res.status === 201)) {
    console.warn(`[totalpass-webhook] confirmSlot ${slotId} → HTTP ${res.status}`);
  }
}
