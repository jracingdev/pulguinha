-- Proteção das senhas — PASSO 2 de 2
--
-- SÓ RODE DEPOIS de:
--   1) migration_protege_senhas_1_preparar.sql executado;
--   2) versão nova do app publicada na web E instalada nos celulares
--      (versões antigas pedem a coluna `senha` e param de carregar os alunos).
--
-- Efeito: a chave pública do app deixa de ler a coluna `senha` de `alunos` e
-- `admins`, e o realtime deixa de transmitir as linhas de `alunos`.
-- Cadastro, troca de senha e login continuam funcionando (gravar a coluna
-- continua permitido; conferir passa pela função conferir_senha_legada).
--
-- ATENÇÃO: ao criar coluna nova em `alunos`/`admins` no futuro, rode de novo
-- este arquivo para que ela também fique legível pelo app.

DO $$
DECLARE
  t TEXT;
  cols TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['alunos', 'admins'] LOOP
    SELECT string_agg(quote_ident(column_name), ', ' ORDER BY ordinal_position)
      INTO cols
      FROM information_schema.columns
     WHERE table_schema = 'public' AND table_name = t AND column_name <> 'senha';

    EXECUTE format('REVOKE SELECT ON public.%I FROM anon, authenticated', t);
    EXECUTE format('GRANT SELECT (%s) ON public.%I TO anon, authenticated', cols, t);
  END LOOP;
END $$;

-- Realtime: `alunos` sai da publicação; o app escuta `alunos_sinal`.
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime DROP TABLE public.alunos;
EXCEPTION WHEN undefined_object THEN NULL;
END $$;

-- Conferência (deve dar erro de permissão quando feita com a chave anon):
--   select senha from alunos limit 1;
--
-- Rollback:
--   GRANT SELECT ON public.alunos TO anon, authenticated;
--   GRANT SELECT ON public.admins TO anon, authenticated;
--   ALTER PUBLICATION supabase_realtime ADD TABLE public.alunos;
