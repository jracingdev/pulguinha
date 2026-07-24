-- Migração 3/3 — RLS com auth.uid() (Pulguinha)
--
-- Este arquivo tem DUAS partes com pré-requisitos diferentes. Leia antes de rodar.
-- Contexto completo: docs/plano-migracao-supabase-auth.md
--
-- PARTE A — Proteger a tabela `admins` (aplicável já)
--   Pré-requisitos:
--     1) migration_supabase_auth.sql executado;
--     2) todos os registros de `admins` já provisionados no Auth
--        (SELECT count(*) FROM admins WHERE auth_user_id IS NULL  ->  0);
--     3) login de admin testado com sucesso pelo Supabase Auth no app.
--   Efeito: a chave anon deixa de conseguir ler e-mails/senhas de administradores.
--
-- PARTE B — Restringir `alunos` e as tabelas de conteúdo (NÃO RODE AINDA)
--   Depende de o app passar a carregar os dados DEPOIS do login (hoje o
--   AppState sincroniza tudo na inicialização, sem sessão) e de
--   `--dart-define=PULG_LOGIN_LEGADO=false`. Está no fim do arquivo, comentada,
--   junto com o rollback.

-- =====================================================================
-- PARTE A — tabela admins
-- =====================================================================

ALTER TABLE admins ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_all_admins" ON admins;

-- Administrador lê e atualiza apenas o próprio registro.
DROP POLICY IF EXISTS "admin_le_proprio_registro" ON admins;
CREATE POLICY "admin_le_proprio_registro" ON admins
  FOR SELECT TO authenticated
  USING (
    auth_user_id = auth.uid()
    OR (public.email_sessao() <> '' AND lower(email) = public.email_sessao())
  );

DROP POLICY IF EXISTS "admin_atualiza_proprio_registro" ON admins;
CREATE POLICY "admin_atualiza_proprio_registro" ON admins
  FOR UPDATE TO authenticated
  USING (
    auth_user_id = auth.uid()
    OR (public.email_sessao() <> '' AND lower(email) = public.email_sessao())
  )
  WITH CHECK (
    auth_user_id = auth.uid()
    OR (public.email_sessao() <> '' AND lower(email) = public.email_sessao())
  );

-- Criação/remoção de admins fica restrita ao painel (service_role ignora RLS).

-- Rollback da PARTE A:
--   DROP POLICY IF EXISTS "admin_le_proprio_registro" ON admins;
--   DROP POLICY IF EXISTS "admin_atualiza_proprio_registro" ON admins;
--   CREATE POLICY "anon_all_admins" ON admins FOR ALL USING (true) WITH CHECK (true);

-- =====================================================================
-- PARTE B — alunos e tabelas de conteúdo (manter COMENTADA até a Fase 5)
-- =====================================================================
--
-- ALTER TABLE alunos ENABLE ROW LEVEL SECURITY;
-- DROP POLICY IF EXISTS "anon_all_alunos" ON alunos;
--
-- -- Cadastro público: visitante só cria conta com status Pendente.
-- CREATE POLICY "anon_cadastra_aluno_pendente" ON alunos
--   FOR INSERT TO anon
--   WITH CHECK (status = 'Pendente');
--
-- -- Aluno logado vê a turma (nome/avatar aparecem no mural e na agenda).
-- -- Passo pendente da Fase 5: mover senha/CPF/endereço para fora desta tabela
-- -- ou expor os colegas por uma view enxuta antes de liberar este SELECT.
-- CREATE POLICY "autenticado_le_alunos" ON alunos
--   FOR SELECT TO authenticated
--   USING (true);
--
-- CREATE POLICY "aluno_atualiza_proprio_registro" ON alunos
--   FOR UPDATE TO authenticated
--   USING (public.eh_admin() OR id = public.aluno_id_sessao())
--   WITH CHECK (public.eh_admin() OR id = public.aluno_id_sessao());
--
-- CREATE POLICY "admin_gerencia_alunos" ON alunos
--   FOR ALL TO authenticated
--   USING (public.eh_admin())
--   WITH CHECK (public.eh_admin());
--
-- -- Conteúdo que exige login (mural, avisos, agenda, presença...).
-- DO $$
-- DECLARE t TEXT;
-- BEGIN
--   FOREACH t IN ARRAY ARRAY['agendamentos','presencas','posts_turma','avisos',
--                            'eventos','dicas_treino','desafios','desafio_progresso',
--                            'comunicacao_leituras','indicacoes']
--   LOOP
--     EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
--     EXECUTE format('DROP POLICY IF EXISTS %I ON %I', 'anon_all_' || t, t);
--     EXECUTE format(
--       'CREATE POLICY %I ON %I FOR ALL TO authenticated USING (true) WITH CHECK (true)',
--       'autenticado_all_' || t, t);
--   END LOOP;
-- END $$;
--
-- -- Loja/planos continuam públicos (tela pública sem login).
-- -- produtos e horarios permanecem com as políticas permissivas atuais.
--
-- Rollback da PARTE B: recriar as políticas `anon_all_<tabela>` de
-- supabase/schema.sql (FOR ALL USING (true) WITH CHECK (true)).
