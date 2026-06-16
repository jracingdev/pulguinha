-- Indique e Ganhe: código por aluno, crédito e tabela de indicações.

ALTER TABLE alunos ADD COLUMN IF NOT EXISTS codigo_indicacao TEXT;
ALTER TABLE alunos ADD COLUMN IF NOT EXISTS credito_indicacao NUMERIC(10, 2) NOT NULL DEFAULT 0;

CREATE UNIQUE INDEX IF NOT EXISTS idx_alunos_codigo_indicacao
  ON alunos (codigo_indicacao)
  WHERE codigo_indicacao IS NOT NULL AND codigo_indicacao <> '';

CREATE TABLE IF NOT EXISTS indicacoes (
  id BIGSERIAL PRIMARY KEY,
  indicador_id BIGINT NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
  indicado_id BIGINT NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
  codigo_usado TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pendente',
  data_criacao DATE NOT NULL DEFAULT CURRENT_DATE,
  data_conversao DATE,
  UNIQUE (indicado_id)
);

CREATE INDEX IF NOT EXISTS idx_indicacoes_indicador ON indicacoes(indicador_id);
CREATE INDEX IF NOT EXISTS idx_indicacoes_status ON indicacoes(status);

ALTER TABLE indicacoes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_all_indicacoes" ON indicacoes;
CREATE POLICY "anon_all_indicacoes" ON indicacoes FOR ALL USING (true) WITH CHECK (true);

-- Indique e Ganhe: código por aluno, crédito e tabela de indicações.

ALTER TABLE alunos ADD COLUMN IF NOT EXISTS codigo_indicacao TEXT;
ALTER TABLE alunos ADD COLUMN IF NOT EXISTS credito_indicacao NUMERIC(10, 2) NOT NULL DEFAULT 0;

CREATE UNIQUE INDEX IF NOT EXISTS idx_alunos_codigo_indicacao
  ON alunos (codigo_indicacao)
  WHERE codigo_indicacao IS NOT NULL AND codigo_indicacao <> '';

CREATE TABLE IF NOT EXISTS indicacoes (
  id BIGSERIAL PRIMARY KEY,
  indicador_id BIGINT NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
  indicado_id BIGINT NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
  codigo_usado TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pendente',
  data_criacao DATE NOT NULL DEFAULT CURRENT_DATE,
  data_conversao DATE,
  UNIQUE (indicado_id)
);

CREATE INDEX IF NOT EXISTS idx_indicacoes_indicador ON indicacoes(indicador_id);
CREATE INDEX IF NOT EXISTS idx_indicacoes_status ON indicacoes(status);

ALTER TABLE indicacoes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_all_indicacoes" ON indicacoes;
CREATE POLICY "anon_all_indicacoes" ON indicacoes FOR ALL USING (true) WITH CHECK (true);
