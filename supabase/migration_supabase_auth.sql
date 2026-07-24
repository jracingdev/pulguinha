-- Migração 1/3 — Preparação do Supabase Auth (Pulguinha)
-- SEGURA PARA RODAR EM PRODUÇÃO: só adiciona colunas, funções e trigger.
-- Nada aqui altera RLS nem quebra o login atual.
--
-- Ordem recomendada:
--   1) supabase/migration_supabase_auth.sql            (este arquivo)
--   2) supabase/scripts/provisionar_auth_users.sql     (ou o script Node)
--   3) supabase/migration_supabase_auth_rls.sql        (só depois de validar o login)
--
-- Detalhes e riscos: docs/plano-migracao-supabase-auth.md

-- —— 1. Vínculo entre as tabelas de perfil e auth.users ——

ALTER TABLE alunos ADD COLUMN IF NOT EXISTS auth_user_id UUID;
ALTER TABLE admins ADD COLUMN IF NOT EXISTS auth_user_id UUID;

DO $$ BEGIN
  ALTER TABLE alunos
    ADD CONSTRAINT alunos_auth_user_id_fkey
    FOREIGN KEY (auth_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE admins
    ADD CONSTRAINT admins_auth_user_id_fkey
    FOREIGN KEY (auth_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS idx_alunos_auth_user_id
  ON alunos(auth_user_id) WHERE auth_user_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_admins_auth_user_id
  ON admins(auth_user_id) WHERE auth_user_id IS NOT NULL;

-- E-mail é a chave de ligação: garanta unicidade case-insensitive.
CREATE UNIQUE INDEX IF NOT EXISTS idx_alunos_email_lower ON alunos(lower(email));
CREATE UNIQUE INDEX IF NOT EXISTS idx_admins_email_lower ON admins(lower(email));

-- —— 2. Funções de apoio para as políticas RLS ——

-- E-mail do JWT da requisição (vazio quando não há sessão).
CREATE OR REPLACE FUNCTION public.email_sessao()
RETURNS TEXT
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT lower(coalesce(auth.jwt() ->> 'email', ''));
$$;

-- Verdadeiro quando o usuário autenticado é administrador.
CREATE OR REPLACE FUNCTION public.eh_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT auth.uid() IS NOT NULL
     AND EXISTS (
       SELECT 1 FROM admins a
       WHERE a.auth_user_id = auth.uid()
          OR (public.email_sessao() <> '' AND lower(a.email) = public.email_sessao())
     );
$$;

-- Id do aluno correspondente à sessão atual (NULL para admin/anônimo).
CREATE OR REPLACE FUNCTION public.aluno_id_sessao()
RETURNS BIGINT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT a.id FROM alunos a
  WHERE auth.uid() IS NOT NULL
    AND (a.auth_user_id = auth.uid()
         OR (public.email_sessao() <> '' AND lower(a.email) = public.email_sessao()))
  ORDER BY a.auth_user_id NULLS LAST
  LIMIT 1;
$$;

-- Checagem usada no cadastro público sem precisar ler a tabela `alunos`
-- (necessária quando o SELECT anônimo em `alunos` for revogado na Fase 5).
CREATE OR REPLACE FUNCTION public.email_ja_cadastrado(p_email TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM alunos WHERE lower(email) = lower(trim(p_email))
  );
$$;

GRANT EXECUTE ON FUNCTION public.email_ja_cadastrado(TEXT) TO anon, authenticated;

-- —— 3. Vínculo automático de novas contas ——

-- Toda conta criada no Auth (signUp no app ou convite pelo painel) é ligada ao
-- perfil de mesmo e-mail.
CREATE OR REPLACE FUNCTION public.vincular_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE alunos SET auth_user_id = NEW.id
   WHERE lower(email) = lower(NEW.email) AND auth_user_id IS NULL;
  UPDATE admins SET auth_user_id = NEW.id
   WHERE lower(email) = lower(NEW.email) AND auth_user_id IS NULL;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_vincular_auth_user ON auth.users;
CREATE TRIGGER trg_vincular_auth_user
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.vincular_auth_user();

-- —— 4. Backfill do vínculo para contas que já existem no Auth ——

UPDATE alunos a
   SET auth_user_id = u.id
  FROM auth.users u
 WHERE lower(u.email) = lower(a.email)
   AND a.auth_user_id IS NULL;

UPDATE admins a
   SET auth_user_id = u.id
  FROM auth.users u
 WHERE lower(u.email) = lower(a.email)
   AND a.auth_user_id IS NULL;

-- —— 5. Conferência ——

-- Quantos perfis ainda não têm conta no Supabase Auth:
--   SELECT count(*) FILTER (WHERE auth_user_id IS NULL) AS pendentes,
--          count(*) AS total
--     FROM alunos;
