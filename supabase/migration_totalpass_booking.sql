-- TotalPass Booking + check-in. Idempotente. Não apaga dados.

ALTER TABLE agendamentos ADD COLUMN IF NOT EXISTS totalpass_slot_id TEXT;
ALTER TABLE agendamentos ADD COLUMN IF NOT EXISTS totalpass_event_id BIGINT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_agendamentos_totalpass_slot
  ON agendamentos (totalpass_slot_id)
  WHERE totalpass_slot_id IS NOT NULL AND totalpass_slot_id <> '';

COMMENT ON COLUMN agendamentos.totalpass_slot_id IS 'id do slot TotalPass (reserva)';
COMMENT ON COLUMN agendamentos.totalpass_event_id IS 'id do evento TotalPass';
COMMENT ON COLUMN agendamentos.origem IS 'app | wellhub | totalpass';

CREATE TABLE IF NOT EXISTS totalpass_webhook_events (
  id BIGSERIAL PRIMARY KEY,
  event_id TEXT,
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  status TEXT NOT NULL DEFAULT 'received',
  error TEXT,
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_totalpass_webhook_events_event_id
  ON totalpass_webhook_events (event_id)
  WHERE event_id IS NOT NULL AND event_id <> '';

CREATE INDEX IF NOT EXISTS idx_totalpass_webhook_events_type
  ON totalpass_webhook_events (event_type, received_at DESC);

CREATE TABLE IF NOT EXISTS totalpass_daily_checkins (
  id BIGSERIAL PRIMARY KEY,
  cpf TEXT NOT NULL,
  checkin_date DATE NOT NULL,
  source TEXT NOT NULL DEFAULT 'webhook',
  plan_code TEXT,
  slot_id TEXT,
  validated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (cpf, checkin_date)
);

CREATE INDEX IF NOT EXISTS idx_totalpass_daily_checkins_date
  ON totalpass_daily_checkins (checkin_date);

CREATE TABLE IF NOT EXISTS totalpass_events (
  id BIGSERIAL PRIMARY KEY,
  horario_id BIGINT REFERENCES horarios(id) ON DELETE CASCADE,
  totalpass_event_id BIGINT NOT NULL,
  external_reference TEXT NOT NULL,
  title TEXT,
  plan_id BIGINT,
  slots INT NOT NULL DEFAULT 1,
  synced_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (external_reference),
  UNIQUE (totalpass_event_id)
);

CREATE INDEX IF NOT EXISTS idx_totalpass_events_horario
  ON totalpass_events (horario_id);

ALTER TABLE totalpass_webhook_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE totalpass_daily_checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE totalpass_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_all_totalpass_webhook_events" ON totalpass_webhook_events;
CREATE POLICY "anon_all_totalpass_webhook_events" ON totalpass_webhook_events
  FOR ALL USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_all_totalpass_daily_checkins" ON totalpass_daily_checkins;
CREATE POLICY "anon_all_totalpass_daily_checkins" ON totalpass_daily_checkins
  FOR ALL USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_all_totalpass_events" ON totalpass_events;
CREATE POLICY "anon_all_totalpass_events" ON totalpass_events
  FOR ALL USING (true) WITH CHECK (true);
