-- Migração mínima para banco Pulguinha já em produção.
-- Execute no SQL Editor do Supabase (idempotente — pode rodar mais de uma vez).

ALTER TABLE alunos ADD COLUMN IF NOT EXISTS aluno_desde DATE;

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
