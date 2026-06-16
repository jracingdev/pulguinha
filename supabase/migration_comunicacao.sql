-- Comunicação: quadro de avisos + agenda de eventos + leituras
-- Rodar uma vez no Supabase SQL Editor

CREATE TABLE IF NOT EXISTS avisos (
  id BIGSERIAL PRIMARY KEY,
  titulo TEXT NOT NULL,
  texto TEXT NOT NULL,
  autor TEXT NOT NULL DEFAULT 'Admin',
  data_hora TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  mencoes BIGINT[] NOT NULL DEFAULT '{}',
  notificar_todos BOOLEAN NOT NULL DEFAULT true,
  fixado BOOLEAN NOT NULL DEFAULT false,
  ativo BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS eventos (
  id BIGSERIAL PRIMARY KEY,
  titulo TEXT NOT NULL,
  descricao TEXT NOT NULL DEFAULT '',
  data_inicio TIMESTAMPTZ NOT NULL,
  data_fim TIMESTAMPTZ,
  local TEXT,
  mencoes BIGINT[] NOT NULL DEFAULT '{}',
  notificar_todos BOOLEAN NOT NULL DEFAULT true,
  lembrete_dias_antes INT NOT NULL DEFAULT 1,
  ativo BOOLEAN NOT NULL DEFAULT true,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS comunicacao_leituras (
  aluno_id BIGINT NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
  item_tipo TEXT NOT NULL,
  item_id BIGINT NOT NULL,
  lido_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (aluno_id, item_tipo, item_id)
);

CREATE INDEX IF NOT EXISTS idx_avisos_ativo ON avisos(ativo, data_hora DESC);
CREATE INDEX IF NOT EXISTS idx_eventos_inicio ON eventos(data_inicio);
CREATE INDEX IF NOT EXISTS idx_leituras_aluno ON comunicacao_leituras(aluno_id);

ALTER TABLE avisos ENABLE ROW LEVEL SECURITY;
ALTER TABLE eventos ENABLE ROW LEVEL SECURITY;
ALTER TABLE comunicacao_leituras ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_all_avisos" ON avisos;
CREATE POLICY "anon_all_avisos" ON avisos FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_all_eventos" ON eventos;
CREATE POLICY "anon_all_eventos" ON eventos FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_all_leituras" ON comunicacao_leituras;
CREATE POLICY "anon_all_leituras" ON comunicacao_leituras FOR ALL USING (true) WITH CHECK (true);
