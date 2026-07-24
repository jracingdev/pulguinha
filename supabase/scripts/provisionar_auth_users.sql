-- Migração 2/3 (opção A — SQL) — Provisiona auth.users a partir de alunos/admins
--
-- Cria uma conta no Supabase Auth para cada perfil que ainda não tem, reusando a
-- senha atual em texto. Assim ninguém precisa trocar de senha na migração.
--
-- Rode no SQL Editor do painel (papel `postgres`). É idempotente: perfis já
-- vinculados ou e-mails já existentes no Auth são ignorados.
--
-- Opção B (recomendada quando houver Node disponível):
--   supabase/scripts/provisionar_auth_users.mjs — usa a Admin API oficial e não
--   depende do formato interno das tabelas de `auth`.
--
-- ATENÇÃO
--   * Rode PRIMEIRO supabase/migration_supabase_auth.sql (colunas + trigger).
--   * Faça backup/snapshot do banco antes.
--   * Senhas com menos de 6 caracteres continuam funcionando no login, mas o
--     usuário só conseguirá definir novas senhas com 6+ caracteres.
--   * Nunca exponha a service_role key no app.

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
SET search_path = public, extensions;

-- —— 1. Contas de alunos ——

INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
)
SELECT
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  lower(trim(a.email)),
  crypt(a.senha, gen_salt('bf')),
  now(),
  now(),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  jsonb_build_object('nome', a.nome, 'perfil', 'aluno', 'origem', 'migracao_pulguinha'),
  '',
  '',
  '',
  ''
FROM alunos a
WHERE a.auth_user_id IS NULL
  AND lower(trim(a.email)) ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'
  AND coalesce(a.senha, '') <> ''
  AND NOT EXISTS (
    SELECT 1 FROM auth.users u WHERE lower(u.email) = lower(trim(a.email))
  );

-- —— 2. Contas de administradores ——

INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
)
SELECT
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  lower(trim(a.email)),
  crypt(a.senha, gen_salt('bf')),
  now(),
  now(),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  jsonb_build_object('nome', a.nome, 'perfil', 'admin', 'origem', 'migracao_pulguinha'),
  '',
  '',
  '',
  ''
FROM admins a
WHERE a.auth_user_id IS NULL
  AND lower(trim(a.email)) ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'
  AND coalesce(a.senha, '') <> ''
  AND NOT EXISTS (
    SELECT 1 FROM auth.users u WHERE lower(u.email) = lower(trim(a.email))
  );

-- —— 3. Identidades do provider "email" ——
-- Algumas versões do GoTrue exigem a linha em auth.identities. O bloco falha
-- silenciosamente (com aviso) se o layout da tabela for diferente — nesse caso
-- use o script Node.

DO $$
BEGIN
  INSERT INTO auth.identities (
    id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
  )
  SELECT
    gen_random_uuid(),
    u.id,
    jsonb_build_object(
      'sub', u.id::text,
      'email', u.email,
      'email_verified', true,
      'phone_verified', false
    ),
    'email',
    u.id::text,
    now(),
    now(),
    now()
  FROM auth.users u
  WHERE u.raw_user_meta_data ->> 'origem' = 'migracao_pulguinha'
    AND NOT EXISTS (
      SELECT 1 FROM auth.identities i WHERE i.user_id = u.id AND i.provider = 'email'
    );
EXCEPTION
  WHEN others THEN
    RAISE NOTICE 'auth.identities não preenchida (%). Use provisionar_auth_users.mjs.', SQLERRM;
END $$;

-- —— 4. Vínculo perfil <-> conta (o trigger cobre inserts novos) ——

UPDATE alunos a
   SET auth_user_id = u.id
  FROM auth.users u
 WHERE lower(u.email) = lower(trim(a.email))
   AND a.auth_user_id IS NULL;

UPDATE admins a
   SET auth_user_id = u.id
  FROM auth.users u
 WHERE lower(u.email) = lower(trim(a.email))
   AND a.auth_user_id IS NULL;

-- —— 5. Conferência ——

SELECT
  (SELECT count(*) FROM alunos WHERE auth_user_id IS NULL) AS alunos_sem_conta,
  (SELECT count(*) FROM admins WHERE auth_user_id IS NULL) AS admins_sem_conta,
  (SELECT count(*) FROM auth.users) AS contas_auth;
