-- Mural moderação, dicas de evolução e desafios gamificados
-- Rodar uma vez no Supabase SQL Editor (após schema.sql)

-- Mural: posts de admin/moderador + ocultar/fixar
ALTER TABLE posts_turma ADD COLUMN IF NOT EXISTS autor_tipo TEXT NOT NULL DEFAULT 'aluno';
ALTER TABLE posts_turma ADD COLUMN IF NOT EXISTS oculto BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE posts_turma ADD COLUMN IF NOT EXISTS fixado BOOLEAN NOT NULL DEFAULT false;

-- Dicas de treino (admin CRUD)
CREATE TABLE IF NOT EXISTS dicas_treino (
  id BIGSERIAL PRIMARY KEY,
  icon TEXT NOT NULL DEFAULT '💡',
  titulo TEXT NOT NULL,
  texto TEXT NOT NULL,
  categoria TEXT NOT NULL DEFAULT 'Geral',
  ativo BOOLEAN NOT NULL DEFAULT true,
  ordem INT NOT NULL DEFAULT 0,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dicas_ativo_ordem ON dicas_treino(ativo, ordem);

-- Desafios gamificados
CREATE TABLE IF NOT EXISTS desafios (
  id BIGSERIAL PRIMARY KEY,
  titulo TEXT NOT NULL,
  descricao TEXT NOT NULL DEFAULT '',
  tipo TEXT NOT NULL DEFAULT 'checkins',
  meta INT NOT NULL DEFAULT 5,
  pontos_recompensa INT NOT NULL DEFAULT 50,
  data_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
  data_fim DATE,
  ativo BOOLEAN NOT NULL DEFAULT true,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS desafio_progresso (
  desafio_id BIGINT NOT NULL REFERENCES desafios(id) ON DELETE CASCADE,
  aluno_id BIGINT NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
  progresso INT NOT NULL DEFAULT 0,
  concluido_em TIMESTAMPTZ,
  PRIMARY KEY (desafio_id, aluno_id)
);

CREATE INDEX IF NOT EXISTS idx_desafios_ativo ON desafios(ativo, data_inicio DESC);
CREATE INDEX IF NOT EXISTS idx_desafio_prog_aluno ON desafio_progresso(aluno_id);

ALTER TABLE dicas_treino ENABLE ROW LEVEL SECURITY;
ALTER TABLE desafios ENABLE ROW LEVEL SECURITY;
ALTER TABLE desafio_progresso ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_all_dicas" ON dicas_treino;
CREATE POLICY "anon_all_dicas" ON dicas_treino FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_all_desafios" ON desafios;
CREATE POLICY "anon_all_desafios" ON desafios FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_all_desafio_prog" ON desafio_progresso;
CREATE POLICY "anon_all_desafio_prog" ON desafio_progresso FOR ALL USING (true) WITH CHECK (true);
