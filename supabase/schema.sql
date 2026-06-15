-- Estrutura do Pulguinha — execute no SQL Editor do Supabase (idempotente).
-- Dados demo opcionais: supabase/seed.sql
-- Migração mínima (banco já em produção): supabase/migration_minimal.sql

-- Admin
CREATE TABLE IF NOT EXISTS admins (
  id BIGSERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  senha TEXT NOT NULL,
  nome TEXT NOT NULL
);

-- Alunos (campos estendidos: anamnese, foto, presença, aniversário)
CREATE TABLE IF NOT EXISTS alunos (
  id BIGSERIAL PRIMARY KEY,
  nome TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  senha TEXT NOT NULL,
  telefone TEXT NOT NULL DEFAULT '',
  plano TEXT NOT NULL DEFAULT 'Mensal',
  vencimento DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'Ativo',
  avatar TEXT NOT NULL DEFAULT '',
  data_nascimento DATE,
  anamnese JSONB NOT NULL DEFAULT '{}'::jsonb,
  foto TEXT,
  streak_presenca INT NOT NULL DEFAULT 0,
  pulguinha_points INT NOT NULL DEFAULT 0,
  data_cadastro DATE DEFAULT CURRENT_DATE,
  aluno_desde DATE
);

-- Horários de aula
CREATE TABLE IF NOT EXISTS horarios (
  id BIGSERIAL PRIMARY KEY,
  hora TEXT NOT NULL,
  dias TEXT NOT NULL,
  capacidade INT NOT NULL DEFAULT 12
);

-- Agendamentos
CREATE TABLE IF NOT EXISTS agendamentos (
  id BIGSERIAL PRIMARY KEY,
  aluno_id BIGINT NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
  nome_aluno TEXT NOT NULL,
  horario_id BIGINT NOT NULL REFERENCES horarios(id) ON DELETE CASCADE,
  data DATE NOT NULL,
  horario TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'Confirmado'
);

-- Presenças (check-in QR)
CREATE TABLE IF NOT EXISTS presencas (
  id BIGSERIAL PRIMARY KEY,
  aluno_id BIGINT NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
  horario_id BIGINT NOT NULL REFERENCES horarios(id) ON DELETE CASCADE,
  data DATE NOT NULL,
  horario TEXT NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  tipo TEXT NOT NULL DEFAULT 'scan_professor',
  nome_aluno TEXT,
  UNIQUE (aluno_id, horario_id, data)
);

-- Produtos / planos da loja
CREATE TABLE IF NOT EXISTS produtos (
  id BIGSERIAL PRIMARY KEY,
  nome TEXT NOT NULL,
  descricao TEXT NOT NULL DEFAULT '',
  preco NUMERIC(10, 2) NOT NULL,
  tipo TEXT NOT NULL,
  emoji TEXT NOT NULL DEFAULT '📦'
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_agendamentos_data ON agendamentos(data);
CREATE INDEX IF NOT EXISTS idx_agendamentos_aluno ON agendamentos(aluno_id);
CREATE INDEX IF NOT EXISTS idx_alunos_email ON alunos(email);
CREATE INDEX IF NOT EXISTS idx_presencas_data ON presencas(data);
CREATE INDEX IF NOT EXISTS idx_presencas_aluno ON presencas(aluno_id);
CREATE INDEX IF NOT EXISTS idx_presencas_horario ON presencas(horario_id);

-- RLS permissivo (app usa auth customizada; reforce em produção)
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE alunos ENABLE ROW LEVEL SECURITY;
ALTER TABLE horarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE agendamentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE presencas ENABLE ROW LEVEL SECURITY;

-- Políticas idempotentes (pode reexecutar o script em banco já configurado)
DROP POLICY IF EXISTS "anon_all_admins" ON admins;
CREATE POLICY "anon_all_admins" ON admins FOR ALL USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_all_alunos" ON alunos;
CREATE POLICY "anon_all_alunos" ON alunos FOR ALL USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_all_horarios" ON horarios;
CREATE POLICY "anon_all_horarios" ON horarios FOR ALL USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_all_agendamentos" ON agendamentos;
CREATE POLICY "anon_all_agendamentos" ON agendamentos FOR ALL USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_all_produtos" ON produtos;
CREATE POLICY "anon_all_produtos" ON produtos FOR ALL USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "anon_all_presencas" ON presencas;
CREATE POLICY "anon_all_presencas" ON presencas FOR ALL USING (true) WITH CHECK (true);

-- Migração para bancos existentes (idempotente)
ALTER TABLE alunos ADD COLUMN IF NOT EXISTS data_nascimento DATE;
ALTER TABLE alunos ADD COLUMN IF NOT EXISTS anamnese JSONB NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE alunos ADD COLUMN IF NOT EXISTS foto TEXT;
ALTER TABLE alunos ADD COLUMN IF NOT EXISTS streak_presenca INT NOT NULL DEFAULT 0;
ALTER TABLE alunos ADD COLUMN IF NOT EXISTS pulguinha_points INT NOT NULL DEFAULT 0;
ALTER TABLE alunos ADD COLUMN IF NOT EXISTS data_cadastro DATE DEFAULT CURRENT_DATE;
ALTER TABLE alunos ADD COLUMN IF NOT EXISTS aluno_desde DATE;
ALTER TABLE alunos ADD COLUMN IF NOT EXISTS horario_id BIGINT REFERENCES horarios(id) ON DELETE SET NULL;
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS foto TEXT;
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS grades JSONB NOT NULL DEFAULT '[]'::jsonb;

-- Posts da turma (rede social interna)
CREATE TABLE IF NOT EXISTS posts_turma (
  id BIGSERIAL PRIMARY KEY,
  aluno_id BIGINT NOT NULL REFERENCES alunos(id) ON DELETE CASCADE,
  nome_aluno TEXT NOT NULL,
  horario_id BIGINT NOT NULL REFERENCES horarios(id) ON DELETE CASCADE,
  texto TEXT NOT NULL,
  data_hora TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reacoes JSONB NOT NULL DEFAULT '[]'::jsonb,
  comentarios JSONB NOT NULL DEFAULT '[]'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_posts_turma_horario ON posts_turma(horario_id);
CREATE INDEX IF NOT EXISTS idx_alunos_horario ON alunos(horario_id);

ALTER TABLE posts_turma ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_all_posts_turma" ON posts_turma;
CREATE POLICY "anon_all_posts_turma" ON posts_turma FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE posts_turma ADD COLUMN IF NOT EXISTS tipo TEXT NOT NULL DEFAULT 'texto';
ALTER TABLE posts_turma ADD COLUMN IF NOT EXISTS figurinha TEXT;
ALTER TABLE posts_turma ADD COLUMN IF NOT EXISTS link_url TEXT;
ALTER TABLE posts_turma ADD COLUMN IF NOT EXISTS enquete_opcoes JSONB NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE posts_turma ADD COLUMN IF NOT EXISTS enquete_votos JSONB NOT NULL DEFAULT '{}'::jsonb;

-- Realtime: atualizar agenda quando alguém agenda/cancela (habilitar no Supabase)
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE agendamentos;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE alunos;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;
