import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  bookingWindowFor,
  createClasses,
  createSlot,
  envGymId,
  envProductId,
  envSandbox,
  listCategories,
  listClasses,
  listProducts,
  listSlots,
  nextDays,
  occurDateIso,
  padHora,
  putClass,
  putSlot,
  serviceClient,
  SLOT_STATUS_ACTIVE,
  syncOccupancyFor,
  weekdaysFromDias,
  weekdayIso,
} from "../_shared/wellhub.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const SLOT_MINUTES = Number(Deno.env.get("WELLHUB_CLASS_DURATION_MINUTES") ?? "60") || 60;
const HORIZON_DAYS = Number(Deno.env.get("WELLHUB_SLOT_HORIZON_DAYS") ?? "14") || 14;

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const body = req.method === "GET" ? { action: "meta" } : ((await req.json().catch(() => ({}))) as Record<string, unknown>);
    const action = String(body.action ?? "sync_schedule");
    const gymId = String(body.wellhub_gym_id || body.gym_id || envGymId() || "824346").trim();

    if (action === "meta") {
      return jsonResponse(await meta(gymId));
    }
    if (action === "occupancy") {
      const horarioId = Number(body.horario_id);
      const data = String(body.data ?? "");
      if (!horarioId || !data) {
        return jsonResponse({ ok: false, message: "horario_id e data são obrigatórios" }, 400);
      }
      const result = await syncOccupancyFor(serviceClient(), horarioId, data, gymId);
      return jsonResponse({ ok: result.ok, ...result });
    }
    if (action === "sync_schedule") {
      const result = await syncSchedule(gymId);
      return jsonResponse(result);
    }
    return jsonResponse({ ok: false, message: "action inválida" }, 400);
  } catch (error) {
    return jsonResponse({ ok: false, message: String(error) }, 500);
  }
});

async function meta(gymId: string) {
  const products = await listProducts(gymId);
  const categories = await listCategories(gymId, "pt-BR");
  return {
    ok: true,
    gym_id: gymId,
    sandbox: envSandbox(),
    production_gym_id: "824346",
    sandbox_gym_id: "683",
    unit: "Funcional do Pulguinha",
    webhook_url: `${Deno.env.get("SUPABASE_URL")}/functions/v1/wellhub-webhook`,
    test_users: ["1000000000001", "1000000000003"],
    products: products.json,
    categories: categories.json,
    products_status: products.status,
    categories_status: categories.status,
  };
}

function asArray(payload: unknown, keys: string[]): Record<string, unknown>[] {
  if (Array.isArray(payload)) return payload as Record<string, unknown>[];
  if (payload && typeof payload === "object") {
    const obj = payload as Record<string, unknown>;
    for (const key of keys) {
      if (Array.isArray(obj[key])) return obj[key] as Record<string, unknown>[];
    }
    if (Array.isArray(obj.results)) return obj.results as Record<string, unknown>[];
  }
  return [];
}

function pickProductId(productsPayload: unknown): number | null {
  const envId = envProductId();
  if (envId) return envId;
  const products = asArray(productsPayload, ["products"]);
  const inPerson = products.find((p) => p.virtual !== true && p.virtual !== "true");
  const chosen = inPerson ?? products[0];
  if (!chosen) return null;
  const id = Number(chosen.product_id ?? chosen.id);
  return Number.isFinite(id) ? id : null;
}

function pickCategoryIds(categoriesPayload: unknown): number[] {
  const cats = asArray(categoriesPayload, ["categories", "results"]);
  const scored = cats.map((c) => {
    const name = String(c.name ?? "").toLowerCase();
    const id = Number(c.id);
    let score = 0;
    if (name.includes("funcional")) score += 5;
    if (name.includes("muay") || name.includes("thai") || name.includes("luta") || name.includes("martial")) score += 4;
    if (name.includes("boxe") || name.includes("boxing")) score += 3;
    if (name.includes("cross")) score += 2;
    return { id, score };
  }).filter((c) => Number.isFinite(c.id));
  scored.sort((a, b) => b.score - a.score);
  const ids = scored.filter((c) => c.score > 0).slice(0, 2).map((c) => c.id);
  if (ids.length) return ids;
  return scored.slice(0, 1).map((c) => c.id);
}

async function syncSchedule(gymId: string) {
  const db = serviceClient();
  const logs: string[] = [];
  const productsRes = await listProducts(gymId);
  const categoriesRes = await listCategories(gymId, "pt-BR");
  const productId = pickProductId(productsRes.json);
  const categoryIds = pickCategoryIds(categoriesRes.json);

  if (!productId) {
    return {
      ok: false,
      message: "Nenhum product_id. Defina WELLHUB_PRODUCT_ID ou confira GET /setup/v1/gyms/{id}/products.",
      products: productsRes.json,
      products_status: productsRes.status,
    };
  }
  logs.push(`product_id=${productId} categories=${categoryIds.join(",") || "nenhuma"}`);

  const { data: horarios, error: horErr } = await db.from("horarios").select("id, hora, dias, capacidade").order("id");
  if (horErr) return { ok: false, message: horErr.message };
  const rows = horarios ?? [];

  const remoteClassesRes = await listClasses(gymId);
  const remoteClasses = asArray(remoteClassesRes.json, ["classes"]);
  const byReference = new Map<string, number>();
  for (const c of remoteClasses) {
    const ref = String(c.reference ?? "");
    const id = Number(c.id);
    if (ref && Number.isFinite(id)) byReference.set(ref, id);
  }

  const { data: mappedClasses } = await db.from("wellhub_classes").select("horario_id, wellhub_class_id, reference");
  for (const m of mappedClasses ?? []) {
    byReference.set(String(m.reference), Number(m.wellhub_class_id));
  }

  const classMap = new Map<number, number>();

  for (const h of rows) {
    const reference = `horario:${h.id}`;
    const name = `Pulguinha ${padHora(String(h.hora))}`;
    const description = `Aula ${padHora(String(h.hora))} (${h.dias}) — Funcional do Pulguinha`;
    const payload = {
      name,
      description,
      notes: `Grade Pulguinha · ${h.dias} · capacidade ${h.capacidade}`,
      bookable: true,
      visible: true,
      reference,
      product_id: productId,
      ...(categoryIds.length ? { categories: categoryIds } : {}),
    };

    let classId = byReference.get(reference);
    if (classId) {
      const put = await putClass(gymId, classId, payload);
      logs.push(`PUT class ${classId} (${reference}) → ${put.status}`);
    } else {
      const created = await createClasses(gymId, [payload]);
      const createdList = asArray(created.json, ["classes"]);
      classId = Number(createdList[0]?.id);
      logs.push(`POST class (${reference}) → ${created.status} id=${classId || "?"}`);
      if (!classId) {
        logs.push(`falha criar class: ${created.text}`);
        continue;
      }
    }

    classMap.set(Number(h.id), classId);
    await db.from("wellhub_classes").upsert({
      horario_id: h.id,
      wellhub_class_id: classId,
      reference,
      product_id: productId,
      name,
      synced_at: new Date().toISOString(),
    }, { onConflict: "horario_id" });
  }

  const days = nextDays(HORIZON_DAYS);
  const fromIso = occurDateIso(days[0], "00:00");
  const toIso = occurDateIso(days[days.length - 1], "23:59");
  let slotsCreated = 0;
  let slotsUpdated = 0;

  for (const h of rows) {
    const classId = classMap.get(Number(h.id));
    if (!classId) continue;
    const weekdays = weekdaysFromDias(String(h.dias ?? ""));
    const remoteSlotsRes = await listSlots(gymId, classId, fromIso, toIso);
    const remoteSlots = asArray(remoteSlotsRes.json, ["slots"]);
    const remoteByOccur = new Map<string, number>();
    for (const s of remoteSlots) {
      const occur = String(s.occur_date ?? "");
      const id = Number(s.id);
      if (occur && Number.isFinite(id)) remoteByOccur.set(occur.slice(0, 16), id);
    }

    for (const day of days) {
      if (weekdays.size && !weekdays.has(weekdayIso(day))) continue;
      const occur = occurDateIso(day, String(h.hora));
      const window = bookingWindowFor(occur);
      const booked = await countLocal(db, Number(h.id), day);
      const slotPayload = {
        occur_date: occur,
        status: SLOT_STATUS_ACTIVE,
        length_in_minutes: SLOT_MINUTES,
        total_capacity: Number(h.capacidade ?? 12),
        total_booked: booked,
        product_id: productId,
        booking_window: { opens_at: window.opens_at, closes_at: window.closes_at },
        cancellable_until: window.cancellable_until,
      };

      const existingId = remoteByOccur.get(occur.slice(0, 16));
      let slotId = existingId;
      if (slotId) {
        const put = await putSlot(gymId, classId, slotId, slotPayload);
        logs.push(`PUT slot ${slotId} ${occur} → ${put.status}`);
        slotsUpdated++;
      } else {
        const created = await createSlot(gymId, classId, slotPayload);
        const createdBody = created.json as Record<string, unknown> | null;
        slotId = Number(createdBody?.id ?? asArray(created.json, ["slots"])[0]?.id);
        logs.push(`POST slot ${occur} → ${created.status} id=${slotId || "?"}`);
        if (!slotId) {
          logs.push(`falha criar slot: ${created.text}`);
          continue;
        }
        slotsCreated++;
      }

      await db.from("wellhub_slots").upsert({
        horario_id: h.id,
        wellhub_class_id: classId,
        wellhub_slot_id: slotId,
        occur_date: occur,
        data: day,
        total_capacity: Number(h.capacidade ?? 12),
        total_booked: booked,
        synced_at: new Date().toISOString(),
      }, { onConflict: "horario_id,data" });
    }
  }

  return {
    ok: true,
    gym_id: gymId,
    product_id: productId,
    classes: classMap.size,
    slots_created: slotsCreated,
    slots_updated: slotsUpdated,
    horizon_days: HORIZON_DAYS,
    logs,
  };
}

async function countLocal(db: ReturnType<typeof serviceClient>, horarioId: number, data: string) {
  const { count } = await db
    .from("agendamentos")
    .select("id", { count: "exact", head: true })
    .eq("horario_id", horarioId)
    .eq("data", data)
    .not("status", "ilike", "%cancel%");
  return count ?? 0;
}
