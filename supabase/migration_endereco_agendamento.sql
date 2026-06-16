-- Endereço no cadastro de alunos + agendamento público sem aluno logado
-- Execute no SQL Editor do Supabase (idempotente).

ALTER TABLE alunos ADD COLUMN IF NOT EXISTS cep TEXT NOT NULL DEFAULT '';
ALTER TABLE alunos ADD COLUMN IF NOT EXISTS logradouro TEXT NOT NULL DEFAULT '';
ALTER TABLE alunos ADD COLUMN IF NOT EXISTS numero TEXT NOT NULL DEFAULT '';
ALTER TABLE alunos ADD COLUMN IF NOT EXISTS complemento TEXT NOT NULL DEFAULT '';
ALTER TABLE alunos ADD COLUMN IF NOT EXISTS bairro TEXT NOT NULL DEFAULT '';
ALTER TABLE alunos ADD COLUMN IF NOT EXISTS cidade TEXT NOT NULL DEFAULT '';
ALTER TABLE alunos ADD COLUMN IF NOT EXISTS uf TEXT NOT NULL DEFAULT '';

-- Visitantes podem agendar sem conta (aluno_id opcional)
ALTER TABLE agendamentos ALTER COLUMN aluno_id DROP NOT NULL;
