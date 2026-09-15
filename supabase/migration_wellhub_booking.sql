-- Wellhub (Gympass) — webhook, check-in do dia, mapa class/slot, booking_number.
-- Idempotente. Access Control (Automated Trigger + Attendance) + Booking API.

ALTER TABLE agendamentos ADD COLUMN IF NOT EXISTS wellhub_booking_number TEXT;
ALTER TABLE agendamentos ADD COLUMN IF NOT EXISTS wellhub_slot_id BIGINT;
ALTER TABLE agendamentos ADD COLUMN IF NOT EXISTS wellhub_class_id BIGINT;
ALTER TABLE agendamentos ADD COLUMN IF NOT EXISTS origem TEXT NOT NULL DEFAULT 'app';

CREATE UNIQUE INDEX IF NOT EXISTS idx_agendamentos_wellhub_booking
  ON agendamentos (wellhub_booking_number)
  WHERE wellhub_booking_number IS NOT NULL AND wellhub_booking_number <> '';

CREATE INDEX IF NOT EXISTS idx_agendamentos_wellhub_slot
  ON agendamentos (wellhub_slot_id)
  WHERE wellhub_slot_id IS NOT NULL;

COMMENT ON COLUMN agendamentos.wellhub_booking_number IS 'booking_number Wellhub (ex.: BK_A1B2C3)';
COMMENT ON COLUMN agendamentos.origem IS 'app | wellhub';

-- Eventos de webhook (idempotência por event_id)
CREATE TABLE IF NOT EXISTS wellhub_webhook_events (
  id BIGSERIAL PRIMARY KEY,
  event_id TEXT,
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  signature TEXT,
  status TEXT NOT NULL DEFAULT 'received',
  error TEXT,
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_wellhub_webhook_events_event_id
  ON wellhub_webhook_events (event_id)
  WHERE event_id IS NOT NULL AND event_id <> '';

CREATE INDEX IF NOT EXISTS idx_wellhub_webhook_events_type
  ON wellhub_webhook_events (event_type, received_at DESC);

-- Check-ins consumidos no dia (America/Sao_Paulo). Evita validar o mesmo check-in duas vezes.
CREATE TABLE IF NOT EXISTS wellhub_daily_checkins (
  id BIGSERIAL PRIMARY KEY,
  gympass_id TEXT NOT NULL,
  checkin_date DATE NOT NULL,
  source TEXT NOT NULL DEFAULT 'validate',
  booking_number TEXT,
  product_id BIGINT,
  validated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (gympass_id, checkin_date)
);

CREATE INDEX IF NOT EXISTS idx_wellhub_daily_checkins_date
  ON wellhub_daily_checkins (checkin_date);

-- Mapa horário Pulguinha ↔ class Wellhub (reference = horario:{id})
CREATE TABLE IF NOT EXISTS wellhub_classes (
  id BIGSERIAL PRIMARY KEY,
  horario_id BIGINT NOT NULL REFERENCES horarios(id) ON DELETE CASCADE,
  wellhub_class_id BIGINT NOT NULL,
  reference TEXT NOT NULL,
  product_id BIGINT,
  name TEXT,
  synced_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (horario_id),
  UNIQUE (wellhub_class_id)
);

CREATE INDEX IF NOT EXISTS idx_wellhub_classes_reference ON wellhub_classes (reference);

-- Mapa slot Wellhub ↔ aula (horário + data)
CREATE TABLE IF NOT EXISTS wellhub_slots (
  id BIGSERIAL PRIMARY KEY,
  horario_id BIGINT NOT NULL REFERENCES horarios(id) ON DELETE CASCADE,
  wellhub_class_id BIGINT NOT NULL,
  wellhub_slot_id BIGINT NOT NULL,
  occur_date TIMESTAMPTZ NOT NULL,
  data DATE NOT NULL,
  total_capacity INT NOT NULL DEFAULT 12,
  total_booked INT NOT NULL DEFAULT 0,
  synced_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (wellhub_slot_id),
  UNIQUE (horario_id, data)
);

CREATE INDEX IF NOT EXISTS idx_wellhub_slots_class ON wellhub_slots (wellhub_class_id);
CREATE INDEX IF NOT EXISTS idx_wellhub_slots_data ON wellhub_slots (data);

ALTER TABLE wellhub_webhook_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE wellhub_daily_checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE wellhub_classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE wellhub_slots ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_all_wellhub_webhook_events" ON wellhub_webhook_events;
CREATE POLICY "anon_all_wellhub_webhook_events" ON wellhub_webhook_events FOR ALL USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_all_wellhub_daily_checkins" ON wellhub_daily_checkins;
CREATE POLICY "anon_all_wellhub_daily_checkins" ON wellhub_daily_checkins FOR ALL USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_all_wellhub_classes" ON wellhub_classes;
CREATE POLICY "anon_all_wellhub_classes" ON wellhub_classes FOR ALL USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_all_wellhub_slots" ON wellhub_slots;
CREATE POLICY "anon_all_wellhub_slots" ON wellhub_slots FOR ALL USING (true) WITH CHECK (true);
