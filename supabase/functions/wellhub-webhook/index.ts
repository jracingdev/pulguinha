import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  alreadyCheckedInToday,
  background,
  countBooked,
  envGymId,
  extractEvent,
  getSlot,
  markCheckedInToday,
  normalizeGympassId,
  patchBookingAlways,
  saoPauloDateISO,
  serviceClient,
  slotFromEvent,
  syncOccupancyFor,
  upsertAlunoFromWellhub,
  userFromEvent,
  validateAccess,
  verifySignature,
} from "../_shared/wellhub.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-gympass-signature",
};

function ack(body: Record<string, unknown> = { ok: true }, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return ack({ ok: false, message: "Method not allowed" }, 405);

  const rawBody = await req.text();
  const signature = req.headers.get("X-Gympass-Signature") ?? req.headers.get("x-gympass-signature");

  const valid = await verifySignature(rawBody, signature);
  if (!valid) {
    console.warn("[wellhub-webhook] assinatura inválida");
    return ack({ ok: false, message: "invalid signature" }, 401);
  }

  let payload: Record<string, unknown> = {};
  try {
    payload = rawBody ? JSON.parse(rawBody) as Record<string, unknown> : {};
  } catch {
    return ack({ ok: false, message: "invalid json" }, 400);
  }

  const { eventType, eventData, eventId } = extractEvent(payload);
  const db = serviceClient();
  const id = eventId || crypto.randomUUID();

  const { data: inserted, error } = await db
    .from("wellhub_webhook_events")
    .insert({
      event_id: id,
      event_type: eventType || "unknown",
      payload,
      signature,
      status: "received",
    })
    .select("id")
    .maybeSingle();

  if (error && (error.code === "23505" || String(error.message).toLowerCase().includes("duplicate"))) {
    return ack({ ok: true, duplicate: true, event_id: id });
  }
  if (error) {
    console.error("[wellhub-webhook] persist", error.message);
  }

  background(processEvent(inserted?.id ?? null, eventType, eventData, payload, id));
  return ack({ ok: true, event_type: eventType, event_id: id });
});

async function processEvent(
  rowId: number | null,
  eventType: string,
  eventData: Record<string, unknown>,
  payload: Record<string, unknown>,
  eventId: string,
) {
  const db = serviceClient();
  try {
    const type = eventType.toLowerCase();
    console.log(`[wellhub-webhook] process type=${type} event=${eventId}`);
    if (type === "checkin") {
      await handleCheckin(eventData, "checkin");
    } else if (type === "checkin-booking-occurred") {
      await handleCheckin(eventData, "checkin-booking-occurred");
    } else if (type === "booking-requested") {
      await handleBookingRequested(eventData);
    } else if (type === "booking-canceled" || type === "booking-late-canceled") {
      await handleBookingCanceled(eventData);
    } else if (type === "system-integration-requested") {
      console.log("[wellhub-webhook] system-integration-requested", JSON.stringify(payload));
    } else {
      console.log("[wellhub-webhook] evento não mapeado", eventType);
    }
    if (rowId) {
      await db.from("wellhub_webhook_events").update({
        status: "processed",
        processed_at: new Date().toISOString(),
      }).eq("id", rowId);
    }
  } catch (err) {
    console.error("[wellhub-webhook] process", eventId, err);
    if (rowId) {
      await db.from("wellhub_webhook_events").update({
        status: "error",
        error: String(err),
        processed_at: new Date().toISOString(),
      }).eq("id", rowId);
    }
  }
}

async function handleCheckin(eventData: Record<string, unknown>, source: string) {
  const db = serviceClient();
  const user = userFromEvent(eventData);
  const gympassId = normalizeGympassId(user.unique_token ?? "");
  if (gympassId.length !== 13) {
    console.warn("[wellhub-webhook] checkin sem unique_token");
    return;
  }

  await upsertAlunoFromWellhub(db, user);

  const gym = (eventData.gym ?? {}) as Record<string, unknown>;
  const product = (gym.product ?? eventData.product ?? {}) as Record<string, unknown>;
  const booking = (eventData.booking ?? {}) as Record<string, unknown>;
  const bookingNumber = String(booking.booking_number ?? "").trim() || undefined;
  const productId = product.id != null ? Number(product.id) : undefined;

  if (await alreadyCheckedInToday(db, gympassId)) {
    console.log("[wellhub-webhook] check-in já consumido hoje", gympassId.slice(-4));
    return;
  }

  const result = await validateAccess(gympassId);
  if (result.ok) {
    await markCheckedInToday(db, gympassId, source, {
      booking_number: bookingNumber,
      product_id: productId,
    });
  } else {
    console.warn("[wellhub-webhook] validate falhou", result.status, result.text);
  }
}

async function occupancyPatch(
  db: ReturnType<typeof serviceClient>,
  gymId: string,
  classId: number,
  slotId: number,
  horarioId?: number,
  data?: string,
  delta?: number,
) {
  const result = await syncOccupancyFor(db, {
    gymId,
    classId,
    slotId,
    horarioId,
    data,
    delta,
  });
  console.log(
    `[wellhub-webhook] occupancy gym=${result.gymId ?? gymId} class=${result.classId ?? classId} slot=${result.slotId ?? slotId} booked=${result.booked} cap=${result.capacity} → HTTP ${result.status ?? "skip"} ${result.ok ? "ok" : result.message ?? ""}`,
  );
  return result;
}

async function handleBookingRequested(eventData: Record<string, unknown>) {
  const db = serviceClient();
  const slot = slotFromEvent(eventData);
  const user = userFromEvent(eventData);
  const gymId = slot.gym_id || envGymId();
  const bookingNumber = slot.booking_number;
  const slotId = slot.id;
  const classIdFromEvent = slot.class_id;

  if (!bookingNumber) {
    console.warn("[wellhub-webhook] booking-requested sem booking_number");
    return;
  }

  let remoteOk = false;
  let remoteCap = 0;
  if (classIdFromEvent && slotId) {
    const remote = await getSlot(gymId, classIdFromEvent, slotId);
    remoteOk = remote.ok || remote.status === 200;
    const body = (remote.json && typeof remote.json === "object")
      ? remote.json as Record<string, unknown>
      : {};
    remoteCap = Number(body.total_capacity ?? 0);
    console.log(
      `[wellhub-webhook] GET slot gym=${gymId} class=${classIdFromEvent} slot=${slotId} → HTTP ${remote.status} exists=${remoteOk}`,
    );
  }

  const mapped = await resolveSlot(db, gymId, slotId, classIdFromEvent);
  if (!mapped && !remoteOk) {
    await patchBookingAlways({
      gymId,
      bookingNumber,
      classId: classIdFromEvent || 0,
      accept: false,
      reason: "Aula não encontrada na grade do Pulguinha",
      reasonCategory: "CLASS_NOT_FOUND",
    });
    return;
  }

  const horarioId = mapped ? Number(mapped.horario_id) : 0;
  const data = mapped ? String(mapped.data) : "";
  const classId = Number(classIdFromEvent || mapped?.wellhub_class_id);
  const slotIdResolved = Number(slotId || mapped?.wellhub_slot_id);
  const capacity = Number(mapped?.total_capacity ?? remoteCap ?? 12);

  if (mapped && horarioId) {
    const { data: horario } = await db.from("horarios").select("id, capacidade, hora").eq("id", horarioId).maybeSingle();
    const cap = Number(horario?.capacidade ?? capacity);

    const aluno = await upsertAlunoFromWellhub(db, user);
    if (!aluno) {
      await patchBookingAlways({
        gymId,
        bookingNumber,
        classId,
        accept: false,
        reason: "Cadastro do aluno não pôde ser criado",
        reasonCategory: "USER_DOES_NOT_EXIST",
      });
      return;
    }

    const { data: existingBooking } = await db
      .from("agendamentos")
      .select("id")
      .eq("wellhub_booking_number", bookingNumber)
      .maybeSingle();
    if (existingBooking) {
      await patchBookingAlways({ gymId, bookingNumber, classId, accept: true });
      await occupancyPatch(db, gymId, classId, slotIdResolved, horarioId, data, 1);
      return;
    }

    const { data: sameClass } = await db
      .from("agendamentos")
      .select("id")
      .eq("aluno_id", aluno.id)
      .eq("horario_id", horarioId)
      .eq("data", data)
      .maybeSingle();
    if (sameClass) {
      await patchBookingAlways({
        gymId,
        bookingNumber,
        classId,
        accept: false,
        reason: "Aluno já está agendado nesta aula",
        reasonCategory: "USER_IS_ALREADY_BOOKED",
      });
      return;
    }

    const booked = await countBooked(db, horarioId, data);
    if (booked >= cap) {
      await patchBookingAlways({
        gymId,
        bookingNumber,
        classId,
        accept: false,
        reason: "Aula lotada",
        reasonCategory: "CLASS_IS_FULL",
      });
      await occupancyPatch(db, gymId, classId, slotIdResolved, horarioId, data, 0);
      return;
    }

    const nome =
      (user.name ?? `${user.first_name ?? ""} ${user.last_name ?? ""}`.trim()) || "Aluno Wellhub";
    const { error: insertErr } = await db.from("agendamentos").insert({
      aluno_id: aluno.id,
      nome_aluno: nome,
      horario_id: horarioId,
      data,
      horario: horario?.hora ?? "",
      status: "Confirmado",
      wellhub_booking_number: bookingNumber,
      wellhub_slot_id: slotIdResolved,
      wellhub_class_id: classId,
      origem: "wellhub",
    });

    if (insertErr) {
      const dup = String(insertErr.message).toLowerCase().includes("unique") ||
        String(insertErr.message).toLowerCase().includes("duplicate");
      await patchBookingAlways({
        gymId,
        bookingNumber,
        classId,
        accept: false,
        reason: dup ? "Aluno já está agendado nesta aula" : "Falha ao criar agendamento",
        reasonCategory: dup ? "USER_IS_ALREADY_BOOKED" : "TECHNICAL_ERROR",
      });
      return;
    }
  } else {
    console.log(
      `[wellhub-webhook] booking-requested sem mapa local — aceitando via slot Wellhub class=${classId} slot=${slotIdResolved}`,
    );
  }

  await patchBookingAlways({ gymId, bookingNumber, classId, accept: true });
  await occupancyPatch(
    db,
    gymId,
    classId,
    slotIdResolved,
    horarioId || undefined,
    data || undefined,
    1,
  );
}

async function handleBookingCanceled(eventData: Record<string, unknown>) {
  const db = serviceClient();
  const slot = slotFromEvent(eventData);
  const gymId = slot.gym_id || envGymId();
  const bookingNumber = slot.booking_number;
  const classId = slot.class_id;
  const slotId = slot.id;

  let horarioId = 0;
  let data = "";

  if (bookingNumber) {
    const { data: ag } = await db
      .from("agendamentos")
      .select("id, horario_id, data")
      .eq("wellhub_booking_number", bookingNumber)
      .maybeSingle();

    if (ag) {
      await db.from("agendamentos").delete().eq("id", ag.id);
      horarioId = Number(ag.horario_id);
      data = String(ag.data ?? "");
      console.log(`[wellhub-webhook] agendamento local removido booking=${bookingNumber} id=${ag.id}`);
    }
  }

  const mapped = (!horarioId || !classId || !slotId)
    ? await resolveSlot(db, gymId, slotId, classId)
    : null;

  const classResolved = classId || Number(mapped?.wellhub_class_id ?? 0);
  const slotResolved = slotId || Number(mapped?.wellhub_slot_id ?? 0);
  const horarioResolved = horarioId || Number(mapped?.horario_id ?? 0);
  const dataResolved = data || String(mapped?.data ?? "");

  // Wellhub já cancela o booking do usuário — NÃO chamar PATCH booking cancel.
  await occupancyPatch(
    db,
    gymId,
    classResolved,
    slotResolved,
    horarioResolved || undefined,
    dataResolved || undefined,
    -1,
  );
}

async function resolveSlot(
  db: ReturnType<typeof serviceClient>,
  gymId: string,
  slotId: number,
  classId: number,
) {
  if (slotId) {
    const { data } = await db
      .from("wellhub_slots")
      .select("horario_id, wellhub_class_id, wellhub_slot_id, data, total_capacity")
      .eq("wellhub_slot_id", slotId)
      .maybeSingle();
    if (data) return data;
  }

  if (classId && slotId) {
    const remote = await getSlot(gymId, classId, slotId);
    const body = remote.json as Record<string, unknown> | null;
    const occur = String(body?.occur_date ?? "");
    const dataIso = occur.slice(0, 10);
    if (dataIso) {
      const { data: byClass } = await db
        .from("wellhub_classes")
        .select("horario_id, wellhub_class_id")
        .eq("wellhub_class_id", classId)
        .maybeSingle();
      if (byClass) {
        return {
          horario_id: byClass.horario_id,
          wellhub_class_id: classId,
          wellhub_slot_id: slotId,
          data: dataIso,
          total_capacity: Number(body?.total_capacity ?? 12),
        };
      }
    }
  }

  if (classId) {
    const { data } = await db
      .from("wellhub_slots")
      .select("horario_id, wellhub_class_id, wellhub_slot_id, data, total_capacity")
      .eq("wellhub_class_id", classId)
      .eq("data", saoPauloDateISO())
      .maybeSingle();
    if (data) return data;
  }

  return null;
}
